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

    mapping(uint => BidAsk[]) public bids;
    mapping(uint => BidAsk[]) public asks;

    mapping(uint => Trade[]) public trades;

    modifier inBiddingPeriod(uint tradingIntervalId) {
        require(tradingInterval.getIntervalState(tradingIntervalId, currentTime()) == TradingIntervalLib.IntervalStates.BIDDING);
        _;
    }

    //TODO fire trade event

    constructor(uint startTime, uint tradingIntervalLength, uint clearingDuration, uint biddingDuration, bool _dev) public {
        tradingInterval.init(startTime, tradingIntervalLength, clearingDuration, biddingDuration);
        dev = _dev;
    }
    function submitBid(uint intervalId, uint amount, uint price) inBiddingPeriod(intervalId) public{
        // TODO: check for cutoff time
        
        bids[intervalId].push(BidAsk(msg.sender, price, amount));
    }
    function submitAsk(uint intervalId, uint amount, uint price) inBiddingPeriod(intervalId) public{
        // TODO: check for cutoff time
        
        asks[intervalId].push(BidAsk(msg.sender, price, amount));
    }
    function clearInterval(uint intervalId) public{
        // TODO: check if interval was not cleared yet and is clearable

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
                    if (bid.amount == 0) {
                        // all offered energy was sold
                        break;
                    }
                }
            }

        }
    }
/*
    function settleTrade(intervalId , from, to) {
       // TODO: add later
    }*/

    function setCurrentTime(uint timestamp) {
        _currentTime = timestamp;
    }
    // Dev function for mocking time in tests 
    function currentTime() public returns (uint){
        if (dev) {
            return _currentTime;
        }
        else now;
    }
}