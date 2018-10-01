var MetaCoin = artifacts.require("./MetaCoin.sol");
var TradingInterval = artifacts.require("./TradingInterval.sol");
const should = require('should');

contract('TradingInterval', function(accounts) {
  it("Should return correct future intervals", async function() {
    const start = Math.floor(Date.now() / 1000)
    const interval = 15*60
    const actualStartTime = Math.floor(start / interval) * interval

    const contract = await TradingInterval.new(start, interval)

    assert.equal(+await contract.getIntervalId.call(actualStartTime + 17*interval), 17)
    assert.equal(+await contract.getIntervalId.call(actualStartTime + 17*interval-1), 16)

    assert.equal(+await contract.getStartOfInterval.call(17), actualStartTime + 17*interval)
    assert.equal(+await contract.getEndOfInterval.call(17), actualStartTime + 18*interval)
  });
});
