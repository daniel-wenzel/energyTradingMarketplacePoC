pragma solidity ^0.4.23;

library ClearingLib {

    struct BidAsk { 
        address from;
        uint price;
        uint amount;   
        int nextId;     
    }

    struct Trade {
        address producer;
        address consumer;
        uint price;
        uint amount;
    }

    struct SortedBidAskList {
        BidAsk[] items;
        uint firstItemId;
        int8 sortDir;
    }

    struct TradingIntervalState {
        SortedBidAskList openBids;
        SortedBidAskList openAsks;
        Trade[] matchedTrades;

        bool initialized;
        bool isCleared;
    }

    function init(TradingIntervalState storage self) public{
        self.openBids.sortDir = 1;
        self.openAsks.sortDir = -1;
        self.initialized = true;
    }

    function addBid(TradingIntervalState storage self, address from, uint price, uint amount) public {
        if (self.initialized == false) init(self);

        addToList(self.openBids, BidAsk(from, price, amount, -1));
    }

    function addAsk(TradingIntervalState storage self, address from, uint price, uint amount) public {
        if (self.initialized == false) init(self);

        addToList(self.openAsks, BidAsk(from, price, amount, -1));
    }

    function addToList(SortedBidAskList storage list, BidAsk _itemToAdd) private {
        uint newItemId = list.items.length;
        list.items.push(_itemToAdd);
        // if we work on the passed memory object we can not edit it
        BidAsk storage itemToAdd = list.items[newItemId];

        // check if list is empty
        if (newItemId == 0) {
            list.firstItemId = newItemId;
            return;
        }

        uint currentId = list.firstItemId;
        BidAsk storage currentItem = list.items[currentId];

        // check if the new item should be the new first item
        if (int(currentItem.price) * list.sortDir > int(itemToAdd.price) * list.sortDir ) {
            list.firstItemId = newItemId;
            itemToAdd.nextId = int(currentId);
            return;
        }

        // find the bid which should be in front of the new bid
        while (currentItem.nextId >= 0 && int(list.items[uint(currentItem.nextId)].price) * list.sortDir < int(itemToAdd.price) * list.sortDir) {
            currentId = uint(currentItem.nextId);
            currentItem = list.items[currentId];
        }

        // insert new item
        itemToAdd.nextId = currentItem.nextId;
        currentItem.nextId = int(newItemId);
    }
    function clear(TradingIntervalState storage self) internal {
        require(!self.isCleared);
        self.isCleared = true;

        // TODO implement clearing logic
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