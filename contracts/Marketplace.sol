pragma solidity ^0.4.23;

import "./libraries/TradingIntervalLib.sol";

contract Marketplace{
    using TradingIntervalLib for TradingIntervalLib.TradingIntervalStorage;
    TradingIntervalLib.TradingIntervalStorage tradingInterval;

    bool public dev;
    uint private _currentTime;

    struct BidAsk { 
        address from;
        uint price;
        uint amount;        
    }

    struct Trade {
        address producer;
        address consumer;
        uint price;
        uint amount;
    }

    // this is potentially very ineffficient because we also store all trades on chain
    event TradeEvent(
        uint intervalId,
        address from,
        address to,
        uint amount,
        uint price
    );    

    mapping(uint => BidAsk[]) public bids;
    mapping(uint => BidAsk[]) public asks;

    // makes sure each interval can only be cleared once
    mapping(uint => bool) public isIntervalCleared;

    mapping(uint => Trade[]) public trades;

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
        bids[intervalId].push(BidAsk(msg.sender, price, amount));
    }
    function submitAsk(uint intervalId, uint amount, uint price) inBiddingPeriod(intervalId) public {         
        asks[intervalId].push(BidAsk(msg.sender, price, amount));
    }
    function clearInterval(uint intervalId) inClearingPeriod(intervalId) public {
        require(isIntervalCleared[intervalId] == false);

        isIntervalCleared[intervalId] = true;

        // Loop through bids in order they were added
        for (uint b=0; b<bids[intervalId].length; b++) {
            BidAsk memory bid = bids[intervalId][b];
            // Loop through asks in order they were added and look for unmatched ask with price > bid.price
            for (uint a=0; a<asks[intervalId].length; a++) {
                BidAsk memory ask = asks[intervalId][a];
                if (bid.price <= ask.price && ask.amount > 0) {
                    // They trade as much as they can
                    uint tradedAmount = bid.amount > ask.amount? ask.amount : bid.amount;
                    ask.amount -= tradedAmount;
                    bid.amount -= tradedAmount;

                    asks[intervalId][a] = ask;
                    trades[intervalId].push(Trade(bid.from, ask.from, ask.price, tradedAmount));
                    emit TradeEvent(intervalId, bid.from, ask.from, ask.price, tradedAmount);
                    if (bid.amount == 0) {
                        // all offered energy was sold
                        break;
                    }
                }
            }

        }
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