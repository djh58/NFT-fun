import { ethers, deployments, getNamedAccounts, network } from "hardhat";
import { expect } from "./chai-setup";
import { providers, Signer } from "ethers";
import { GovernanceNFT, TestToken } from "../typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signers";
import { getTime, TimeUnits, advanceTime } from "./utils";

describe("Governance NFT Tests", () => {
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let token: TestToken;
  let nft: GovernanceNFT;
  beforeEach("Deploy and initialize", async () => {
    [user1, user2] = await ethers.getUnnamedSigners();
    await deployments.fixture("gov");
    token = await ethers.getContract("TestToken");
    nft = await ethers.getContract("GovernanceNFT");
  });

  describe("staking", () => {
    it("four year lockup has correct votes", async () => {
      await token
        .connect(user1)
        .mint(user1.address, ethers.utils.parseEther("1000000"));
      const lockupAmount = ethers.utils.parseEther("1000000");
      await token.connect(user1).approve(nft.address, lockupAmount);
      const latestBlock = await ethers.provider.getBlock("latest");
      const time = latestBlock.timestamp;
      const lockupPeriod = getTime(4, TimeUnits.YEARS);
      const lockupTime = time + lockupPeriod + 1;
      const lockup = await nft.connect(user1).lockup(lockupAmount, lockupTime);
      const balance = await token.balanceOf(user1.address);
      const votes = await nft.getVotes(user1.address);
      expect(balance.isZero()).to.be.true;
      expect(votes).to.eq(lockupAmount);
    });
    it("two year lockup has correct votes", async () => {
      await token
        .connect(user1)
        .mint(user1.address, ethers.utils.parseEther("2000000"));
      const lockupAmount = ethers.utils.parseEther("2000000");
      const voteAmount = ethers.utils.parseEther("1000000");
      await token.connect(user1).approve(nft.address, lockupAmount);
      const latestBlock = await ethers.provider.getBlock("latest");
      const time = latestBlock.timestamp;
      const lockupPeriod = getTime(2, TimeUnits.YEARS);
      const lockupTime = time + lockupPeriod + 1;
      await nft.connect(user1).lockup(lockupAmount, lockupTime);
      const balance = await token.balanceOf(user1.address);
      expect(balance.isZero()).to.be.true;
      expect(await nft.getVotes(user1.address)).to.eq(voteAmount);
    });
  });
  describe("un-staking", () => {
    const lockupAmount = ethers.utils.parseEther("1000000");
    beforeEach("1 million votes in 4 year lockup", async () => {
      await token
        .connect(user1)
        .mint(user1.address, ethers.utils.parseEther("1000000"));
      await token.connect(user1).approve(nft.address, lockupAmount);
      const latestBlock = await ethers.provider.getBlock("latest");
      const time = latestBlock.timestamp;
      const lockupPeriod = getTime(4, TimeUnits.YEARS);
      const lockupTime = time + lockupPeriod + 1;
      await nft.connect(user1).lockup(lockupAmount, lockupTime);
      await advanceTime(4, TimeUnits.YEARS);
      await nft.connect(user1).release(0);
    });
    it("removes votes", async () => {
      const nftBal = await nft.balanceOf(user1.address);

      expect(nftBal).to.be.eq(0);
    });
    it("returns correct balance", async () => {
      const balance = await token.balanceOf(user1.address);
      expect(balance).to.be.eq(lockupAmount);
    });
  });
  describe("transfer nft", () => {
    const lockupAmount = ethers.utils.parseEther("1000000");
    beforeEach("1 million votes in 4 year lockup", async () => {
      await token
        .connect(user1)
        .mint(user1.address, ethers.utils.parseEther("1000000"));

      await token.connect(user1).approve(nft.address, lockupAmount);
      const latestBlock = await ethers.provider.getBlock("latest");
      const time = latestBlock.timestamp;
      const lockupPeriod = getTime(4, TimeUnits.YEARS);
      const lockupTime = time + lockupPeriod + 1;
      await nft.connect(user1).lockup(lockupAmount, lockupTime);
      const balance = await token.balanceOf(user1.address);
      const tokenId = await nft._nftOwned(user1.address);
      await nft
        .connect(user1)
        .transferFrom(user1.address, user2.address, tokenId);
    });
    it("wipes votes", async () => {
      expect(await nft.getVotes(user2.address)).to.eq(0);
    });
    it("maintains staked amount", async () => {
      await nft.connect(user2).approve(nft.address, 1);
      await advanceTime(4, TimeUnits.YEARS);
      await nft.connect(user2).release(0);
      expect(await token.balanceOf(user2.address)).to.be.eq(lockupAmount);
    });
  });
});
