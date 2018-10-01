pragma solidity ^0.4.23;

contract TradingInterval {
  // Intervals in the past are not relevant for the application, this is the interval at contract creation and will always be 0 in the internal id system
  uint private intervalStartingOffset;
  // length of an interval
  uint public intervalLength;

  constructor(uint _intervalStartingTime, uint _intervalLength) public {
    require(_intervalLength >= 1 minutes);
    require(_intervalLength <= 60 minutes);

    intervalStartingOffset = _intervalStartingTime / _intervalLength;
    intervalLength = _intervalLength;
  }

  function getIntervalId(uint timestamp) public returns (uint) {
      return timestamp / intervalLength - intervalStartingOffset;
  }
  function getStartOfInterval(uint intervalId) public returns (uint) {
      return (intervalId + intervalStartingOffset) * intervalLength;
  }
  function getEndOfInterval(uint intervalId) public returns (uint) {
      return getStartOfInterval(intervalId + 1);
  }
}