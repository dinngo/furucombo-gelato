import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { constants, utils } from "ethers";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import {
  FuruGelato,
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

describe("FuruGelato", function () {
  this.timeout(0);
  let user0: SignerWithAddress;
  let owner: SignerWithAddress;
  let executor: any;

  let dsProxy: IDSProxy;

  let dsGuard: DSGuard;
  let dsProxyFactory: DSProxyFactory;
  let furuGelato: FuruGelato;
  let action: ActionMock;
  let aFurucombo: AFurucomboMock;
  let aTrevi: ATreviMock;

  let taskHandler: CreateTaskHandler;
  let treviTaskTimer: TaskTimer;
  let foo: Foo;

  before(async function () {
    [user0, owner] = await ethers.getSigners();
    executor = await ethers.provider.getSigner(gelatoAddress);

    const furuGelatoF = await ethers.getContractFactory("FuruGelato");
    const actionF = await ethers.getContractFactory("ActionMock");
    const aFurucomboF = await ethers.getContractFactory("AFurucomboMock");
    const aTreviF = await ethers.getContractFactory("ATreviMock");
    const dsProxyFactoryF = await ethers.getContractFactory("DSProxyFactory");
    const dsGuardF = await ethers.getContractFactory("DSGuard");
    const dsProxyF = await ethers.getContractFactory("DSProxy");
    const treviTaskTimerF = await ethers.getContractFactory("TreviTaskTimer");
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
    const treviTaskTimerD = await treviTaskTimerF
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
      "FuruGelato",
      furuGelatoD.address
    )) as FuruGelato;

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

    treviTaskTimer = (await ethers.getContractAt(
      "TaskTimer",
      treviTaskTimerD.address
    )) as TaskTimer;

    await expect(
      furuGelato.connect(owner).registerResolver(treviTaskTimer.address)
    )
      .to.emit(furuGelato, "ResolverWhitelistAdded")
      .withArgs(treviTaskTimer.address);

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

    await user0.sendTransaction({
      value: ethers.utils.parseEther("5"),
      to: furuGelato.address,
    });
  });

  it("create invalid task should fail", async () => {
    const fooData = foo.interface.encodeFunctionData("bar");
    const fooConfig = utils.hexlify(constants.MaxUint256);
    const fooTarget = foo.address;
    const actionData = action.interface.encodeFunctionData("multiCall", [
      [fooTarget],
      [fooConfig],
      [fooData],
    ]);
    const dsCreateTask = taskHandler.interface.encodeFunctionData(
      "createTask",
      [treviTaskTimer.address, actionData]
    );
    await expect(
      dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask)
    ).to.be.revertedWith("Invalid tos length");
  });

  it("create on invalid resolver should fail", async () => {
    await expect(
      furuGelato.connect(owner).unregisterResolver(treviTaskTimer.address)
    )
      .to.emit(furuGelato, "ResolverWhitelistRemoved")
      .withArgs(treviTaskTimer.address);
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
    const actionData = action.interface.encodeFunctionData("multiCall", [
      [aTrevi.address, aFurucombo.address, aTrevi.address],
      [config, config, config],
      [data0, data1, data2],
    ]);
    const dsCreateTask = taskHandler.interface.encodeFunctionData(
      "createTask",
      [treviTaskTimer.address, actionData]
    );
    await expect(
      dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask)
    ).to.be.revertedWith("Invalid resolver");

    await expect(
      furuGelato.connect(owner).registerResolver(treviTaskTimer.address)
    )
      .to.emit(furuGelato, "ResolverWhitelistAdded")
      .withArgs(treviTaskTimer.address);
  });

  it("check create and cancel task", async () => {
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
    const actionData = action.interface.encodeFunctionData("multiCall", [
      [aTrevi.address, aFurucombo.address, aTrevi.address],
      [config, config, config],
      [data0, data1, data2],
    ]);
    const dsCreateTask = taskHandler.interface.encodeFunctionData(
      "createTask",
      [treviTaskTimer.address, actionData]
    );
    const taskId = await treviTaskTimer.getTaskId(
      dsProxy.address,
      treviTaskTimer.address,
      actionData
    );
    const dsCancelTask = taskHandler.interface.encodeFunctionData(
      "cancelTask",
      [treviTaskTimer.address, actionData]
    );

    await expect(
      dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask)
    )
      .to.emit(furuGelato, "TaskCreated")
      .withArgs(dsProxy.address, taskId, treviTaskTimer.address, actionData);

    await expect(
      dsProxy.connect(user0).execute(taskHandler.address, dsCancelTask)
    )
      .to.emit(furuGelato, "TaskCancelled")
      .withArgs(dsProxy.address, taskId, treviTaskTimer.address, actionData);

    await dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask);
  });

  it("exec when condition passes", async () => {
    expect(await aTrevi.count()).to.be.eql(ethers.BigNumber.from("0"));
    expect(await aFurucombo.count()).to.be.eql(ethers.BigNumber.from("0"));
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
    const actionData = action.interface.encodeFunctionData("multiCall", [
      [aTrevi.address, aFurucombo.address, aTrevi.address],
      [config, config, config],
      [data0, data1, data2],
    ]);
    const fee = ethers.utils.parseEther("1");

    await expect(
      furuGelato
        .connect(executor)
        .exec(fee, dsProxy.address, treviTaskTimer.address, actionData)
    ).to.be.revertedWith("Not yet");

    const THREE_MIN = 3 * 60;

    await network.provider.send("evm_increaseTime", [THREE_MIN]);
    await network.provider.send("evm_mine", []);

    await furuGelato
      .connect(executor)
      .exec(fee, dsProxy.address, treviTaskTimer.address, actionData);

    expect(await aTrevi.count()).to.be.eql(ethers.BigNumber.from("2"));
    expect(await aFurucombo.count()).to.be.eql(ethers.BigNumber.from("1"));
  });

  it("should revert when resolver unregistered", async () => {
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
    const actionData = action.interface.encodeFunctionData("multiCall", [
      [aTrevi.address, aFurucombo.address, aTrevi.address],
      [config, config, config],
      [data0, data1, data2],
    ]);
    const fee = ethers.utils.parseEther("1");
    await expect(
      furuGelato.connect(owner).unregisterResolver(treviTaskTimer.address)
    )
      .to.emit(furuGelato, "ResolverWhitelistRemoved")
      .withArgs(treviTaskTimer.address);

    const THREE_MIN = 3 * 60;

    await network.provider.send("evm_increaseTime", [THREE_MIN]);
    await network.provider.send("evm_mine", []);

    await expect(
      furuGelato
        .connect(executor)
        .exec(fee, dsProxy.address, treviTaskTimer.address, actionData)
    ).to.be.revertedWith("Invalid resolver");

    await expect(
      furuGelato.connect(owner).registerResolver(treviTaskTimer.address)
    )
      .to.emit(furuGelato, "ResolverWhitelistAdded")
      .withArgs(treviTaskTimer.address);

    await furuGelato
      .connect(executor)
      .exec(fee, dsProxy.address, treviTaskTimer.address, actionData);

    expect(await aTrevi.count()).to.be.eql(ethers.BigNumber.from("4"));
    expect(await aFurucombo.count()).to.be.eql(ethers.BigNumber.from("2"));
  });

  it("exec again with modified period", async () => {
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
    const actionData = action.interface.encodeFunctionData("multiCall", [
      [aTrevi.address, aFurucombo.address, aTrevi.address],
      [config, config, config],
      [data0, data1, data2],
    ]);
    const fee = ethers.utils.parseEther("1");

    const ONE_MIN = 60;

    await network.provider.send("evm_increaseTime", [ONE_MIN]);
    await network.provider.send("evm_mine", []);

    await expect(
      furuGelato
        .connect(executor)
        .exec(fee, dsProxy.address, treviTaskTimer.address, actionData)
    ).to.be.revertedWith("Not yet");

    await expect(treviTaskTimer.connect(owner).setPeriod(ONE_MIN))
      .to.emit(treviTaskTimer, "PeriodSet")
      .withArgs(ONE_MIN);

    await furuGelato
      .connect(executor)
      .exec(fee, dsProxy.address, treviTaskTimer.address, actionData);

    expect(await aTrevi.count()).to.be.eql(ethers.BigNumber.from("6"));
    expect(await aFurucombo.count()).to.be.eql(ethers.BigNumber.from("3"));
  });
});
