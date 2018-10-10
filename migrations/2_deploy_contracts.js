
const TradingIntervalLib = artifacts.require("./libraries/TradingIntervalLib.sol");
const Marketplace = artifacts.require("./Marketplace.sol");

module.exports = function(deployer) {
  deployer.deploy(TradingIntervalLib);
  deployer.link(TradingIntervalLib, Marketplace);
  deployer.deploy(Marketplace, 0, 360, 60, 60, true);
};
