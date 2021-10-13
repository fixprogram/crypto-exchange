pragma solidity >=0.4.21 <0.9.0;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract Token {
    using SafeMath for uint;

    // Varibables
    string public name = "Sand Token";
    string public symbol = 'Sand';
    uint256 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;  // Mapping is like a dictionary where we assosiate key-value pairs

    // Events 
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        totalSupply = 1000000 * (10 ** decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balanceOf[msg.sender] >= _value); // Throw an error if it's false and continue execution if true
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}
