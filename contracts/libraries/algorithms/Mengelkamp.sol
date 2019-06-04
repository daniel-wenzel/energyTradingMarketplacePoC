pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "../TradingIntervalStateObjectLib.sol";
import "../SortedBidAskListLib.sol";

library Mengelkamp {
    using SortedBidAskListLib for SortedBidAskListLib.SortedBidAskList;

    event DEBUG(
        string message,
        uint val
    );
    //Events can be imported yet, so they have to be copied
    event TradeEvent(
        uint intervalId,
        address from,
        address to,
        uint amount,
        uint price
    );
        // based on https://github.com/BlockInfinity/dex_contract/blob/fixedSomeBugs/contracts/Etherex.sol but with more swag
    function clear(TradingIntervalStateObjectLib.TradingIntervalState storage self) internal {
        if (self.openBids.numEntries == 0 || self.openAsks.numEntries == 0) {
            // if this is true we have either no asks or no bids
            return;
        }

        // contains all bids, price-wise ascending
        // during interation this list will grow
        SortedBidAskListLib.BidAsk[] memory bids = self.openBids.getAsArray();
        // index of the bid with the lowest price which is larger than the matching price
        // bids in [0, cheapestBidWithHigherPriceId) are matched
        uint cheapestBidWithHigherPriceId = 0;
        // sum of amounts of all bids in [0, cheapestBidWithHigherPriceId)
        uint cumBidAmount = 0;

        // matching price will be raised until cumBidAmount > cumAskAmount
        uint matchingPrice = bids[0].price;

        // init cumBidAmount
        while (cheapestBidWithHigherPriceId < bids.length && bids[cheapestBidWithHigherPriceId].price <= matchingPrice) {
            //emit DEBUG("Willing to sell for initial price:", cheapestBidWithHigherPriceId);
            cumBidAmount += bids[cheapestBidWithHigherPriceId].amount;
            cheapestBidWithHigherPriceId++;
        }

        // contains all asks price-wise descending
        // during interation this list will shrink
        SortedBidAskListLib.BidAsk[] memory asks = self.openAsks.getAsArray();
        // index of the ask with the lowest price which is still not smaller than the matching price
        // asks in [0, highestAskWithLowerPriceId) are matched
        int highestAskWithLowerPriceId = 0;
        // sum of amounts of all asks in [0, highestAskWithLowerPriceId]
        uint cumAskAmount = 0;
        // init highestAskWithLowerPriceId and cumAskAmount
        while (uint(highestAskWithLowerPriceId) < asks.length && asks[uint(highestAskWithLowerPriceId)].price >= matchingPrice) {
            emit DEBUG("Willing to buy for initial price:", uint(highestAskWithLowerPriceId));
            cumAskAmount += asks[uint(highestAskWithLowerPriceId)].amount;
            highestAskWithLowerPriceId ++;
        }
        highestAskWithLowerPriceId--;

        while (cumAskAmount > cumBidAmount && highestAskWithLowerPriceId >= 0 && cheapestBidWithHigherPriceId < bids.length) {

            matchingPrice = bids[cheapestBidWithHigherPriceId].price;

            emit DEBUG("New Matching Price:", matchingPrice);
            // increase matchedBidWithHighestPriceId until price is bigger than matchingPrice
            while (cheapestBidWithHigherPriceId < bids.length && bids[cheapestBidWithHigherPriceId].price <= matchingPrice )
            {
                emit DEBUG("Willing to sell now:", cheapestBidWithHigherPriceId);
                cumBidAmount += bids[cheapestBidWithHigherPriceId].amount;
                cheapestBidWithHigherPriceId++;
            }

            // decrease matchedAskWithLowestPriceId until price is smaller than matchingPrice
            while (highestAskWithLowerPriceId > -1 && asks[uint(highestAskWithLowerPriceId)].price < matchingPrice)
            {
                emit DEBUG("Not willing to buy anymore:", uint(highestAskWithLowerPriceId));
                cumAskAmount -= asks[uint(highestAskWithLowerPriceId)].amount;
                if (highestAskWithLowerPriceId == 0) {
                    emit DEBUG("No one is willing to buy anymore", 0);
                }
                highestAskWithLowerPriceId--;
            }
            emit DEBUG("----------", 0);
        }

        // actually match orders at the matching price
        uint iBid = 0;
        uint iAsk = 0;
        while (highestAskWithLowerPriceId > -1 && iBid < cheapestBidWithHigherPriceId && iBid < bids.length && iAsk <= uint(highestAskWithLowerPriceId) && iAsk < asks.length) {

            uint amount = bids[iBid].amount > asks[iAsk].amount? asks[iAsk].amount: bids[iBid].amount;
            emit DEBUG("Matching Bid", iBid);
            emit DEBUG("Matching Ask", iAsk);
            emit DEBUG("Matchable Bid Amount", bids[iBid].amount);
            emit DEBUG("Matchable Ask Amount", asks[iAsk].amount);
            emit DEBUG("Matched Amount", amount);
            emit DEBUG("---------",0);
            bids[iBid].amount -= amount;
            asks[iAsk].amount -= amount;

            self.matchedTrades.push(TradingIntervalStateObjectLib.Trade(bids[iBid].from, asks[iAsk].from, matchingPrice, amount));
            emit TradeEvent(self.intervalId, bids[iBid].from, asks[iAsk].from, amount, matchingPrice);

            if (bids[iBid].amount == 0) {
                iBid ++;
            }
            if (asks[iAsk].amount == 0) {
                iAsk ++;
            }
        }
    }
}
