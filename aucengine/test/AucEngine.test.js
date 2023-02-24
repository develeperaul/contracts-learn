const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AucEngine", function () {
  let owner;
  let seller;
  let buyer;
  let auct;

  beforeEach(async function () {
    [owner, seller, buyer] = await ethers.getSigners();
    const AucEngineCotract = await ethers.getContractFactory(
      "AucEngine",
      owner
    );
    auct = await AucEngineCotract.deploy();
    await auct.deployed();
  });
  it("sets owner", async function () {
    const currentOwner = await auct.owner();
    console.log(currentOwner);
    expect(currentOwner).to.eq(owner.address);
  });

  async function getTimestamp(blockNumber) {
    return (await ethers.provider.getBlock(blockNumber)).timestamp;
  }

  describe("createAuction", function () {
    it("create auction correctly", async function () {
      const duration = 60;
      const tx = await auct.createAuction(
        ethers.utils.parseEther("0.0001"),
        3,
        "Fake item",
        duration
      );

      const cAuction = await auct.auctions(0);

      expect(cAuction.item).to.eq("Fake item");
      const ts = await getTimestamp(tx.blockNumber);
      expect(cAuction.endsAt).to.eq(ts + duration);
    });
  });

  function delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
  describe("buy", function () {
    it("allows to buy", async function () {
      const duration = 60;
      const tx = await auct
        .connect(seller)
        .createAuction(
          ethers.utils.parseEther("0.0001"),
          3,
          "Fake item",
          duration
        );
      this.timeout(5000);
      await delay(1000);

      const buyTx = await auct
        .connect(buyer)
        .buy(0, { value: ethers.utils.parseEther("0.0001") });

      const cAuction = await auct.auctions(0);
      const finalPrice = cAuction.finalPrice;
      console.log(finalPrice);
      await expect(() => buyTx).to.changeEtherBalance(
        seller,
        finalPrice - Math.floor((finalPrice * 10) / 100)
      );

      await expect(buyTx)
        .to.emit(auct, "AuctionEnded")
        .withArgs(0, finalPrice, buyer.address);

      await expect(
        auct.connect(buyer).buy(0, { value: ethers.utils.parseEther("0.0001") })
      ).to.be.rejectedWith("stopped");
    });
  });
});
