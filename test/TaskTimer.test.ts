import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { constants, utils } from "ethers";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import {
  FuruGelatoMock,
  ActionMock,
  AFurucomboMock,
  ATreviMock,
  CreateTaskHandler,
  TaskTimer,
  IDSProxy,
  DSProxyFactory,
  DSGuard,
  Foo,
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
  let aTrevi: ATreviMock;

  let taskHandler: CreateTaskHandler;
  let taskTimer: TaskTimer;
  let foo: Foo;

  let actionData: any;

  const fee = ethers.utils.parseEther("0");

  beforeEach(async function () {
    [user0, owner] = await ethers.getSigners();
    executor = await ethers.provider.getSigner(gelatoAddress);

    const furuGelatoF = await ethers.getContractFactory("FuruGelatoMock");
    const actionF = await ethers.getContractFactory("ActionMock");
    const aFurucomboF = await ethers.getContractFactory("AFurucomboMock");
    const aTreviF = await ethers.getContractFactory("ATreviMock");
    const dsProxyFactoryF = await ethers.getContractFactory("DSProxyFactory");
    const dsGuardF = await ethers.getContractFactory("DSGuard");
    const dsProxyF = await ethers.getContractFactory("DSProxy");
    const taskTimerF = await ethers.getContractFactory("TaskTimer");
    const fooF = await ethers.getContractFactory("Foo");

    const taskHandlerF = await ethers.getContractFactory("CreateTaskHandler");

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [gelatoAddress],
    });

    const furuGelatoD = await furuGelatoF.connect(owner).deploy(gelatoAddress);
    const actionD = await actionF.deploy();
    const aFurucomboD = await aFurucomboF.deploy();
    const aTreviD = await aTreviF.deploy();
    const dsProxyFactoryD = await dsProxyFactoryF.deploy();
    const dsGuardD = await dsGuardF.deploy();
    const taskTimerD = await taskTimerF
      .connect(owner)
      .deploy(
        actionD.address,
        furuGelatoD.address,
        aFurucomboD.address,
        aTreviD.address,
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

    aTrevi = (await ethers.getContractAt(
      "ATreviMock",
      aTreviD.address
    )) as ATreviMock;

    taskTimer = (await ethers.getContractAt(
      "TaskTimer",
      taskTimerD.address
    )) as TaskTimer;

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
    const data0 = aTrevi.interface.encodeFunctionData(
      "harvestAngelsAndCharge",
      [aTrevi.address, [], []]
    );
    const data1 = aFurucombo.interface.encodeFunctionData(
      "injectAndBatchExec",
      [[], [], [], [], [], []]
    );
    const data2 = aTrevi.interface.encodeFunctionData("deposit", [
      aTrevi.address,
      0,
    ]);

    actionData = action.interface.encodeFunctionData("multiCall", [
      [aTrevi.address, aFurucombo.address, aTrevi.address],
      [config, config, config],
      [data0, data1, data2],
    ]);
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
        [taskTimer.address, fooActionData]
      );
      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask)
      ).to.be.revertedWith("Invalid tos length");
    });
  });

  describe("onCreateTask", () => {
    it("should update the time when task created", async () => {
      const dsCreateTask = taskHandler.interface.encodeFunctionData(
        "createTask",
        [taskTimer.address, actionData]
      );
      const taskId = await taskTimer.getTaskId(
        dsProxy.address,
        taskTimer.address,
        actionData
      );
      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask)
      )
        .to.emit(furuGelato, "TaskCreated")
        .withArgs(dsProxy.address, taskId, taskTimer.address, actionData);
      expect(await taskTimer.lastExecTimes(taskId)).to.be.gt(
        ethers.BigNumber.from("0")
      );
    });
  });

  describe("onCancelTask", () => {
    beforeEach(async () => {
      const dsCreateTask = taskHandler.interface.encodeFunctionData(
        "createTask",
        [taskTimer.address, actionData]
      );

      await dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask);
    });

    it("should reset the time when task is canceled", async () => {
      const taskId = await taskTimer.getTaskId(
        dsProxy.address,
        taskTimer.address,
        actionData
      );
      const dsCancelTask = taskHandler.interface.encodeFunctionData(
        "cancelTask",
        [taskTimer.address, actionData]
      );

      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCancelTask)
      )
        .to.emit(furuGelato, "TaskCancelled")
        .withArgs(dsProxy.address, taskId, taskTimer.address, actionData);
      expect(await taskTimer.lastExecTimes(taskId)).to.be.eql(
        ethers.BigNumber.from("0")
      );
    });
  });

  describe("onExec", () => {
    beforeEach(async () => {
      const dsCreateTask = taskHandler.interface.encodeFunctionData(
        "createTask",
        [taskTimer.address, actionData]
      );

      await dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask);
    });

    it("should execute and set timer when condition passes", async () => {
      expect(await aTrevi.count()).to.be.eql(ethers.BigNumber.from("0"));
      expect(await aFurucombo.count()).to.be.eql(ethers.BigNumber.from("0"));

      const taskId = await taskTimer.getTaskId(
        dsProxy.address,
        taskTimer.address,
        actionData
      );
      await expect(
        furuGelato
          .connect(executor)
          .exec(fee, dsProxy.address, taskTimer.address, actionData)
      ).to.be.revertedWith("Not yet");

      let lastExecTime = await taskTimer.lastExecTimes(taskId);
      const THREE_MIN = 3 * 60;

      await network.provider.send("evm_increaseTime", [THREE_MIN]);
      await network.provider.send("evm_mine", []);

      await furuGelato
        .connect(executor)
        .exec(fee, dsProxy.address, taskTimer.address, actionData);
      expect(await aTrevi.count()).to.be.eql(ethers.BigNumber.from("2"));
      expect(await aFurucombo.count()).to.be.eql(ethers.BigNumber.from("1"));
      expect(await taskTimer.lastExecTimes(taskId)).to.be.gt(
        lastExecTime.add(ethers.BigNumber.from(THREE_MIN))
      );
    });

    it("should be able to execute again with modified period", async () => {
      const ONE_MIN = 60;

      await network.provider.send("evm_increaseTime", [ONE_MIN]);
      await network.provider.send("evm_mine", []);

      await expect(
        furuGelato
          .connect(executor)
          .exec(fee, dsProxy.address, taskTimer.address, actionData)
      ).to.be.revertedWith("Not yet");

      await expect(taskTimer.connect(owner).setPeriod(ONE_MIN))
        .to.emit(taskTimer, "PeriodSet")
        .withArgs(ONE_MIN);

      await furuGelato
        .connect(executor)
        .exec(fee, dsProxy.address, taskTimer.address, actionData);
      expect(await aTrevi.count()).to.be.eql(ethers.BigNumber.from("2"));
      expect(await aFurucombo.count()).to.be.eql(ethers.BigNumber.from("1"));
    });
  });
});
