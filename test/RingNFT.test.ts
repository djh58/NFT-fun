import { ethers, deployments, getNamedAccounts, network } from "hardhat";
import { expect } from "./chai-setup";
import { providers, Signer } from "ethers";
import { RingNFT } from "../typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signers";
import { getTime, TimeUnits, advanceTime } from "./utils";

describe("Ring NFT Tests", () => {
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let deployer: SignerWithAddress;
  let nft: RingNFT;
  const testDeadline = 15821889; // TODO: change to now + N interval. need to retrieve current block timestamp from HH EVM
  beforeEach("Deploy and initialize", async () => {
    [user1, user2] = await ethers.getUnnamedSigners();
    [deployer] = await ethers.getSigners();
    await deployments.fixture("ring");
    nft = await ethers.getContract("RingNFT");
  });

  describe("Proposer actions", () => {
    it("happy path", async () => {
      const amount = ethers.utils.parseEther("1");
      expect(
        await nft.connect(user1).propose(user2.address, "test", testDeadline, {
          value: amount,
        })
      ).changeBalance(await user1.getAddress(), amount);
    });
  });

  describe("Proposee actions", () => {
    it("happy path", async () => {});
  });

  describe("Dev wallet actions", () => {
    it("happy path", async () => {});
  });
});
