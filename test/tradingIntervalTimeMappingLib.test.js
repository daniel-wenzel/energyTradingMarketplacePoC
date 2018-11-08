const Marketplace = artifacts.require("./Marketplace.sol");
const should = require('should');

const {makeDefaultContract} = require("./util")



contract('TradingIntervalTimeMappingLib', function (accounts) {

    it("should correctly initialized the trading intervals", async function () {
        const opts = {
            startTime: 400
        }
        const contract = await makeDefaultContract(opts)
        const startTimeOfFirstInterval = +await contract.getStartOfInterval(0)

        startTimeOfFirstInterval.should.equal(opts.startTime)
    })

    it("should correctly calculate start and end times of future intervals", async function () {
        const opts = {
            startTime: 400,
            tradingIntervalLength: 120
        }
        const contract = await makeDefaultContract(opts)

        const startTimeOfFirstInterval = +await contract.getStartOfInterval(0)
        const endTimeOfFirstInterval = +await contract.getEndOfInterval(0)
        startTimeOfFirstInterval.should.equal(opts.startTime)
        endTimeOfFirstInterval.should.equal(opts.startTime + opts.tradingIntervalLength)


        const intervalId = 763
        const startTimeOfFutureInterval = +await contract.getStartOfInterval(intervalId)
        const endTimeOfFutureInterval = +await contract.getEndOfInterval(intervalId)

        startTimeOfFutureInterval.should.equal(opts.startTime + opts.tradingIntervalLength * intervalId)
        endTimeOfFutureInterval.should.equal(opts.startTime + opts.tradingIntervalLength * (intervalId + 1))

    })

    it("should correctly calculate the interval of a timestamp", async function () {
        const opts = {
            startTime: 400,
            tradingIntervalLength: 120
        }
        const contract = await makeDefaultContract(opts)

        const intervalIds = [1, 763]
        for (intervalId of intervalIds) {
            // this is the smallest and largest timestamp which should be in this interval
            const startTimestamp = intervalId * opts.tradingIntervalLength + opts.startTime
            const endTimestamp = (intervalId + 1) * opts.tradingIntervalLength + opts.startTime - 1
            const lastTimestampOfPreviousInterval = startTimestamp - 1
            const firstTimestampOfNextInterval = endTimestamp + 1

            const intervalIdFromContractStart = + await contract.getIntervalId(startTimestamp)
            const intervalIdFromContractEnd = + await contract.getIntervalId(endTimestamp)
            const intervalIdFromContractPrevious = + await contract.getIntervalId(lastTimestampOfPreviousInterval)
            const intervalIdFromContractNext = + await contract.getIntervalId(firstTimestampOfNextInterval)

            intervalIdFromContractStart.should.equal(intervalId)
            intervalIdFromContractEnd.should.equal(intervalId)
            intervalIdFromContractPrevious.should.equal(intervalId - 1)
            intervalIdFromContractNext.should.equal(intervalId + 1)
        }
    })

    it("should return the correct periods for an interval", async function() {
        const opts = {
            startTime: 400,
            tradingIntervalLength: 120,
            biddingDuration: 90,
            clearingDuration: 30
        }
        const contract = await makeDefaultContract(opts)

        const periods = ["PRIOR_BIDDING", "BIDDING", "CLEARING", "TRADING", "POST_TRADING"]

        const getPeriod = async (timestamp, intervalId) => {
            await contract.setCurrentTime(timestamp)
            return periods[+ await contract.getIntervalState(intervalId)]
        }

        const intervalIds = [1, 764]
        for (intervalId of intervalIds) {
            let time = opts.startTime + intervalId * opts.tradingIntervalLength - opts.clearingDuration - opts.biddingDuration
            await getPeriod(time -1, intervalId).should.finally.equal(periods[0])
            await getPeriod(time, intervalId).should.finally.equal(periods[1])
    
            time += opts.biddingDuration
            await getPeriod(time -1, intervalId).should.finally.equal(periods[1])
            await getPeriod(time, intervalId).should.finally.equal(periods[2])
    
            time += opts.clearingDuration
            await getPeriod(time -1, intervalId).should.finally.equal(periods[2])
            await getPeriod(time, intervalId).should.finally.equal(periods[3])
    
            time += opts.tradingIntervalLength
            await getPeriod(time -1, intervalId).should.finally.equal(periods[3])
            await getPeriod(time, intervalId).should.finally.equal(periods[4])
        }
    })
})