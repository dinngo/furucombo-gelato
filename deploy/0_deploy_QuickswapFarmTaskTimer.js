const utils = ethers.utils;

// beta parameter
const gelatoAddress = "0xCFED8d811a30AFF6A0aDA7d866811BaaA17f2Cc7";
const taskExecutor = "0x522a8bDE53341fcB37525C24731F575453c4A146";
const aQuickswapFarm = "0xa34A5C4687AE6ab889BC67D575F3C21467Ec055E";
const aFurucombo = "0xC8B14BFcdf744459aEae87F762AFe6C943ddD7EA";
const gnosisAddress = "0x64585922a9703d9EdE7d353a6522eb2970f75066";
const period = 60;
const fakeKey =
  "d74d952106fcdc7fe598eea01a3e9f5a081d928cea7869e9921e69abc5a7dd44";

module.exports = async ({ getNamedAccounts, deployments }) => {
  if (network.name != "beta") {
    console.log(
      "QuickswapFarmTaskTimer deployment script only used for beta network."
    );
    return;
  }

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const provider = ethers.provider;
  const signer = new ethers.Wallet(fakeKey, provider);

  // deploy resolver
  await deploy("QuickswapFarmTaskTimer", {
    from: deployer,
    args: [taskExecutor, gelatoAddress, aQuickswapFarm, aFurucombo, period],
    log: true,
  });
  const quickswapFarmTaskTimer = await ethers.getContract(
    "QuickswapFarmTaskTimer",
    deployer
  );

  // register to FuruGelato
  const iface = new utils.Interface([
    "function registerResolver(address _resolverAddress)",
  ]);

  const registerData = iface.encodeFunctionData("registerResolver", [
    quickswapFarmTaskTimer.address,
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

module.exports.tags = ["QuickswapFarmTaskTimer"];
