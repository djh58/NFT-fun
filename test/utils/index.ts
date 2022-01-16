import { Contract } from "ethers";
import { ethers, network } from "hardhat";

export async function setupUsers<
  T extends { [contractName: string]: Contract }
>(addresses: string[], contracts: T): Promise<({ address: string } & T)[]> {
  const users: ({ address: string } & T)[] = [];
  for (const address of addresses) {
    users.push(await setupUser(address, contracts));
  }
  return users;
}

export async function setupUser<T extends { [contractName: string]: Contract }>(
  address: string,
  contracts: T
): Promise<{ address: string } & T> {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const user: any = { address };
  for (const key of Object.keys(contracts)) {
    user[key] = contracts[key].connect(await ethers.getSigner(address));
  }
  return user as { address: string } & T;
}

export enum TimeUnits {
  SECONDS = "seconds",
  MINUTES = "minutes",
  HOURS = "hours",
  DAYS = "days",
  WEEKS = "weeks",
  MONTHS = "months",
  YEARS = "years",
}

export function getTime(amount: number, unit: TimeUnits) {
  let netTime: number;
  switch (unit) {
    case TimeUnits.SECONDS:
      netTime = amount;
      break;
    case TimeUnits.MINUTES:
      netTime = amount * 60;
      break;
    case TimeUnits.HOURS:
      netTime = amount * 60 * 60;
      break;
    case TimeUnits.DAYS:
      netTime = amount * 60 * 60 * 24;
      break;
    case TimeUnits.WEEKS:
      netTime = amount * 60 * 60 * 24 * 7;
      break;
    case TimeUnits.MONTHS:
      netTime = amount * 60 * 60 * 24 * 30;
      break;
    case TimeUnits.YEARS:
      netTime = amount * 60 * 60 * 24 * 365;
      break;
    default:
      throw "invalid time unit";
  }
  return netTime;
}
export async function advanceTime(amount: number, unit: TimeUnits) {
  const netTime = getTime(amount, unit);
  await network.provider.send("evm_increaseTime", [netTime]);
  await network.provider.send("evm_mine");
}
