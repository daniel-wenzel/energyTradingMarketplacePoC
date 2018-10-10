# Energy Marketplace PoC

This Proof of Concept simulates on chain P2P energy trading. Prosumers can make bids and asks for energy in a specific target interval. Bids and Asks are matched into trades which the participants can then execute.

## Getting started
Make sure you have node.js, truffle and ganache installed. Running the tests:
```
npm i
truffle test --network development
```

## Interval Model

![Interval Model](/docs/img/intervals.png)

Prosumers place bid and ask for a specific marketplace-wide trading interval. Bids and asks for a specific interval can only be place during the bidding period. Bids ands asks for a trading interval can be matched into trades during the clearing period.

All trading intervals have the same lengths and are assigned a consecutive ID. In the constructor of the smart contract, the start time of the first trading interval, the trading interval length, clearing period length and bidding period length are specified.

## Client API
- **placeBid(tradingIntervalID, amount, price)**: Bids an amount of energy for a trading interval for a set price per unit. Only possible during bidding period of trading interval.
- **placeAsk(tradingIntervalID, amount, price)**: Ask for an amount of energy for a trading interval for a set price per unit. Only possible during bidding period of trading interval.
- **clearInterval(tradingIntervalID)**: Matches all bids and asks in the trading interval and forms trades out of them. A trade consists of a producer, a consumer, an amount and a price. Only possible during clearing period of trading interval. **TODO: Incentivize users to call this**
- **settleTrade(tradingIntervalID, tradeID)**: **TODO: further specify**
