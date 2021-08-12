// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract BlindAuction {
    struct bid 
        {
        bytes32 blindedbid;
        uint deposit;
        }
    address payable public auctionhouse;
    uint revealEnd;
    uint biddingEnd;
    bool auctionended;
    
    mapping (address => bid[]) public bids;
    
    address public highestbidder;
    uint public highestbid;
    
    mapping (address => uint)  pendingbids;
    
    event blindauctionended (address winner, uint highestbid);
    
    error auctionhasended(uint time);
    error auctionhasnotStarted(uint time);

    
    modifier onlyBefore (uint _time) {
        if (block.timestamp > _time) revert auctionhasended (_time); 
        _;
    }
    
    
    modifier onlyAfter (uint _time) {
        if (block.timestamp < _time) revert auctionhasnotStarted (_time); 
        _;
    }
    
    constructor(
        uint _biddingTime,
        uint _revealTime,
        address payable _auctionhouse
    )
    {
    auctionhouse = _auctionhouse;
    biddingEnd = block.timestamp + _biddingTime;
    revealEnd = biddingEnd + _revealTime;
    
    }
   
    function withdraw() public {
        uint amount = pendingbids[msg.sender];
        if (amount>0) {
             pendingbids[msg.sender] = 0;
             payable(msg.sender).transfer(amount);
                    }
        }
    
    function reveal  (
        uint[] memory _values,
        bool[] memory _fake,
        bytes32[] memory _secret
        )
        public
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd)
         {
        uint length = bids[msg.sender].length;
        require(_values.length == length);
        require(_fake.length == length);
        require(_secret.length == length);

        uint refund;
        for (uint i = 0; i < length; i++) {
            bid storage bidToCheck = bids[msg.sender][i];
            (uint value, bool fake, bytes32 secret) =
                    (_values[i], _fake[i], _secret[i]);
            if (bidToCheck.blindedbid != keccak256(abi.encodePacked(value, fake, secret))) {
                continue;
            }
            refund += bidToCheck.deposit;
            if (!fake && bidToCheck.deposit >= value) {
                if (placeBid(msg.sender, value))
                    refund -= value;
            }
            bidToCheck.blindedbid = bytes32(0);
        }
        payable(msg.sender).transfer(refund);
    }
    
    error AuctionEndAlreadyCalled();

    function auctionEnd()
        public
        onlyAfter(revealEnd)
    {
        if (auctionended) revert AuctionEndAlreadyCalled();
        emit blindauctionended(highestbidder, highestbid);
        auctionended = true;
        auctionhouse.transfer(highestbid);
    }
        
    function placeBid(address bidder, uint value) internal
            returns (bool success)
    {
        if (value <= highestbid) {
            return false;
        }
        if (highestbidder != address(0)) {
            // Refund the previously highest bidder.
            pendingbids[highestbidder] += highestbid;
        }
        highestbid = value;
        highestbidder = bidder;
        return true;
    }
    
    
    function sendmoney() public payable {
        
    }
    address public  owner;
    bool public paused;
    
    
    function setpaused (bool _paused) public {
        require(msg.sender == owner , "Hat be lavde");
        paused = _paused;
        
    }
    
    function withdrawmoney (address payable _to) public {
        
        require( msg.sender == owner , " error lavde");
        require ( !paused, " rukja ");
    
        _to.transfer(address(this).balance);
        
    }
    
    function setselfdestruct (address payable _to) public {
        require ( msg.sender == owner , " hat be lavde");
        require (!paused, " ruka hua hai");
        selfdestruct(_to);
    
    }
}