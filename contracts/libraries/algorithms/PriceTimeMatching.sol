pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "../TradingIntervalStateObjectLib.sol";
import "../SortedBidAskListLib.sol";

library PriceTimeMatching {
    using SortedBidAskListLib for SortedBidAskListLib.SortedBidAskList;

    //Events can be imported yet, so they have to be copied
    event TradeEvent(
        uint intervalId,
        address from,
        address to,
        uint amount,
        uint price
    );
    function clear(TradingIntervalStateObjectLib.TradingIntervalState storage self) internal{
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

            self.matchedTrades.push(TradingIntervalStateObjectLib.Trade(bid.from, ask.from, bid.price, tradedAmount));
            emit TradeEvent(self.intervalId, bid.from, ask.from, tradedAmount, bid.price);

            if (bid.amount == 0) {
                self.openBids.removeFirstItem();
            }
            if (ask.amount == 0) {
                self.openAsks.removeFirstItem();
            }
        }
    }
} 