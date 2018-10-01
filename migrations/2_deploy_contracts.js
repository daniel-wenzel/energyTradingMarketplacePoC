var ConvertLib = artifacts.require("./ConvertLib.sol");
var MetaCoin = artifacts.require("./MetaCoin.sol");
const TradingIntervalLib = artifacts.require("./libraries/TradingIntervalLib.sol");
const Marketplace = artifacts.require("./Marketplace.sol");

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);

  deployer.deploy(TradingIntervalLib);
  deployer.link(TradingIntervalLib, Marketplace);
  deployer.deploy(Marketplace, 0, 360, 60, 60, true);

 // deployer.deploy(TradingInterval, 1000, 10, true);
  
};
