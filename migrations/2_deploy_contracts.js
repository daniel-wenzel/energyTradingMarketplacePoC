
const TradingIntervalLib = artifacts.require("./libraries/TradingIntervalLib.sol");
const ClearingLib = artifacts.require("./libraries/ClearingLib.sol");
const Marketplace = artifacts.require("./Marketplace.sol");

module.exports = function(deployer) {
  deployer.deploy(TradingIntervalLib);
  deployer.deploy(ClearingLib);
  deployer.link(TradingIntervalLib, Marketplace);
  deployer.link(ClearingLib, Marketplace);
  deployer.deploy(Marketplace, 0, 360, 60, 60, true);
};
