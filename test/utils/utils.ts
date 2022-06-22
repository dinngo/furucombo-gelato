import { ethers, network } from "hardhat";

export async function impersonateAndInjectEther(address: string) {
  _impersonateAndInjectEther(address);
  return await (ethers as any).getSigner(address);
}

export async function _impersonateAndInjectEther(address: string) {
  // Impersonate pair
  await network.provider.send("hardhat_impersonateAccount", [address]);

  // Inject 1 ether
  await network.provider.send("hardhat_setBalance", [
    address,
    "0xde0b6b3a7640000",
  ]);
}
