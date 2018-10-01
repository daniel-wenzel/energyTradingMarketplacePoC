pragma solidity ^0.4.23;

library TradingIntervalLib {

    enum IntervalStates { PRIOR_BIDDING, BIDDING, CLEARING, TRADING, POST_TRADING }

    struct TradingIntervalStorage{
        uint tradingIntervalStartingOffset;
        uint tradingIntervalLength;
        uint clearingPeriodLength;
        uint biddingPeriodLength;
    }

    function init(TradingIntervalStorage storage self, uint startingTime, uint tradingIntervalLength, uint clearingPeriodLength, uint biddingPeriodLength) public {
        self.tradingIntervalStartingOffset = startingTime / tradingIntervalLength;
        self.tradingIntervalLength = tradingIntervalLength;
        self.clearingPeriodLength = clearingPeriodLength;
        self.biddingPeriodLength = biddingPeriodLength;
    }

    function getIntervalId(TradingIntervalStorage storage self, uint timestamp) constant public returns (uint tradingIntervalId){
        return timestamp / self.tradingIntervalLength - self.tradingIntervalStartingOffset;
    }

    function getStartOfInterval(TradingIntervalStorage storage self, uint intervalId) constant public returns (uint) {
        return (intervalId + self.tradingIntervalStartingOffset) * self.tradingIntervalLength;
    }

    function getEndOfInterval(TradingIntervalStorage storage self, uint intervalId) constant public returns (uint) {
        return getStartOfInterval(self, intervalId + 1);
    }

    function getIntervalState(TradingIntervalStorage storage self, uint intervalId, uint timestamp) constant public returns (IntervalStates currentState) {
        uint intervalStart = getStartOfInterval(self, intervalId);
        return IntervalStates.BIDDING;
        /*if (timestamp < intervalStart) {
            if (timestamp < intervalStart - self.clearingPeriodLength) {
                if (timestamp < intervalStart - self.clearingPeriodLength - self.biddingPeriodLength) {
                    return IntervalStates.PRIOR_BIDDING;
                }
                else {
                    return IntervalStates.BIDDING;
                }
            }
            else {
                return IntervalStates.CLEARING;
            }
        }
        else {
            if (timestamp < intervalStart + self.tradingIntervalLength) {
                return IntervalStates.TRADING;
            }
            else {
                return IntervalStates.POST_TRADING;
            }
        }*/
    }
}