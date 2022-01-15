import { ethers, deployments, getNamedAccounts } from "hardhat";
import { expect } from "./chai-setup";
import { Signer } from "ethers";
import { Water } from "../typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signers";

describe("Water Tests", () => {
  let user1: SignerWithAddress;
  let water: Water;
  beforeEach("Deploy and initialize", async () => {
    [user1] = await ethers.getSigners();
    await deployments.fixture("water");
    water = await ethers.getContract("Water");
  });

  describe("minting atoms", () => {
    it("mint hydrogen", async () => {
      await water
        .connect(user1)
        .mintHydrogen(2, { value: ethers.utils.parseEther("0.1") });
      const balance = await water.balanceOf(user1.address, 0);
      expect(balance).to.eq(2);
    });
    it("mint oxygen", async () => {
      await water
        .connect(user1)
        .mintOxygen(1, { value: ethers.utils.parseEther("0.1") });
      const balance = await water.balanceOf(user1.address, 1);
      expect(balance).to.be.eq(1);
    });
  });

  describe("water creation and deletion ", () => {
    it("mint water", async () => {
      await water
        .connect(user1)
        .mintHydrogen(2, { value: ethers.utils.parseEther("0.1") });
      await water
        .connect(user1)
        .mintOxygen(1, { value: ethers.utils.parseEther("0.1") });
      await water.connect(user1).setApprovalForAll(water.address, true);
      await water.connect(user1).makeWater(1);
      const hydrogenBalance = await water.balanceOf(user1.address, 0);
      const oxygenBalance = await water.balanceOf(user1.address, 1);
      const waterBalance = await water.balanceOf(user1.address, 2);
      expect(hydrogenBalance.isZero()).to.be.true;
      expect(oxygenBalance.isZero()).to.be.true;
      expect(waterBalance).to.be.eq(1);
    });
    it("burn water", async () => {
      await water
        .connect(user1)
        .mintHydrogen(2, { value: ethers.utils.parseEther("0.1") });
      await water
        .connect(user1)
        .mintOxygen(1, { value: ethers.utils.parseEther("0.1") });
      const startBalance = await ethers.provider.getBalance(water.address);
      await water.connect(user1).setApprovalForAll(water.address, true);
      await water.connect(user1).makeWater(1);
      await water.connect(user1).breakWater(1);
      const hydrogenBalance = await water.balanceOf(user1.address, 0);
      const oxygenBalance = await water.balanceOf(user1.address, 1);
      const waterBalance = await water.balanceOf(user1.address, 2);
      const endBalance = await ethers.provider.getBalance(water.address);
      expect(hydrogenBalance).to.be.eq(2);
      expect(oxygenBalance).to.be.eq(1);
      expect(waterBalance.isZero()).to.be.true;
      expect(endBalance.sub(startBalance)).to.be.eq(
        ethers.utils.parseEther("-0.19")
      );
    });
  });
});
