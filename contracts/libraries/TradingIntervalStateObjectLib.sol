pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "./SortedBidAskListLib.sol";
library TradingIntervalStateObjectLib {

    enum ClearingAlgorithm { NONE, PRICE_TIME_BASED, MENGELKAMP }

    struct Trade {
        address producer;
        address consumer;
        uint price;
        uint amount;
    }

    struct TradingIntervalState {
        SortedBidAskListLib.SortedBidAskList openBids;
        SortedBidAskListLib.SortedBidAskList openAsks;
        Trade[] matchedTrades;

        bool initialized;
        bool isCleared;
        uint intervalId;

        ClearingAlgorithm clearingAlgorithm;
    }
} 