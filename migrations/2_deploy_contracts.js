
const TradingIntervalTimeMappingLib = artifacts.require("./libraries/TradingIntervalTimeMappingLib.sol");
const SortedBidAskListLib = artifacts.require("./libraries/SortedBidAskListLib.sol");
const TradingIntervalStateObjectLib = artifacts.require("./libraries/TradingIntervalStateObjectLib.sol");
const TradingIntervalStateFunctionsLib = artifacts.require("./libraries/TradingIntervalStateFunctionsLib.sol");
const Marketplace = artifacts.require("./Marketplace.sol");
const Mengelkamp = artifacts.require("./Mengelkamp.sol");
const PriceTimeMatching = artifacts.require("./PriceTimeMatching.sol");

module.exports = function(deployer) {
  deployer.deploy(TradingIntervalTimeMappingLib);
  deployer.deploy(SortedBidAskListLib);

  deployer.deploy(TradingIntervalStateObjectLib);
  deployer.link(SortedBidAskListLib, TradingIntervalStateObjectLib);
  
  deployer.link(SortedBidAskListLib, Mengelkamp);
  deployer.link(TradingIntervalStateObjectLib, Mengelkamp);

  deployer.deploy(Mengelkamp)

  deployer.link(SortedBidAskListLib, PriceTimeMatching);
  deployer.link(TradingIntervalStateObjectLib, PriceTimeMatching);

  deployer.deploy(PriceTimeMatching)

  deployer.link(PriceTimeMatching, TradingIntervalStateFunctionsLib)
  deployer.link(Mengelkamp, TradingIntervalStateFunctionsLib)
  deployer.link(SortedBidAskListLib, TradingIntervalStateFunctionsLib);
  deployer.link(TradingIntervalStateObjectLib, TradingIntervalStateFunctionsLib);


  deployer.link(TradingIntervalStateObjectLib, Marketplace);
  deployer.link(TradingIntervalTimeMappingLib, Marketplace);

  deployer.deploy(TradingIntervalStateFunctionsLib);

  deployer.link(TradingIntervalStateFunctionsLib, Marketplace);
  deployer.link(SortedBidAskListLib, Marketplace);

  deployer.deploy(Marketplace, 0, 360, 60, 60, true, 0);
};
