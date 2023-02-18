// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract AucEngine {
    address public owner;
    uint constant DURATION = 2 days;
    uint constant FEE = 10;

    event AuctionCreate(uint index, string itemName, uint startingPrice, uint duration);
    event AuctionEnded(uint index, uint finalPrice, address winner);
    
    struct Auction {
        address payable seller;
        uint startPrice;
        uint finalPrice;
        uint startAt;
        uint endsAt;
        uint discountRate;
        string item;
        bool stopped;
    }
    Auction[] public auctions;
    constructor(){
        owner = msg.sender;
    }

    function createAuction(uint _startingPrice, uint _discountRate, string memory _item, uint _duration ) external{
        uint duration = _duration == 0 ? DURATION : _duration;
        require(_startingPrice >= _discountRate * duration, "incorrect starting price");
        Auction memory newAuction =  Auction({
            seller: payable(msg.sender),
            startPrice: _startingPrice,
            finalPrice: _startingPrice,
            discountRate: _discountRate,
            startAt: block.timestamp,
            endsAt: block.timestamp + duration,
            item: _item,
            stopped: false
        });

        auctions.push(newAuction);

        emit AuctionCreate(auctions.length -1, _item, _startingPrice, duration);
    }

    function getPriceFor(uint index) public view returns(uint){
        Auction memory cAuction = auctions[index];
        require(!cAuction.stopped, "stopped");
        uint elapsed = block.timestamp - cAuction.startAt;
        uint discount = cAuction.discountRate * elapsed;
        return cAuction.startPrice - discount;
    }

    function buy(uint index) external payable {
        Auction memory cAuction = auctions[index];
        require(!cAuction.stopped, "stopped");
        require(block.timestamp < cAuction.endsAt, "ended");
        uint cPrice = getPriceFor(index);
        require(msg.value >= cPrice, "not enough funds");
        cAuction.stopped = true;
        cAuction.finalPrice = cPrice;
        uint refund = msg.value - cPrice;
        if(refund >0){
            payable(msg.sender).transfer(refund);
        }

        cAuction.seller.transfer(
            cPrice - ((cPrice * FEE) / 100)
        );

        emit AuctionEnded(index, cPrice, msg.sender);
    }
}