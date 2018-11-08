var Marketplace = artifacts.require("./Marketplace.sol");
const should = require('should');

require('truffle-test-utils').init();
const { makeContractInPeriod, shouldHaveEmittedTradesFactory } = require("../util")
const shouldHaveEmittedTrades = shouldHaveEmittedTradesFactory(assert)

async function placeBidAsksAndClear(contract, marketActions) {
    for (marketAction of marketActions) {
        if (marketAction.type == "BID") {
            await contract.submitBid(marketAction.intervalId, marketAction.amount, marketAction.price, { from: marketAction.sender })
        }
        if (marketAction.type == "ASK") {
            await contract.submitAsk(marketAction.intervalId, marketAction.amount, marketAction.price, { from: marketAction.sender })
        }
    }
    // Move to clearing period
    await contract.setPeriod("CLEARING", marketActions[0].intervalId)

    const receipt = await contract.clearInterval(marketActions[0].intervalId)
    return receipt
}

contract('Marketplace - mengelkamp clearing', function (accounts) {
    it("should match a bid and ask with equal prices and amounts", async function () {
        const intervalId = 0
        const contract = await makeContractInPeriod("BIDDING", intervalId, { clearingAlgorithm: "MENGELKAMP" })

        const bid = {
            intervalId: intervalId,
            sender: accounts[0],
            amount: 5,
            price: 100
        }

        await contract.submitBid.sendTransaction(bid.intervalId, bid.amount, bid.price)
        await contract.submitAsk(bid.intervalId, bid.amount, bid.price)
        // Move to clearing period
        await contract.setPeriod("CLEARING", bid.intervalId)

        const receipt = await contract.clearInterval(bid.intervalId)
        shouldHaveEmittedTrades(receipt, {
            intervalId: intervalId,
            from: accounts[0],
            to: accounts[0],
            amount: 5,
            price: 100
        })
    });

    it("should match correctly in a simple scenario", async function () {
        const intervalId = 0
        const contract = await makeContractInPeriod("BIDDING", intervalId, { clearingAlgorithm: "MENGELKAMP" })

        const marketActions = [
            {
                intervalId: intervalId,
                sender: accounts[1],
                amount: 2,
                price: 120,
                type: "BID",
                trades: []
            },
            {
                intervalId: intervalId,
                sender: accounts[2],
                amount: 5,
                price: 50,
                type: "BID"
            },
            {
                intervalId: intervalId,
                sender: accounts[3],
                amount: 20,
                price: 200,
                type: "ASK"
            },
            {
                intervalId: intervalId,
                sender: accounts[4],
                amount: 20,
                price: 180,
                type: "ASK"
            },
        ]
        const receipt = await placeBidAsksAndClear(contract, marketActions)
        
        shouldHaveEmittedTrades(receipt, [{
            intervalId: intervalId,
            from: accounts[2],
            to: accounts[3],
            amount: 5,
            price: 120
        },
        {
            intervalId: intervalId,
            from: accounts[1],
            to: accounts[3],
            amount: 2,
            price: 120
        }
        ])
    });
    it("should not allow any trades when a single extremely pricey offer exists", async function () {
        const intervalId = 0
        const contract = await makeContractInPeriod("BIDDING", intervalId, { clearingAlgorithm: "MENGELKAMP" })

        const marketActions = [
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
                type: "BID"
            },
            {
                intervalId: intervalId,
                sender: accounts[3],
                amount: 2,
                price: 3000,
                type: "BID"
            },
            {
                intervalId: intervalId,
                sender: accounts[3],
                amount: 20,
                price: 200,
                type: "ASK"
            },
            {
                intervalId: intervalId,
                sender: accounts[4],
                amount: 20,
                price: 180,
                type: "ASK"
            },
        ]
        const receipt = await placeBidAsksAndClear(contract, marketActions)
        shouldHaveEmittedTrades(receipt, [])
    });
    it("should not match anything when there is only one bid", async function () {
        const intervalId = 0
        const contract = await makeContractInPeriod("BIDDING", intervalId, { clearingAlgorithm: "MENGELKAMP" })

        const marketActions = [
            {
                intervalId: intervalId,
                sender: accounts[1],
                amount: 5,
                price: 120,
                type: "BID",
                trades: []
            }
        ]
        const receipt = await placeBidAsksAndClear(contract, marketActions)
        shouldHaveEmittedTrades(receipt, [])
    });
    it("should not match anything when there is only one ask", async function () {
        const intervalId = 0
        const contract = await makeContractInPeriod("BIDDING", intervalId, { clearingAlgorithm: "MENGELKAMP" })

        const marketActions = [
            {
                intervalId: intervalId,
                sender: accounts[1],
                amount: 5,
                price: 120,
                type: "ASK",
                trades: []
            }
        ]
        const receipt = await placeBidAsksAndClear(contract, marketActions)
        shouldHaveEmittedTrades(receipt, [])
    });
    it("should not match anything when bid and ask have different price ranges", async function () {
        const intervalId = 0
        const contract = await makeContractInPeriod("BIDDING", intervalId, { clearingAlgorithm: "MENGELKAMP" })

        const marketActions = [
            {
                intervalId: intervalId,
                sender: accounts[1],
                amount: 5,
                price: 120,
                type: "ASK",
                trades: []
            },
            {
                intervalId: intervalId,
                sender: accounts[2],
                amount: 5,
                price: 150,
                type: "BID",
                trades: []
            }
        ]
        const receipt = await placeBidAsksAndClear(contract, marketActions)
        shouldHaveEmittedTrades(receipt, [])
    });
});
