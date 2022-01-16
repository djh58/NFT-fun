import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction, DeployResult } from "hardhat-deploy/types";
import { BigNumber } from "ethers";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const token = await deploy("TestToken", {
    from: deployer,
    log: true,
    autoMine: true,
  });

  await deploy("GovernanceNFT", {
    from: deployer,
    log: true,
    autoMine: true,
    args: [token.address],
  });
};
export default func;
func.tags = ["gov"];
