pragma solidity ^0.4.23;

import "./libraries/TradingIntervalLib.sol";
import "./libraries/ClearingLib.sol";

contract Marketplace{
    using TradingIntervalLib for TradingIntervalLib.TradingIntervalStorage;
    using ClearingLib for ClearingLib.TradingIntervalState;


    TradingIntervalLib.TradingIntervalStorage tradingInterval;

    bool public dev;
    uint private _currentTime;

    // this is potentially very ineffficient because we also store all trades on chain
    event TradeEvent(
        uint intervalId,
        address from,
        address to,
        uint amount,
        uint price
    );    
    mapping(uint => ClearingLib.TradingIntervalState) public intervalState;

   /* mapping(uint => ClearingLib.BidAsk[]) public bids;
    mapping(uint => ClearingLib.BidAsk[]) public asks;

    // makes sure each interval can only be cleared once
    mapping(uint => bool) public isIntervalCleared;

    mapping(uint => ClearingLib.Trade[]) public trades;*/

    modifier inBiddingPeriod(uint tradingIntervalId) {
        require(tradingInterval.getIntervalState(tradingIntervalId, currentTime()) == TradingIntervalLib.IntervalStates.BIDDING);
        _;
    }
    modifier inClearingPeriod(uint tradingIntervalId) {
        require(tradingInterval.getIntervalState(tradingIntervalId, currentTime()) == TradingIntervalLib.IntervalStates.CLEARING);
        _;
    }


    //TODO fire trade event

    constructor(uint startTime, uint tradingIntervalLength, uint clearingDuration, uint biddingDuration, bool _dev) public {
        tradingInterval.init(startTime, tradingIntervalLength, clearingDuration, biddingDuration);
        dev = _dev;
    }
    function submitBid(uint intervalId, uint amount, uint price) inBiddingPeriod(intervalId) public {
        //bids[intervalId].push(ClearingLib.BidAsk(msg.sender, price, amount));
        intervalState[intervalId].addBid(msg.sender, price, amount);
    }
    function submitAsk(uint intervalId, uint amount, uint price) inBiddingPeriod(intervalId) public {         
        intervalState[intervalId].addAsk(msg.sender, price, amount);
    }

    // Solidity does not allow returning structs, therefore we return the individual items
    function debugGetBidAsk(uint intervalId, uint id, bool bids) public constant returns (address, uint, uint, int) {
        ClearingLib.SortedBidAskList memory list;
        if (bids) {
            list = intervalState[intervalId].openBids;
        }
        else {
            list = intervalState[intervalId].openAsks;
        }
        int sortedId = int(list.firstItemId);
        while (id > 0) {
            sortedId = list.items[uint(sortedId)].nextId;
            id --;
        }

        ClearingLib.BidAsk memory item = list.items[uint(sortedId)];
        return (item.from, item.price, item.amount, item.nextId);
    }
    function clearInterval(uint intervalId) inClearingPeriod(intervalId) public {
        intervalState[intervalId].clear();
        //trades[intervalId].compute(bids[intervalId], asks[intervalId]);
    }
    function getIntervalState(uint tradingIntervalId) public constant returns (TradingIntervalLib.IntervalStates interval) {
        return tradingInterval.getIntervalState(tradingIntervalId, currentTime());
    }

    function getStartOfInterval(uint intervalId) public constant returns (uint startTime) {
        return tradingInterval.getStartOfInterval(intervalId);
    }

    function getEndOfInterval(uint intervalId) public constant returns (uint endTime) {
        return tradingInterval.getEndOfInterval(intervalId);
    }

    function getIntervalId(uint timestamp) public constant returns (uint intervalId) {
        return tradingInterval.getIntervalId(timestamp);
    }
/*
    function settleTrade(intervalId , from, to) {
       // TODO: add later
    }*/

    function setCurrentTime(uint timestamp) public {
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