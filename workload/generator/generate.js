const fs = require("fs")
const csv = require("fast-csv");
const yaml = require('js-yaml');

const workloadConfigs = yaml.safeLoad(fs.readFileSync('workload/generator/workloads.yml', 'utf8'));

function* standardDistribution(min, max) {
    while (true) {
        yield Math.floor(min + (max-min)*Math.random())
    } 
}

function* idGenerator(numHouseholds) {
    let i = 0
    while (true)
        yield (i++ % numHouseholds)
}

function* bidAskGenerator(prosumerShare) {
    while(true)
        yield (Math.random() < prosumerShare? "BID": "ASK")
}

function generateBidAsk(type, idIt, priceIt, amountIt) {
    return {
        type,
        amount: amountIt.next().value,
        price: priceIt.next().value,
        senderId: idIt.next().value
    }
}

function* makeWorkload(w) {

    const numHouseholds = w.numMarketActions
    //const intervalLength = 15

    const prosumerShare = w.bidShare
    const bidAmounts = standardDistribution(w.bidAmounts.min, w.bidAmounts.max)
    const askAmounts = standardDistribution(w.askAmounts.min, w.askAmounts.max)
    
    const askPrices = standardDistribution(w.askPrices.min, w.askPrices.max)
    const bidPrices = standardDistribution(w.bidPrices.min, w.bidPrices.max)
    
    const ids = idGenerator(numHouseholds)
    const bidAsks = bidAskGenerator(prosumerShare)
    
    for (let i=0; i<numHouseholds; i++) {
        const type = bidAsks.next().value
        if (type === "BID") {
            yield generateBidAsk(type, ids, bidPrices, bidAmounts)
        }
        else {
            yield generateBidAsk(type, ids, askPrices, askAmounts)
        }
    }
}

for (workloadConfig of workloadConfigs) {
    var csvStream = csv.createWriteStream({headers: true}),
    writableStream = fs.createWriteStream(`test/workloads/definitions/${workloadConfig.name}.csv`);
    csvStream.pipe(writableStream);
    for (entry of makeWorkload(workloadConfig)) {
        csvStream.write(entry)
    }
    csvStream.end();
}