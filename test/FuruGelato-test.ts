import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { expect } from "chai";
import { ethers, network, waffle } from "hardhat";
import {
  IProxy,
  IRegistry,
  FuruGelato,
  IncreaseCountHandler,
  CreateTaskHandler,
  Counter,
  IDSProxy,
  DSProxyFactory,
  DSGuard,
} from "../typechain";

const gelatoAddress = "0x3CACa7b48D0573D793d3b0279b5F0029180E83b6";
const furuProxyAddress = "0xA013AfbB9A92cEF49e898C87C060e6660E050569";
const handlerRegistryAddress = "0xd4258B13C9FADb7623Ca4b15DdA34b7b85b842C7";
const Zero = ethers.constants.HashZero;

describe("FuruGelato", function () {
  this.timeout(0);
  let user0: SignerWithAddress;
  let registryOwner: any;
  let executor: any;

  let furuProxy: IProxy;
  let registry: IRegistry;
  let dsProxy: IDSProxy;

  let dsGuard: DSGuard;
  let dsProxyFactory: DSProxyFactory;
  let furuGelato: FuruGelato;
  let countHandler: IncreaseCountHandler;
  let taskHandler: CreateTaskHandler;
  let counter: Counter;

  before(async function () {
    [user0] = await ethers.getSigners();
    executor = await ethers.provider.getSigner(gelatoAddress);

    registry = (await ethers.getContractAt(
      "IRegistry",
      handlerRegistryAddress
    )) as IRegistry;

    const furuGelatoF = await ethers.getContractFactory("FuruGelato");
    const dsProxyFactoryF = await ethers.getContractFactory("DSProxyFactory");
    const dsGuardF = await ethers.getContractFactory("DSGuard");
    const dsProxyF = await ethers.getContractFactory("DSProxy");
    const counterF = await ethers.getContractFactory("Counter");
    const countHandlerF = await ethers.getContractFactory(
      "IncreaseCountHandler"
    );
    const taskHandlerF = await ethers.getContractFactory("CreateTaskHandler");

    const registryOwnerAddress = await registry.owner();

    await user0.sendTransaction({
      value: ethers.utils.parseEther("1"),
      to: registryOwnerAddress,
    });

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [registryOwnerAddress],
    });

    registryOwner = await ethers.provider.getSigner(registryOwnerAddress);

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [gelatoAddress],
    });

    const furuGelatoD = await furuGelatoF
      .connect(registryOwner)
      .deploy(gelatoAddress, furuProxyAddress);
    const dsProxyFactoryD = await dsProxyFactoryF.deploy();
    const dsGuardD = await dsGuardF.deploy();
    const counterD = await counterF.deploy();
    const countHandlerD = await countHandlerF.deploy(
      counterD.address,
      furuGelatoD.address
    );
    const taskHandlerD = await taskHandlerF.deploy(furuGelatoD.address);

    furuProxy = (await ethers.getContractAt(
      "IProxy",
      furuProxyAddress
    )) as IProxy;

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

    counter = (await ethers.getContractAt(
      "Counter",
      counterD.address
    )) as Counter;

    countHandler = (await ethers.getContractAt(
      "IncreaseCountHandler",
      countHandlerD.address
    )) as IncreaseCountHandler;

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

    await registry
      .connect(registryOwner)
      .register(
        countHandler.address,
        ethers.utils.formatBytes32String("IncreaseCountHandler")
      );

    await user0.sendTransaction({
      value: ethers.utils.parseEther("5"),
      to: furuGelato.address,
    });

    // console.log("FuruGelato: ", furuGelato.address);
    // console.log("User0: ", user0.address);
    // console.log("FuruProsy: ", furuProxyAddress);
    // console.log("DSProxy: ", dsProxy.address);
    // console.log("DSGuard: ", dsGuard.address);
    // console.log("Handler: ", countHandler.address);
    // console.log("Count: ", counter.address);
  });

  it("Only owner can whitelist and remove task", async () => {
    const selector = countHandler.interface.getSighash("increaseCount");
    const target = countHandler.address;
    const encode = ethers.utils.defaultAbiCoder.encode(
      ["address[]", "bytes4[]"],
      [[target], [selector]]
    );

    const task = ethers.utils.keccak256(encode);

    await expect(
      furuGelato.connect(user0).whitelistTask([target], [selector])
    ).to.be.revertedWith("Ownable: caller is not the owner");

    await furuGelato.connect(registryOwner).whitelistTask([target], [selector]);
    expect(await furuGelato.getWhitelistedTasks()).to.include(task);

    const whitelisted = await furuGelato.getWhitelistedTasks();

    await furuGelato.connect(registryOwner).removeTask(task);
    expect(await furuGelato.getWhitelistedTasks()).to.not.include(task);

    await furuGelato.connect(registryOwner).whitelistTask([target], [selector]);
  });

  it("check create and cancel task", async () => {
    const execData = countHandler.interface.encodeFunctionData(
      "increaseCount",
      [5]
    );
    const target = countHandler.address;
    const dsCreateTask = taskHandler.interface.encodeFunctionData(
      "createTask",
      [[target], [execData]]
    );
    const dsCancelTask = taskHandler.interface.encodeFunctionData(
      "cancelTask",
      [[target], [execData]]
    );

    const expectedTask = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["address", "address[]", "bytes[]"],
        [dsProxy.address, [target], [execData]]
      )
    );

    await expect(
      dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask)
    )
      .to.emit(furuGelato, "TaskCreated")
      .withArgs(
        dsProxy.address,
        [countHandler.address],
        [execData],
        expectedTask
      );

    await expect(
      dsProxy.connect(user0).execute(taskHandler.address, dsCancelTask)
    )
      .to.emit(furuGelato, "TaskCancelled")
      .withArgs(
        dsProxy.address,
        [countHandler.address],
        [execData],
        expectedTask
      );

    await dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask);
  });

  it("exec when condition passes ", async () => {
    expect(await counter.count()).to.be.eql(ethers.BigNumber.from("0"));

    const execData = countHandler.interface.encodeFunctionData(
      "increaseCount",
      [5]
    );
    const target = countHandler.address;
    const fee = ethers.utils.parseEther("1");

    await expect(
      furuGelato
        .connect(executor)
        .exec(fee, dsProxy.address, [target], [execData])
    ).to.be.revertedWith("FuruGelato: batchExec: Delegatecall failed");

    const THREE_MIN = 3 * 60;

    await network.provider.send("evm_increaseTime", [THREE_MIN]);
    await network.provider.send("evm_mine", []);

    await furuGelato
      .connect(executor)
      .exec(fee, dsProxy.address, [target], [execData]);

    expect(await counter.count()).to.be.eql(ethers.BigNumber.from("5"));
  });
});
