var Marketplace = artifacts.require("./Marketplace.sol");
const should = require('should');

const {makeContractInPeriod, placeBidAsk} = require("./util")


contract('Marketplace', function (accounts) {

    it("Should be possible to place bids and asks", async function () {
        const intervalId = 0
        const contract = await makeContractInPeriod("BIDDING", intervalId)

        const bid = {
            intervalId: intervalId,
            sender: accounts[0],
            amount: 5,
            price: 100
        }

        await contract.submitBid.sendTransaction(bid.intervalId, bid.amount, bid.price)
        await contract.submitAsk.sendTransaction(bid.intervalId, bid.amount, bid.price)
        const answerBid = await contract.bids.call(bid.intervalId, 0)
        const answerAsk = await contract.asks.call(bid.intervalId, 0)

        bid.sender.should.equal(answerBid[0])
        bid.price.should.equal(+answerBid[1])
        bid.amount.should.equal(+answerBid[2])

        bid.sender.should.equal(answerAsk[0])
        bid.price.should.equal(+answerAsk[1])
        bid.amount.should.equal(+answerAsk[2])
    });

    it("Should order bids/asks in the order they were added", async function () {
        const intervalId = 0
        const contract = await makeContractInPeriod("BIDDING", intervalId)

        const bid1 = {
            intervalId: intervalId,
            sender: accounts[0],
            amount: 5,
            price: 100
        }
        const bid2 = {
            intervalId: intervalId,
            sender: accounts[1],
            amount: 5,
            price: 100
        }

        await contract.submitBid.sendTransaction(bid1.intervalId, bid1.amount, bid1.price, { from: bid1.sender })
        await contract.submitBid.sendTransaction(bid2.intervalId, bid2.amount, bid2.price, { from: bid2.sender })
        const answer1 = await contract.bids.call(bid1.intervalId, 0)
        const answer2 = await contract.bids.call(bid1.intervalId, 1)

        bid1.sender.should.equal(answer1[0])
        bid2.sender.should.equal(answer2[0])
    });

    it("should match bids and asks by time", async function () {
        const intervalId = 1
        const contractOpts = {
            clearingDuration: 30
        }

        const contract = await makeContractInPeriod("BIDDING", intervalId, contractOpts)

        const bidsAsks = [
            { amount: 100, price: 100, sender: 1, isBid: true },
            { amount: 100, price: 80, sender: 2, isBid: true },
            { amount: 100, price: 140, sender: 3, isBid: true },
            { amount: 200, price: 50, sender: 4, isBid: true },
            { amount: 50, price: 85, sender: 6, isBid: false },
            { amount: 50, price: 100, sender: 7, isBid: false },
            { amount: 300, price: 80, sender: 8, isBid: false },
            { amount: 50, price: 150, sender: 9, isBid: false }
        ]
        for (bidAsk of bidsAsks) {
            await placeBidAsk(contract, bidAsk, accounts)
        }
        // was set to very end of bidding period, adding clearing duration moves it to very end of clearing duration
        await contract.setCurrentTime.sendTransaction(+ await contract.currentTime()+contractOpts.clearingDuration)
        
        await contract.clearInterval.sendTransaction(intervalId)

        const getTrade = async (intervalId, tradeId) => {
            const t = await contract.trades.call(intervalId, tradeId)
            return {
                producer: accounts.findIndex(a => a == t[0]),
                consumer: accounts.findIndex(a => a == t[1]),
                price: +t[2],
                amount: +t[3]
            }
        }
        const trades = [
            {producer: 1, consumer: 7, price: 100, amount: 50},
            {producer: 1, consumer: 9, price: 150, amount: 50},
            {producer: 2, consumer: 6, price: 85, amount: 50},
            {producer: 2, consumer: 8, price: 80, amount: 50},
            {producer: 4, consumer: 8, price: 80, amount: 200},
        ]
        for (let tradeId=0; tradeId < trades.length; tradeId++) {
            trades[tradeId].should.deepEqual(await getTrade(1, tradeId))
        }
    })
});
