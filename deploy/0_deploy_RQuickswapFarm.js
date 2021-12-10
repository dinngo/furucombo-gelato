// const { ethers } = require("ethers");
const utils = ethers.utils;

const gelatoAddress = "0xCFED8d811a30AFF6A0aDA7d866811BaaA17f2Cc7";
const taskExecutor = "0x522a8bDE53341fcB37525C24731F575453c4A146";
const aQuickswapFarm = "0x9BdEfd0aac9B64027Ef2B546Ed91D315D4c75378";
const aFurucombo = "0x38D0C02d846A8420DcfEb4F2d73591c9C69E5425";
const period = 60;

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const provider = ethers.getDefaultProvider(
    "https://polygon-beta.furucombo.app/"
  );

  // await deploy("RQuickswapFarm", {
  //   from: deployer,
  //   args: [taskExecutor, gelatoAddress, aQuickswapFarm, aFurucombo, period],
  //   log: true,
  // });
  // const rQuickswapFarm = await ethers.getContract("RQuickswapFarm", deployer);
  // console.log("1");

  // get furuGelato contract
  const furuGelato = await (
    await ethers.getContractFactory("FuruGelato")
  ).attach(gelatoAddress);
  console.log("2");

  // register to FuruGelato
  const iface = new utils.Interface([
    "function registerResolver(address _resolverAddress)",
  ]);

  const registerData = iface.encodeFunctionData("registerResolver", [
    aFurucombo,
  ]);
  console.log(registerData);

  const modifyData =
    registerData + "ff00ff" + "64585922a9703d9EdE7d353a6522eb2970f75066";

  console.log(modifyData);

  const nonce = await provider.getTransactionCount(
    "0x64585922a9703d9EdE7d353a6522eb2970f75066"
  );

  // await furuGelato.registerResolver(rQuickswapFarm.address, { from: deployer });
  // console.log("3");
  // const isValid = await furuGelato.isValidResolver(rQuickswapFarm.address, {
  //   from: deployer,
  // });
  // console.log("isValid:" + isValid);
};

module.exports.tags = ["RQuickswapFarm"];
