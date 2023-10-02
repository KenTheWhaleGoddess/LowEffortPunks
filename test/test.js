const {
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Test", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployLEP() {
    

    // Contracts are deployed using the first signer/account by default
    const [owner, account1, account2] = await ethers.getSigners();

    const LEP = await ethers.getContractFactory("LowEffortPunks");
    const lep = await LEP.deploy([10000000000,1000000000,20000,10000,true], [], []);

    return { lep, owner, account1, account2 };
  }

  describe("Test", function () {
    it("Should work", async function () {
      const { lep, owner, account1, account2 } = await loadFixture(deployLEP);

      
    });
  });
});
