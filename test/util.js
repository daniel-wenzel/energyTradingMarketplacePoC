const Marketplace = artifacts.require("./Marketplace.sol");

const clearingAlgorithms = ["NONE", "PRICE_TIME_BASED", "MENGELKAMP"]

async function makeContractInPeriod(period, intervalId, opts) {
    period = period || "PRIOR_BIDDING"
    // all values in seconds
    const defaultOptions = {
        startTime: 400,
        tradingIntervalLength: 120,
        biddingDuration: 90,
        clearingDuration: 30,
        dev: true,
        clearingAlgorithm: "NONE"
    }

    const o = Object.assign(defaultOptions, opts)
    const clearingAlgorithmId = clearingAlgorithms.findIndex(a => a == o.clearingAlgorithm)
    const contract = await Marketplace.new(o.startTime, o.tradingIntervalLength, o.clearingDuration, o.biddingDuration, o.dev, clearingAlgorithmId)

    switch (period) {
        case "PRIOR_BIDDING":
            await contract.setCurrentTime.sendTransaction(o.startTime + o.tradingIntervalLength * intervalId - o.clearingDuration - o.biddingDuration - 1)
            break;
        case "BIDDING":
            await contract.setCurrentTime.sendTransaction(o.startTime + o.tradingIntervalLength * intervalId - o.clearingDuration - 1)
            break;
        case "CLEARING":
            await contract.setCurrentTime.sendTransaction(o.startTime + o.tradingIntervalLength * intervalId - 1)
            break;
        case "TRADING":
            await contract.setCurrentTime.sendTransaction(o.startTime + o.tradingIntervalLength * intervalId)
            break;
        case "POST_TRADING":
            await contract.setCurrentTime.sendTransaction(o.startTime + o.tradingIntervalLength * (intervalId + 1))
            break;
        default:
            throw new Error("unrecognized period: " + period)
    }
    return contract
}


async function placeBidAsk(contract, bidAsk, accounts) {
    if (bidAsk.isBid) {
        await contract.submitBid.sendTransaction(1, bidAsk.amount, bidAsk.price, { from: accounts[bidAsk.sender] })
    }
    else {
        await contract.submitAsk.sendTransaction(1, bidAsk.amount, bidAsk.price, { from: accounts[bidAsk.sender] })
    }
}
async function makeDefaultContract(opts) {
    // all values in seconds
    const defaultOptions = {
        startTime: 400,
        tradingIntervalLength: 120,
        biddingDuration: 90,
        clearingDuration: 30,
        dev: true,
        clearingAlgorithm: "NONE"
    }
    const o = Object.assign(defaultOptions, opts)
    const clearingAlgorithmId = clearingAlgorithms.findIndex(a => a == o.clearingAlgorithm)
    const contract = await Marketplace.new(o.startTime, o.tradingIntervalLength, o.clearingDuration, o.biddingDuration, o.dev, clearingAlgorithmId)

    return contract
}

function shouldHaveEmittedTradesFactory(assert) {
    return (receipt, trades) => {
        if (trades.length === undefined) {
            trades = [trades]
        }
        const formatedTrades = trades.map(trade => {
            return {
                event: 'TradeEvent',
                args: trade
            }
        })
        assert.web3AllEvents(receipt, formatedTrades);
    }
}

module.exports = {
    makeDefaultContract,
    makeContractInPeriod,
    placeBidAsk,
    shouldHaveEmittedTradesFactory,
    periods: ["PRIOR_BIDDING", "BIDDING", "CLEARING", "TRADING", "POST_TRADING"]
}