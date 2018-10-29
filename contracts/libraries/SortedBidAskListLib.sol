pragma solidity ^0.4.23;

library SortedBidAskListLib {

    struct BidAsk { 
        address from;
        uint price;
        uint amount;   
        int nextId;     
    }

    struct SortedBidAskList {
        BidAsk[] items;
        int firstItemId;
        int8 sortDir;
    }

    function add(SortedBidAskList storage list, address from, uint price, uint amount) public {
        uint newItemId = list.items.length;
        list.items.push(BidAsk(from, price, amount, -1));
        // if we work on the passed memory object we can not edit it
        BidAsk storage itemToAdd = list.items[newItemId];

        // check if list is empty
        if (list.firstItemId == -1) {
            list.firstItemId = int(newItemId);
            return;
        }

        uint currentId = uint(list.firstItemId);
        BidAsk storage currentItem = list.items[currentId];

        // check if the new item should be the new first item
        if (int(currentItem.price) * list.sortDir > int(itemToAdd.price) * list.sortDir ) {
            list.firstItemId = int(newItemId);
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

    function removeFirstItem(SortedBidAskList storage list) public {
        assert(list.firstItemId != -1);

        int newFirstItemId = list.items[uint(list.firstItemId)].nextId;
        delete list.items[uint(list.firstItemId)];
        list.firstItemId = newFirstItemId;
    }
} 