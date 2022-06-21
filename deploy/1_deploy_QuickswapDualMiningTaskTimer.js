const utils = ethers.utils;

// beta parameter
const gelatoAddress = "0xCFED8d811a30AFF6A0aDA7d866811BaaA17f2Cc7";
const taskExecutor = "0x522a8bDE53341fcB37525C24731F575453c4A146";
const aQuickswapDualMining = "0x1B742498dA0Aa60aE55e7a8673105635DBD7C64B";
const aFurucombo = "0x38D0C02d846A8420DcfEb4F2d73591c9C69E5425";
const gnosisAddress = "0x64585922a9703d9EdE7d353a6522eb2970f75066";
const period = 60;
const fakeKey =
  "d74d952106fcdc7fe598eea01a3e9f5a081d928cea7869e9921e69abc5a7dd44";

module.exports = async ({ getNamedAccounts, deployments }) => {
  if (network.name != "beta") {
    console.log(
      "QuickswapDualMiningTaskTimer deployment script only used for beta network."
    );
    return;
  }

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const provider = ethers.provider;
  const signer = new ethers.Wallet(fakeKey, provider);

  // deploy resolver
  await deploy("QuickswapDualMiningTaskTimer", {
    from: deployer,
    args: [
      taskExecutor,
      gelatoAddress,
      aQuickswapDualMining,
      aFurucombo,
      period,
    ],
    log: true,
  });
  const QuickswapDualMiningTaskTimer = await ethers.getContract(
    "QuickswapDualMiningTaskTimer",
    deployer
  );

  // register to FuruGelato
  const iface = new utils.Interface([
    "function registerResolver(address _resolverAddress)",
  ]);

  const registerData = iface.encodeFunctionData("registerResolver", [
    QuickswapDualMiningTaskTimer.address,
  ]);

  const customData = registerData + "ff00ff" + gnosisAddress.replace("0x", "");

  const nonce = await provider.getTransactionCount(gnosisAddress);

  await signer.sendTransaction({
    to: gelatoAddress,
    nonce: nonce,
    data: customData,
    gasLimit: 10000000,
  });
};

module.exports.tags = ["QuickswapDualMiningTaskTimer"];
