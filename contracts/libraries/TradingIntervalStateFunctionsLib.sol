pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "./SortedBidAskListLib.sol";
import "./TradingIntervalStateObjectLib.sol";
import "./algorithms/Mengelkamp.sol";
import "./algorithms/PriceTimeMatching.sol";

library TradingIntervalStateFunctionsLib {
    using SortedBidAskListLib for SortedBidAskListLib.SortedBidAskList;

    event TradeEvent(
        uint intervalId,
        address from,
        address to,
        uint amount,
        uint price
    );


    function init(TradingIntervalStateObjectLib.TradingIntervalState storage self, TradingIntervalStateObjectLib.ClearingAlgorithm algorithm, uint intervalId) public{
        self.openBids.sortDir = 1;
        self.openAsks.sortDir = -1;
        self.openBids.firstItemId = -1;
        self.openAsks.firstItemId = -1;

        self.initialized = true;

        self.clearingAlgorithm = algorithm;
        self.intervalId = intervalId;
    }

    function addBid(TradingIntervalStateObjectLib.TradingIntervalState storage self, address from, uint price, uint amount) public {

        self.openBids.add(from, price, amount);

        onBidAsk(self);
    }

    function addAsk(TradingIntervalStateObjectLib.TradingIntervalState storage self, address from, uint price, uint amount) public {

        self.openAsks.add(from, price, amount);
        
        onBidAsk(self);
    }

    function clear(TradingIntervalStateObjectLib.TradingIntervalState storage self) internal {
        require(!self.isCleared);
        self.isCleared = true; 

       
        if (self.clearingAlgorithm == TradingIntervalStateObjectLib.ClearingAlgorithm.MENGELKAMP) {
            Mengelkamp.clear(self);
        }
    }

    function onBidAsk(TradingIntervalStateObjectLib.TradingIntervalState storage self) internal {
        if (self.clearingAlgorithm == TradingIntervalStateObjectLib.ClearingAlgorithm.PRICE_TIME_BASED) {
            PriceTimeMatching.clear(self);
        }
    } 
} 