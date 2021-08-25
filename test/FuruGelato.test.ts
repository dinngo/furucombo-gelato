import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { constants, utils } from "ethers";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import {
  FuruGelato,
  ActionMock,
  CreateTaskHandler,
  ResolverMock,
  IDSProxy,
  DSProxyFactory,
  DSGuard,
  Foo,
} from "../typechain";

const gelatoAddress = "0x3CACa7b48D0573D793d3b0279b5F0029180E83b6";

describe("FuruGelato", function () {
  let user0: SignerWithAddress;
  let owner: SignerWithAddress;
  let executor: any;

  let dsProxy: IDSProxy;

  let dsGuard: DSGuard;
  let dsProxyFactory: DSProxyFactory;
  let furuGelato: FuruGelato;
  let action: ActionMock;

  let taskHandler: CreateTaskHandler;
  let resolver: ResolverMock;
  let foo: Foo;

  let actionData: any;

  const fee = ethers.utils.parseEther("1");

  beforeEach(async () => {
    [user0, owner] = await ethers.getSigners();
    executor = await ethers.provider.getSigner(gelatoAddress);

    const furuGelatoF = await ethers.getContractFactory("FuruGelato");
    const actionF = await ethers.getContractFactory("ActionMock");
    const dsProxyFactoryF = await ethers.getContractFactory("DSProxyFactory");
    const dsGuardF = await ethers.getContractFactory("DSGuard");
    const dsProxyF = await ethers.getContractFactory("DSProxy");
    const resolverF = await ethers.getContractFactory("ResolverMock");
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
    const resolverD = await resolverF
      .connect(owner)
      .deploy(actionD.address, furuGelatoD.address);
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

    resolver = (await ethers.getContractAt(
      "ResolverMock",
      resolverD.address
    )) as ResolverMock;

    await expect(furuGelato.connect(owner).registerResolver(resolver.address))
      .to.emit(furuGelato, "ResolverWhitelistAdded")
      .withArgs(resolver.address);

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

    await expect(furuGelato.connect(owner).registerResolver(resolver.address))
      .to.emit(furuGelato, "ResolverWhitelistAdded")
      .withArgs(resolver.address);

    const fooData = foo.interface.encodeFunctionData("bar");
    const fooConfig = utils.hexlify(constants.MaxUint256);
    const fooTarget = foo.address;
    actionData = action.interface.encodeFunctionData("multiCall", [
      [fooTarget],
      [fooConfig],
      [fooData],
    ]);
  });

  describe("create task", () => {
    it("normal", async () => {
      const dsCreateTask = taskHandler.interface.encodeFunctionData(
        "createTask",
        [resolver.address, actionData]
      );
      const taskId = await furuGelato.getTaskId(
        dsProxy.address,
        resolver.address,
        actionData
      );

      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask)
      )
        .to.emit(furuGelato, "TaskCreated")
        .withArgs(dsProxy.address, taskId, resolver.address, actionData);
    });

    it("create on invalid resolver should fail", async () => {
      await expect(
        furuGelato.connect(owner).unregisterResolver(resolver.address)
      )
        .to.emit(furuGelato, "ResolverWhitelistRemoved")
        .withArgs(resolver.address);

      const dsCreateTask = taskHandler.interface.encodeFunctionData(
        "createTask",
        [resolver.address, actionData]
      );
      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask)
      ).to.be.revertedWith("Invalid resolver");
    });

    it("create by an invalid DSProxy", async () => {
      await expect(furuGelato.connect(owner).banDSProxy(dsProxy.address))
        .to.emit(furuGelato, "DSProxyBlacklistAdded")
        .withArgs(dsProxy.address);

      const dsCreateTask = taskHandler.interface.encodeFunctionData(
        "createTask",
        [resolver.address, actionData]
      );

      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask)
      ).to.be.revertedWith("Invalid dsProxy");
    });

    it("create an extsted task", async () => {
      const dsCreateTask = taskHandler.interface.encodeFunctionData(
        "createTask",
        [resolver.address, actionData]
      );
      const taskId = await furuGelato.getTaskId(
        dsProxy.address,
        resolver.address,
        actionData
      );

      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask)
      )
        .to.emit(furuGelato, "TaskCreated")
        .withArgs(dsProxy.address, taskId, resolver.address, actionData);

      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask)
      ).to.be.revertedWith("Sender already started task");
    });
  });

  describe("cancel task", () => {
    beforeEach(async () => {
      const dsCreateTask = taskHandler.interface.encodeFunctionData(
        "createTask",
        [resolver.address, actionData]
      );
      await dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask);
    });

    it("normal", async () => {
      const taskId = await furuGelato.getTaskId(
        dsProxy.address,
        resolver.address,
        actionData
      );
      const dsCancelTask = taskHandler.interface.encodeFunctionData(
        "cancelTask",
        [resolver.address, actionData]
      );
      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCancelTask)
      )
        .to.emit(furuGelato, "TaskCancelled")
        .withArgs(dsProxy.address, taskId, resolver.address, actionData);
    });

    it("canceling a task not existed", async () => {
      const taskId = await furuGelato.getTaskId(
        dsProxy.address,
        resolver.address,
        actionData
      );
      const dsCancelTask = taskHandler.interface.encodeFunctionData(
        "cancelTask",
        [resolver.address, actionData]
      );
      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCancelTask)
      )
        .to.emit(furuGelato, "TaskCancelled")
        .withArgs(dsProxy.address, taskId, resolver.address, actionData);
      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCancelTask)
      ).to.be.revertedWith("Sender did not start task yet");
    });

    it("canceling an invalidated task", async () => {
      const taskId = await furuGelato.getTaskId(
        dsProxy.address,
        resolver.address,
        actionData
      );
      await expect(furuGelato.connect(owner).banTask(taskId))
        .to.emit(furuGelato, "TaskBlacklistAdded")
        .withArgs(taskId);
      const dsCancelTask = taskHandler.interface.encodeFunctionData(
        "cancelTask",
        [resolver.address, actionData]
      );
      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCancelTask)
      )
        .to.emit(furuGelato, "TaskCancelled")
        .withArgs(dsProxy.address, taskId, resolver.address, actionData);
    });

    it("canceling an task of invalid DSProxy", async () => {
      const taskId = await furuGelato.getTaskId(
        dsProxy.address,
        resolver.address,
        actionData
      );
      await expect(furuGelato.connect(owner).banDSProxy(dsProxy.address))
        .to.emit(furuGelato, "DSProxyBlacklistAdded")
        .withArgs(dsProxy.address);
      const dsCancelTask = taskHandler.interface.encodeFunctionData(
        "cancelTask",
        [resolver.address, actionData]
      );
      await expect(
        dsProxy.connect(user0).execute(taskHandler.address, dsCancelTask)
      )
        .to.emit(furuGelato, "TaskCancelled")
        .withArgs(dsProxy.address, taskId, resolver.address, actionData);
    });
  });

  describe("execute task", () => {
    beforeEach(async () => {
      const dsCreateTask = taskHandler.interface.encodeFunctionData(
        "createTask",
        [resolver.address, actionData]
      );

      await dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask);
    });

    it("normal", async () => {
      const taskId = await furuGelato.getTaskId(
        dsProxy.address,
        resolver.address,
        actionData
      );
      await expect(
        furuGelato
          .connect(executor)
          .exec(fee, dsProxy.address, resolver.address, actionData)
      )
        .to.emit(furuGelato, "ExecSuccess")
        .withArgs(
          fee,
          "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
          dsProxy.address,
          taskId
        );
    });

    it("should revert when resolver unregistered", async () => {
      await expect(
        furuGelato.connect(owner).unregisterResolver(resolver.address)
      )
        .to.emit(furuGelato, "ResolverWhitelistRemoved")
        .withArgs(resolver.address);
      await expect(
        furuGelato
          .connect(executor)
          .exec(fee, dsProxy.address, resolver.address, actionData)
      ).to.be.revertedWith("Invalid resolver");

      await expect(furuGelato.connect(owner).registerResolver(resolver.address))
        .to.emit(furuGelato, "ResolverWhitelistAdded")
        .withArgs(resolver.address);

      await furuGelato
        .connect(executor)
        .exec(fee, dsProxy.address, resolver.address, actionData);
    });

    it("exec repeatedly ", async () => {
      await furuGelato
        .connect(executor)
        .exec(fee, dsProxy.address, resolver.address, actionData);

      await furuGelato
        .connect(executor)
        .exec(fee, dsProxy.address, resolver.address, actionData);
    });

    it("executing an invalid DSProxy's task", async () => {
      await expect(furuGelato.connect(owner).banDSProxy(dsProxy.address))
        .to.emit(furuGelato, "DSProxyBlacklistAdded")
        .withArgs(dsProxy.address);

      await expect(
        furuGelato
          .connect(executor)
          .exec(fee, dsProxy.address, resolver.address, actionData)
      ).to.revertedWith("Invalid dsProxy");
    });

    it("executing an invalid task", async () => {
      const taskId = await furuGelato.getTaskId(
        dsProxy.address,
        resolver.address,
        actionData
      );
      await expect(furuGelato.connect(owner).banTask(taskId))
        .to.emit(furuGelato, "TaskBlacklistAdded")
        .withArgs(taskId);
      await expect(
        furuGelato
          .connect(executor)
          .exec(fee, dsProxy.address, resolver.address, actionData)
      ).to.revertedWith("invalid task");
    });
  });
});
