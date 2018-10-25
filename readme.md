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


## Incentivizing Users to call clearInterval() as soon as possible
It is crucial for the application that clearInterval() is excuted for each trading interval before the start time of the trading interval. Furthermore, it is desirable that users can bid for as long as possible before the start of the trading interval. clearInterval must be triggered from outside, which costs gas. 
**possible solutions**:
1. **Create a system-wide program which calls clearInterval:** Introduces a single point of failure and is therefore not desirable.
2. **Give monetary reward to people who call clearInterval:** Multiple people run a program which listens for new blocks and calls clearInterval when possible. The transaction which is included first in the block will receive the reward, the others will receive nothing. Users must send a large amount of gas for the transaction to run. Due to the new revert() opcode, the unused gas will be refunded and not deleted. The cost for calling clearInterval and reverting is approximately 25000 gas. We then need a client application which checks when an interval can be cleared and then tries to clear it. This could be running on our clients or we could use [existing services](https://ethereum-alarm-clock.readthedocs.io/en/latest/introduction.html).