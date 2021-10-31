var TestERC20Token = artifacts.require("./TestERC20Token.sol");
var ArtifactToken = artifacts.require("./ArtifactToken.sol");
var BidProcess = artifacts.require("./BidProcess.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(TestERC20Token, {from: accounts[0]});
  deployer.deploy(ArtifactToken, {from: accounts[1]});
  deployer.deploy(BidProcess);
};