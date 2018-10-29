
const TradingIntervalLib = artifacts.require("./libraries/TradingIntervalLib.sol");
const SortedBidAskListLib = artifacts.require("./libraries/SortedBidAskListLib.sol");
const ClearingLib = artifacts.require("./libraries/ClearingLib.sol");
const Marketplace = artifacts.require("./Marketplace.sol");

module.exports = function(deployer) {
  deployer.deploy(TradingIntervalLib);
  deployer.deploy(SortedBidAskListLib);

  deployer.link(SortedBidAskListLib, ClearingLib);
  deployer.link(TradingIntervalLib, Marketplace);

  deployer.deploy(ClearingLib);

  deployer.link(ClearingLib, Marketplace);
  deployer.link(SortedBidAskListLib, Marketplace);

  deployer.deploy(Marketplace, 0, 360, 60, 60, true, 0);
};
