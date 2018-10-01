pragma solidity ^0.4.23;

contract Marketplace {
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

    constructor(uint startTime, uint intervalLength, uint cutoffLengthInIntervals) public {
        
    }
    function submitBid(uint intervalId, uint amount, uint price) public{
        // TODO: check for cutoff time
        
        bids[intervalId].push(BidAsk(msg.sender, price, amount));
    }
    function submitAsk(uint intervalId, uint amount, uint price) public{
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
}