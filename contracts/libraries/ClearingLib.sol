pragma solidity ^0.4.23;

import "./SortedBidAskListLib.sol";
library ClearingLib {
    using SortedBidAskListLib for SortedBidAskListLib.SortedBidAskList;

    enum ClearingAlgorithm { NONE, PRICE_TIME_BASED, MENGELKAMP }

    event TradeEvent(
        uint intervalId,
        address from,
        address to,
        uint amount,
        uint price
    );

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

    function init(TradingIntervalState storage self, ClearingAlgorithm algorithm, uint intervalId) public{
        self.openBids.sortDir = 1;
        self.openAsks.sortDir = -1;
        self.openBids.firstItemId = -1;
        self.openAsks.firstItemId = -1;

        self.initialized = true;

        self.clearingAlgorithm = algorithm;
        self.intervalId = intervalId;
    }

    function addBid(TradingIntervalState storage self, address from, uint price, uint amount) public {

        self.openBids.add(from, price, amount);

        onBidAsk(self);
    }

    function addAsk(TradingIntervalState storage self, address from, uint price, uint amount) public {

        self.openAsks.add(from, price, amount);
        
        onBidAsk(self);
    }

    function clear(TradingIntervalState storage self) internal {
        require(!self.isCleared);
        self.isCleared = true; 

       
        if (self.clearingAlgorithm == ClearingAlgorithm.MENGELKAMP) {
            // TODO implement clearing logic
        }
    }

    function priceTimeBasedClearing(TradingIntervalState storage self) internal{
            // if we have no more asks / bids to match stop
        while (self.openBids.firstItemId != -1 && self.openAsks.firstItemId != -1) {
            SortedBidAskListLib.BidAsk storage bid = self.openBids.items[uint(self.openBids.firstItemId)];
            SortedBidAskListLib.BidAsk storage ask = self.openAsks.items[uint(self.openAsks.firstItemId)];
            // if the price of the bid is higher than the price of the ask, stop
            if (bid.price > ask.price) {
                break;
            }

            uint tradedAmount = bid.amount > ask.amount? ask.amount : bid.amount;
            ask.amount -= tradedAmount;
            bid.amount -= tradedAmount;

            self.matchedTrades.push(Trade(bid.from, ask.from, bid.price, tradedAmount));
            emit TradeEvent(self.intervalId, bid.from, ask.from, tradedAmount, bid.price);

            if (bid.amount == 0) {
                self.openBids.removeFirstItem();
            }
            if (ask.amount == 0) {
                self.openAsks.removeFirstItem();
            }
        }
    }

    function onBidAsk(TradingIntervalState storage self) internal {
        if (self.clearingAlgorithm == ClearingAlgorithm.PRICE_TIME_BASED) {
            priceTimeBasedClearing(self);
        }
    } 

/*
    function compute(Trade[] storage trades, BidAsk[] storage bids, BidAsk[] storage asks) public {
        // price time matching
// Loop through bids in order they were added
        for (uint b=0; b<bids.length; b++) {
            ClearingLib.BidAsk memory bid = bids[b];
            // Loop through asks in order they were added and look for unmatched ask with price > bid.price
            for (uint a=0; a<asks.length; a++) {
                ClearingLib.BidAsk memory ask = asks[a];
                if (bid.price <= ask.price && ask.amount > 0) {
                    // They trade as much as they can
                    uint tradedAmount = bid.amount > ask.amount? ask.amount : bid.amount;
                    ask.amount -= tradedAmount;
                    bid.amount -= tradedAmount;

                    asks[a] = ask;
                    trades.push(Trade(bid.from, ask.from, ask.price, tradedAmount));
                    //emit TradeEvent(intervalId, bid.from, ask.from, ask.price, tradedAmount);
                    if (bid.amount == 0) {
                        // all offered energy was sold
                        break;
                    }
                }
            }
        }
    }*/
} 