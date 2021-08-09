import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import {
  FuruGelato,
  ActionMock,
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

  let taskHandler: CreateTaskHandler;
  let taskTimer: TaskTimer;
  let foo: Foo;

  before(async function () {
    [user0, owner] = await ethers.getSigners();
    executor = await ethers.provider.getSigner(gelatoAddress);

    const furuGelatoF = await ethers.getContractFactory("FuruGelato");
    const actionF = await ethers.getContractFactory("ActionMock");
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
    const dsProxyFactoryD = await dsProxyFactoryF.deploy();
    const dsGuardD = await dsGuardF.deploy();
    const taskTimerD = await taskTimerF.deploy(
      actionD.address,
      furuGelatoD.address,
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

    taskTimer = (await ethers.getContractAt(
      "TaskTimer",
      taskTimerD.address
    )) as TaskTimer;

    await expect(furuGelato.connect(owner).registerResolver(taskTimer.address))
      .to.emit(furuGelato, "ResolverWhitelistAdded")
      .withArgs(taskTimer.address);

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

  it("check create and cancel task", async () => {
    const fooData = foo.interface.encodeFunctionData("bar");
    const fooTarget = foo.address;
    const actionData = action.interface.encodeFunctionData("multiCall", [
      [fooTarget],
      [fooData],
    ]);
    const dsCreateTask = taskHandler.interface.encodeFunctionData(
      "createTask",
      [taskTimer.address, actionData]
    );
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
      dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask)
    )
      .to.emit(furuGelato, "TaskCreated")
      .withArgs(dsProxy.address, taskId, taskTimer.address, actionData);

    await expect(
      dsProxy.connect(user0).execute(taskHandler.address, dsCancelTask)
    )
      .to.emit(furuGelato, "TaskCancelled")
      .withArgs(dsProxy.address, taskId, taskTimer.address, actionData);

    await dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask);
  });

  it("exec when condition passes", async () => {
    expect(await foo.ok()).to.be.false;
    const fooData = foo.interface.encodeFunctionData("bar");
    const fooTarget = foo.address;
    const actionData = action.interface.encodeFunctionData("multiCall", [
      [fooTarget],
      [fooData],
    ]);
    const target = taskTimer.address;
    const fee = ethers.utils.parseEther("1");

    await expect(
      furuGelato
        .connect(executor)
        .exec(fee, dsProxy.address, taskTimer.address, actionData)
    ).to.be.revertedWith("Checker failed");

    const THREE_MIN = 3 * 60;

    await network.provider.send("evm_increaseTime", [THREE_MIN]);
    await network.provider.send("evm_mine", []);

    await furuGelato
      .connect(executor)
      .exec(fee, dsProxy.address, taskTimer.address, actionData);

    expect(await foo.ok()).to.be.true;
  });
});
