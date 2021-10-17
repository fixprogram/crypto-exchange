pragma solidity >=0.4.21 <0.9.0;
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

import './Token.sol';

contract Exchange {
    using SafeMath for uint;

    address public feeAccount; // the account which receives exchange fees
    uint256 public feePercent; // the fee percentage
    address constant ETHER = address(0); // store Ethers in tokens mapping with blank address
    mapping(address => mapping(address => uint256)) public tokens;
    mapping(uint256 => _Order) public orders; // Id of the order and the value is the data about this order
    uint256 public orderCount;
    mapping(uint256 => bool) public orderCancelled;
    mapping(uint256 => bool) public orderFilled;

    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint amount, uint balance);
    event Order(
        uint id,
        address user,
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive, 
        uint timestamp
    );

    event Cancel(
        uint id,
        address user,
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive, 
        uint timestamp
    );

    event Trade(
        uint id,
        address user, 
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        address userFill,
        uint timestamp
    );

    struct _Order { // We use underscore here to not conflict with the event declaration
        uint id; // Order id
        address user; // Who create the order
        address tokenGet; // Address of the token
        uint amountGet; // Amount of tokens he wanna get
        address tokenGive; // Address of the token he is gonna trade
        uint amountGive; // Amount of these tokens
        uint timestamp; // The time of the order has created
    }

    constructor (address _feeAccount, uint256 _feePercent) public {
        feeAccount = _feeAccount;
        feePercent = _feePercent;
    }

    // Fallback: reverts if Ether is sent to this smart contract by mistake
    function() external {
        revert();
    }

    function depositEther() payable public {
        tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].add(msg.value);
        emit Deposit(ETHER, msg.sender, msg.value, tokens[ETHER][msg.sender]);
    }

    function withdrawEther(uint _amount) public {
        require(tokens[ETHER][msg.sender] >= _amount); // make sure we have enough ETH
        tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].sub(_amount);
        msg.sender.transfer(_amount);
        emit Withdraw(ETHER, msg.sender, _amount, tokens[ETHER][msg.sender]);
    }

    function depositToken(address _token, uint _amount) public {
        require(_token != ETHER); // Check if it's not an Ethereum address
        require(Token(_token).transferFrom(msg.sender, address(this), _amount));
        tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);
        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function withdrawToken(address _token, uint256 _amount) public {
        require(_token != ETHER); // require that it's not ETHER address
        require(tokens[_token][msg.sender] >= _amount); // make sure we have enough tokens
        tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
        require(Token(_token).transfer(msg.sender, _amount));
        emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function balanceOf(address _token, address _user) public view returns(uint256) {
        return tokens[_token][_user];
    }

    function makeOrder(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) public {
        orderCount = orderCount.add(1);
        orders[orderCount] = _Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now); // NOW sets current timestamp
        emit Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
    }

    function cancelOrder(uint256 _id) public {
        _Order storage _order = orders[_id]; // we get the order by the id and and assign it to the var called _order type of _Order
        require(address(_order.user) == msg.sender); // it's the same user
        require(_order.id == _id); // the order must exist
        orderCancelled[_id] = true;
        emit Cancel(orderCount, msg.sender, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive, now);
    }

    function fillOrder(uint256 _id) public {
        require(_id > 0 && _id <= orderCount);
        require(!orderFilled[_id]);
        require(!orderCancelled[_id]);
        _Order storage _order = orders[_id];
        _trade(_order.id, _order.user, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive);
        orderFilled[_order.id] = true;
    }

    function _trade(uint256 _orderId, address _user, address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) internal {
        // Fee paid by the user who fills the order a.k.a msg.sender
        // Fee deducted from _amountGet
        uint256 _feeAmount = _amountGive.mul(feePercent).div(100);
        
        // Execute trade
        tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender].sub(_amountGet.add(_feeAmount));
        tokens[_tokenGet][_user] = tokens[_tokenGet][_user].add(_amountGet);
        tokens[_tokenGet][feeAccount] = tokens[_tokenGet][feeAccount].add(_feeAmount);
        tokens[_tokenGive][_user] = tokens[_tokenGive][_user].sub(_amountGive);
        tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender].add(_amountGive);

        emit Trade(_orderId, _user, _tokenGet, _amountGet, _tokenGive, _amountGive, msg.sender, now);
    }
}