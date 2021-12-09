import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { constants, utils } from "ethers";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import {
  FuruGelatoMock,
  ActionMock,
  AFurucomboMock,
  ATreviMock,
  AQuickswapFarmMock,
  CreateTaskHandler,
  TaskTimer,
  IDSProxy,
  DSProxyFactory,
  DSGuard,
  Foo,
  RQuickswapFarm,
} from "../typechain";

const gelatoAddress = "0x3CACa7b48D0573D793d3b0279b5F0029180E83b6";

describe("TaskTimer", function () {
  this.timeout(0);
  let user0: SignerWithAddress;
  let owner: SignerWithAddress;
  let executor: any;

  let dsProxy: IDSProxy;

  let dsGuard: DSGuard;
  let dsProxyFactory: DSProxyFactory;
  let furuGelato: FuruGelatoMock;
  let action: ActionMock;
  let aFurucombo: AFurucomboMock;
  let aQuickswapFarm: AQuickswapFarmMock;

  let taskHandler: CreateTaskHandler;
  let rQuickswapFarm: RQuickswapFarm;
  let foo: Foo;

  beforeEach(async function () {
    [user0, owner] = await ethers.getSigners();
    executor = await ethers.provider.getSigner(gelatoAddress);

    const furuGelatoF = await ethers.getContractFactory("FuruGelatoMock");
    const actionF = await ethers.getContractFactory("ActionMock");
    const aFurucomboF = await ethers.getContractFactory("AFurucomboMock");
    const aQuickswapFarmF = await ethers.getContractFactory(
      "AQuickswapFarmMock"
    );
    const dsProxyFactoryF = await ethers.getContractFactory("DSProxyFactory");
    const dsGuardF = await ethers.getContractFactory("DSGuard");
    const dsProxyF = await ethers.getContractFactory("DSProxy");
    const rQuickswapFarmF = await ethers.getContractFactory("RQuickswapFarm");
    const fooF = await ethers.getContractFactory("Foo");

    const taskHandlerF = await ethers.getContractFactory("CreateTaskHandler");

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [gelatoAddress],
    });

    const furuGelatoD = await furuGelatoF.connect(owner).deploy(gelatoAddress);
    const actionD = await actionF.deploy();
    const aFurucomboD = await aFurucomboF.deploy();
    const aQuickswapFarmD = await aQuickswapFarmF.deploy();
    const dsProxyFactoryD = await dsProxyFactoryF.deploy();
    const dsGuardD = await dsGuardF.deploy();
    const rQuickswapFarmD = await rQuickswapFarmF
      .connect(owner)
      .deploy(
        actionD.address,
        furuGelatoD.address,
        aQuickswapFarmD.address,
        aFurucomboD.address,
        180
      );
    const fooD = await fooF.deploy();

    const taskHandlerD = await taskHandlerF.deploy(furuGelatoD.address);

    dsProxyFactory = (await ethers.getContractAt(
      "DSProxyFactory",
      dsProxyFactoryD.address
    )) as DSProxyFactory;

    dsGuard = (await ethers.getContractAt(
      "DSGuard",
      dsGuardD.address
    )) as DSGuard;

    furuGelato = (await ethers.getContractAt(
      "FuruGelatoMock",
      furuGelatoD.address
    )) as FuruGelatoMock;

    action = (await ethers.getContractAt(
      "ActionMock",
      actionD.address
    )) as ActionMock;

    aFurucombo = (await ethers.getContractAt(
      "AFurucomboMock",
      aFurucomboD.address
    )) as AFurucomboMock;

    aQuickswapFarm = (await ethers.getContractAt(
      "AQuickswapFarmMock",
      aQuickswapFarmD.address
    )) as AQuickswapFarmMock;

    rQuickswapFarm = (await ethers.getContractAt(
      "RQuickswapFarm",
      rQuickswapFarmD.address
    )) as RQuickswapFarm;

    foo = (await ethers.getContractAt("Foo", fooD.address)) as Foo;

    taskHandler = (await ethers.getContractAt(
      "CreateTaskHandler",
      taskHandlerD.address
    )) as CreateTaskHandler;

    const cache = await dsProxyFactory.cache();

    const dsProxyD = await dsProxyF.deploy(cache);
    dsProxy = (await ethers.getContractAt(
      "IDSProxy",
      dsProxyD.address,
      user0
    )) as IDSProxy;

    const any = await dsGuard.ANY();
    await dsGuard
      .connect(user0)
      ["permit(address,address,bytes32)"](
        furuGelato.address,
        dsProxy.address,
        any
      );

    await expect(dsProxy.connect(user0).setAuthority(dsGuard.address))
      .to.emit(dsProxy, "LogSetAuthority")
      .withArgs(dsGuard.address);

    const config = utils.hexlify(constants.MaxUint256);
    // const data0 = aTrevi.interface.encodeFunctionData(
    //   "harvestAngelsAndCharge",
    //   [aTrevi.address, [], []]
    // );
    // const data1 = aFurucombo.interface.encodeFunctionData(
    //   "injectAndBatchExec",
    //   [[], [], [], [], [], []]
    // );
    // const data2 = aTrevi.interface.encodeFunctionData("deposit", [
    //   aTrevi.address,
    //   0,
    // ]);

    // actionData = action.interface.encodeFunctionData("multiCall", [
    //   [aTrevi.address, aFurucombo.address, aTrevi.address],
    //   [config, config, config],
    //   [data0, data1, data2],
    // ]);
  });

  describe("checker", () => {
    it("create invalid task should fail", async () => {
      const fooData = foo.interface.encodeFunctionData("bar");
      const fooConfig = utils.hexlify(constants.MaxUint256);
      const fooTarget = foo.address;
      const fooActionData = action.interface.encodeFunctionData("multiCall", [
        [fooTarget],
        [fooConfig],
        [fooData],
      ]);
      const dsCreateTask = taskHandler.interface.encodeFunctionData(
        "createTask",
        [rQuickswapFarm.address, fooActionData]
      );
      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask)
      ).to.be.revertedWith("Invalid tos length");
    });

    it("create task with wrong function selector should fail", async () => {
      const config = utils.hexlify(constants.MaxUint256);
      const data0 = aQuickswapFarm.interface.encodeFunctionData(
        "getRewardAndCharge",
        [aQuickswapFarm.address]
      );
      const data1 = aQuickswapFarm.interface.encodeFunctionData("dQuickLeave");
      const data2 = aFurucombo.interface.encodeFunctionData(
        "injectAndBatchExec",
        [[], [], [], [], [], []]
      );
      const actionDataWrong = action.interface.encodeFunctionData("multiCall", [
        [
          aQuickswapFarm.address,
          aQuickswapFarm.address,
          aFurucombo.address,
          aQuickswapFarm.address,
        ],
        [config, config, config, config],
        [data0, data1, data2, data2],
      ]);
      const dsCreateTask = taskHandler.interface.encodeFunctionData(
        "createTask",
        [rQuickswapFarm.address, actionDataWrong]
      );

      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask)
      ).to.be.revertedWith("Invalid datas");
    });
  });

  describe("onCreateTask", () => {
    it("should update the time when task created", async () => {
      const dsCreateTask = taskHandler.interface.encodeFunctionData(
        "createTask",
        [rQuickswapFarm.address, actionData]
      );
      const taskId = await rQuickswapFarm.getTaskId(
        dsProxy.address,
        rQuickswapFarm.address,
        actionData
      );
      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask)
      )
        .to.emit(furuGelato, "TaskCreated")
        .withArgs(dsProxy.address, taskId, rQuickswapFarm.address, actionData);

      expect(await taskTimer.lastExecTimes(taskId)).to.be.gt(
        ethers.BigNumber.from("0")
      );
    });
  });
});
