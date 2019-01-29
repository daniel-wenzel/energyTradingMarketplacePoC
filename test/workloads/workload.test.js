var Marketplace = artifacts.require("./Marketplace.sol");
const should = require('should');
const csv = require("fast-csv");
const fs = require("fs")

const {makeContractInPeriod, periods} = require("../util")

const workloads = [
    //"10_actions_20_percent_bids",
    //"50_actions_20_percent_bids",
    //"100_actions_20_percent_bids",
    //"250_actions_20_percent_bids",
    "500_actions_20_percent_bids",
    "750_actions_20_percent_bids",
    "1000_actions_20_percent_bids",
]

contract('Gas Consumption', function (accounts) {
    const placeMarketAction = async (contract, intervalId, marketAction) => {
        if (marketAction.type === "BID") {
            return contract.submitBid(intervalId, +marketAction.amount, +marketAction.price, { from: accounts[+marketAction.senderId % accounts.length] })
        }
        else {
            return contract.submitAsk(intervalId, +marketAction.amount, +marketAction.price, { from: accounts[+marketAction.senderId % accounts.length] })

        }
    }
    const executeWorkload = async (workloadName, algorithm) => {
        const marketActions = await loadWorkload(workloadName)
            const intervalId = 0
            const contract = await makeContractInPeriod("BIDDING", intervalId, { clearingAlgorithm: algorithm })
            const output = fs.createWriteStream(`test/workloads/usages/${algorithm}/${workloadName}.csv`)
            output.write(["gas used", "block number", "num trades"].join(", ")+"\n")
            for (marketAction of marketActions) {
                const {receipt, ...rest} = await placeMarketAction(contract, intervalId, marketAction)
                output.write([receipt.gasUsed, receipt.blockNumber, receipt.logs.length].join(", ")+"\n")
            }
            await contract.setPeriod("CLEARING", intervalId)
            const {receipt, ...rest} = await contract.clearInterval(intervalId, {
                gas: 100 * 1000 * 1000
            })
            output.write([receipt.gasUsed, receipt.blockNumber, receipt.logs.length].join(", ")+"\n")

            output.end()
    }
    it.only(" mengelkamp", async function () {
        for (workload of workloads) {
            await executeWorkload(workload, "MENGELKAMP")
        }
    }).timeout(1000*60*60)
    it(" price time based", async function () {
        for (workload of workloads) {
            await executeWorkload(workload, "PRICE_TIME_BASED")
        }
    }).timeout(1000*60*60)
})

function loadWorkload(workloadName) {
    const path = `test/workloads/definitions/${workloadName}.csv`
    const entries = []
    return new Promise((res, rej) => {
        csv
        .fromPath(path, {headers: true})
        .on("data", function(data){
            entries.push(data)
        })
        .on("end", function(){
            res(entries)
        });
    })
}