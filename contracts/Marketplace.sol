pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "./libraries/TradingIntervalTimeMappingLib.sol";
import "./libraries/TradingIntervalStateObjectLib.sol";
import "./libraries/TradingIntervalStateFunctionsLib.sol";
import "./libraries/SortedBidAskListLib.sol";

contract Marketplace{
    using TradingIntervalTimeMappingLib for TradingIntervalTimeMappingLib.TradingIntervalTimeMappingStorage;
    using TradingIntervalStateFunctionsLib for TradingIntervalStateObjectLib.TradingIntervalState;
    using SortedBidAskListLib for SortedBidAskListLib.SortedBidAskList;

    event TradeEvent(
        uint intervalId,
        address from,
        address to,
        uint amount,
        uint price
    );
    event DEBUG(
        string message,
        uint val
    );

    TradingIntervalTimeMappingLib.TradingIntervalTimeMappingStorage tradingIntervalTimeMapping;
    TradingIntervalStateObjectLib.ClearingAlgorithm algorithm;

    bool public dev;
    uint private _currentTime;
    
    mapping(uint => TradingIntervalStateObjectLib.TradingIntervalState) public intervalState;

    modifier inBiddingPeriod(uint tradingIntervalId) {
        require(tradingIntervalTimeMapping.getIntervalState(tradingIntervalId, currentTime()) == TradingIntervalTimeMappingLib.IntervalStates.BIDDING);
        _;
    }
    modifier inClearingPeriod(uint tradingIntervalId) {
        require(tradingIntervalTimeMapping.getIntervalState(tradingIntervalId, currentTime()) == TradingIntervalTimeMappingLib.IntervalStates.CLEARING);
        _;
    }

    constructor(uint startTime, uint tradingIntervalLength, uint clearingDuration, uint biddingDuration, bool _dev, TradingIntervalStateObjectLib.ClearingAlgorithm _clearingAlgorithm) public {
        tradingIntervalTimeMapping.init(startTime, tradingIntervalLength, clearingDuration, biddingDuration);
        dev = _dev;
        algorithm = _clearingAlgorithm;
    }
    function submitBid(uint intervalId, uint amount, uint price) inBiddingPeriod(intervalId) public {
        if (!intervalState[intervalId].initialized) {
            intervalState[intervalId].init(algorithm, intervalId);
        }
        intervalState[intervalId].addBid(msg.sender, price, amount);
    }
    function submitAsk(uint intervalId, uint amount, uint price) inBiddingPeriod(intervalId) public {
        if (!intervalState[intervalId].initialized) {
            intervalState[intervalId].init(algorithm, intervalId);
        }

        intervalState[intervalId].addAsk(msg.sender, price, amount);
    }

    // Solidity does not allow returning structs, therefore we return the individual items
    function debugGetBidAsk(uint intervalId, uint id, bool bids) public constant returns (address, uint, uint, int) {
        require(dev);
        SortedBidAskListLib.BidAsk[] memory list;
        if (bids) {
            list = intervalState[intervalId].openBids.getAsArray();
        }
        else {
            list = intervalState[intervalId].openAsks.getAsArray();
        }
        SortedBidAskListLib.BidAsk memory item = list[id];
        return (item.from, item.price, item.amount, item.nextId);
    }
    function clearInterval(uint intervalId) inClearingPeriod(intervalId) public {
        intervalState[intervalId].clear();
    }
    function getIntervalState(uint tradingIntervalId) public constant returns (TradingIntervalTimeMappingLib.IntervalStates interval) {
        return tradingIntervalTimeMapping.getIntervalState(tradingIntervalId, currentTime());
    }

    function getStartOfInterval(uint intervalId) public constant returns (uint startTime) {
        return tradingIntervalTimeMapping.getStartOfInterval(intervalId);
    }

    function getEndOfInterval(uint intervalId) public constant returns (uint endTime) {
        return tradingIntervalTimeMapping.getEndOfInterval(intervalId);
    }

    function getIntervalId(uint timestamp) public constant returns (uint intervalId) {
        return tradingIntervalTimeMapping.getIntervalId(timestamp);
    }
/*
    function settleTrade(intervalId , from, to) {
       // TODO: add later
    }*/

    function setCurrentTime(uint timestamp) public {
        require(dev);
        _currentTime = timestamp;
    }
    // Dev function for mocking time in tests 
    function currentTime() public constant returns (uint){
        if (dev) {
            return _currentTime;
        }
        else now;
    }
}