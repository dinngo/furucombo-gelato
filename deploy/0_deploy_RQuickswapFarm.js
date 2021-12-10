const gelatoAddress = "0x3CACa7b48D0573D793d3b0279b5F0029180E83b6";
const taskExecutor = "0x522a8bDE53341fcB37525C24731F575453c4A146";
const aQuickswapFarm = "0x9BdEfd0aac9B64027Ef2B546Ed91D315D4c75378";
const aFurucombo = "0x38D0C02d846A8420DcfEb4F2d73591c9C69E5425";
const period = 60;
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("RQuickswapFarm", {
    from: deployer,
    args: [taskExecutor, gelatoAddress, aQuickswapFarm, aFurucombo, period],
    log: true,
  });
};

module.exports.tags = ["RQuickswapFarm"];
