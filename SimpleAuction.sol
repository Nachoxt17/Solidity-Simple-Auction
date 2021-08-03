// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

contract SimpleAuction {
  address payable public beneficiary;
  //+-AuctionEndTime. By Default the time is in Seconds.
  uint256 public auctionEndTime;

  //+-Current State of the Auction:_
  address public highestBidder;
  uint256 public highestBid;

  mapping(address => uint256) public pendingReturns;

  bool ended = false;

  event HighestBidIncrease(address bidder, uint256 amount);
  event AuctionEnded(address winner, uint256 amount);

  constructor(uint256 _biddingTime, address payable _beneficiary) {
    beneficiary =  _beneficiary;
    auctionEndTime = block.timestamp + _biddingTime;
  }

  function bid() public payable {
    if (block.timestamp > auctionEndTime) {
      revert("The auction has already ended");
    }

    if (msg.value <= highestBid) {
      revert("There is already a higher or equal bid");
    }

    if (highestBid != 0) {
      pendingReturns[highestBidder] += highestBid;
    }

    highestBidder = msg.sender;
    highestBid = msg.value;
    emit HighestBidIncrease(msg.sender, msg.value);
  }

  function witdrawAuctionProfitsToUser() public returns (bool) {
    uint256 amount = pendingReturns[msg.sender];
    if(amount > 0) {
      pendingReturns[msg.sender] = 0;

      if(!payable(msg.sender).send(amount)) {
        pendingReturns[msg.sender] = amount;
      }
    }
    return true;
  }

  function auctionEnd() public {
    if (block.timestamp < auctionEndTime) {
      revert("The auction has not ended yet");
    }

    if (ended) {
      revert("The function auctionEnded has already been called");
    }

    ended = true;
    emit AuctionEnded(highestBidder, highestBid);

    beneficiary.transfer(highestBid);
  }
}
