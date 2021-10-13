// migrations are changing the state of blockchain

const Token = artifacts.require("Token");

module.exports = function (deployer) {
  deployer.deploy(Token);
};
