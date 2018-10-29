var Marketplace = artifacts.require("./Marketplace.sol");
const should = require('should');

require('truffle-test-utils').init();
const { makeContractInPeriod, shouldHaveEmittedTradesFactory } = require("../util")
const shouldHaveEmittedTrades = shouldHaveEmittedTradesFactory(assert)

contract('Marketplace - price time based clearing', function (accounts) {

    it("should match a bid and ask with equal prices and amounts", async function () {
        const intervalId = 0
        const contract = await makeContractInPeriod("BIDDING", intervalId, { clearingAlgorithm: "PRICE_TIME_BASED" })

        const bid = {
            intervalId: intervalId,
            sender: accounts[0],
            amount: 5,
            price: 100
        }

        await contract.submitBid.sendTransaction(bid.intervalId, bid.amount, bid.price)
        const receipt = await contract.submitAsk(bid.intervalId, bid.amount, bid.price)
        shouldHaveEmittedTrades(receipt, {
            intervalId: intervalId,
            from: accounts[0],
            to: accounts[0],
            amount: 5,
            price: 100
        })
    });
    it("should match by price first and then by time", async function () {
        const intervalId = 0
        const contract = await makeContractInPeriod("BIDDING", intervalId, { clearingAlgorithm: "PRICE_TIME_BASED" })

        const bids = [{
            intervalId: intervalId,
            sender: accounts[0],
            amount: 5,
            price: 100
        },
        {
            intervalId: intervalId,
            sender: accounts[1],
            amount: 5,
            price: 100
        },
        {
            intervalId: intervalId,
            sender: accounts[2],
            amount: 5,
            price: 50
        }]
        const ask = {
            intervalId: intervalId,
            sender: accounts[4],
            amount: 10,
            price: 200
        }

        for (bid of bids) {
            await contract.submitBid.sendTransaction(bid.intervalId, bid.amount, bid.price, {from: bid.sender})
        }
        const receipt = await contract.submitAsk(ask.intervalId, ask.amount, ask.price, {from: ask.sender})
        shouldHaveEmittedTrades(receipt, [{
            intervalId: intervalId,
            from: accounts[2],
            to: accounts[4],
            amount: 5,
            price: 50
        }, {
            intervalId: intervalId,
            from: accounts[0],
            to: accounts[4],
            amount: 5,
            price: 100
        }])
    })
    it("should match bids and asks whenever a new bid/ask arrives", async function () {
        const intervalId = 0
        const contract = await makeContractInPeriod("BIDDING", intervalId, { clearingAlgorithm: "PRICE_TIME_BASED" })

        const marketActions = [
            {
                intervalId: intervalId,
                sender: accounts[0],
                amount: 5,
                price: 100,
                type: "ASK",
                trades: []
            },
            {
                intervalId: intervalId,
                sender: accounts[1],
                amount: 5,
                price: 120,
                type: "BID",
                trades: []
            },
            {
                intervalId: intervalId,
                sender: accounts[2],
                amount: 2,
                price: 50,
                type: "BID",
                trades: [
                    {
                        intervalId: intervalId,
                        from: accounts[2],
                        to: accounts[0],
                        amount: 2,
                        price: 50
                    }
                ]
            },
            {
                intervalId: intervalId,
                sender: accounts[3],
                amount: 10,
                price: 100,
                type: "ASK",
                trades: []
            },
            {
                intervalId: intervalId,
                sender: accounts[4],
                amount: 20,
                price: 100,
                type: "BID",
                trades: [
                    {
                        intervalId: intervalId,
                        from: accounts[4],
                        to: accounts[0],
                        amount: 3,
                        price: 100
                    },
                    {
                        intervalId: intervalId,
                        from: accounts[4],
                        to: accounts[3],
                        amount: 10,
                        price: 100
                    },
                ]
            },
            {
                intervalId: intervalId,
                sender: accounts[5],
                amount: 20,
                price: 200,
                type: "ASK",
                trades: [
                    {
                        intervalId: intervalId,
                        from: accounts[4],
                        to: accounts[5],
                        amount: 7,
                        price: 100
                    },
                    {
                        intervalId: intervalId,
                        from: accounts[1],
                        to: accounts[5],
                        amount: 5,
                        price: 120
                    }
                ]
            },
        ]

        for (marketAction of marketActions) {
            let receipt
            if (marketAction.type == "BID") {
                receipt = await contract.submitBid(marketAction.intervalId, marketAction.amount, marketAction.price, {from: marketAction.sender})
            }
            if (marketAction.type == "ASK") {
                receipt = await contract.submitAsk(marketAction.intervalId, marketAction.amount, marketAction.price, {from: marketAction.sender})
            }
            shouldHaveEmittedTrades(receipt, marketAction.trades)
        }
    })

    /*it("should match bids and asks by time", async function () {
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
    })*/
});
