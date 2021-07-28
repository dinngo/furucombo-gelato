import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import {
  FuruGelato,
  CreateTaskHandler,
  Counter,
  IDSProxy,
  DSProxyFactory,
  DSGuard,
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

  let taskHandler: CreateTaskHandler;
  let counter: Counter;

  before(async function () {
    [user0, owner] = await ethers.getSigners();
    executor = await ethers.provider.getSigner(gelatoAddress);

    const furuGelatoF = await ethers.getContractFactory("FuruGelato");
    const dsProxyFactoryF = await ethers.getContractFactory("DSProxyFactory");
    const dsGuardF = await ethers.getContractFactory("DSGuard");
    const dsProxyF = await ethers.getContractFactory("DSProxy");
    const counterF = await ethers.getContractFactory("Counter");

    const taskHandlerF = await ethers.getContractFactory("CreateTaskHandler");

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [gelatoAddress],
    });

    const furuGelatoD = await furuGelatoF.connect(owner).deploy(gelatoAddress);
    const dsProxyFactoryD = await dsProxyFactoryF.deploy();
    const dsGuardD = await dsGuardF.deploy();
    const counterD = await counterF.deploy();

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

    counter = (await ethers.getContractAt(
      "Counter",
      counterD.address
    )) as Counter;

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

  it("Only owner can whitelist and remove task", async () => {
    const selector = counter.interface.getSighash("increaseCount");
    const target = counter.address;
    const encode = ethers.utils.defaultAbiCoder.encode(
      ["address[]", "bytes4[]"],
      [[target], [selector]]
    );

    const task = ethers.utils.keccak256(encode);

    await expect(
      furuGelato.connect(user0).whitelistTask([target], [selector])
    ).to.be.revertedWith("Ownable: caller is not the owner");

    await furuGelato.connect(owner).whitelistTask([target], [selector]);
    expect(await furuGelato.getWhitelistedTasks()).to.include(task);

    await furuGelato.connect(owner).removeTask(task);
    expect(await furuGelato.getWhitelistedTasks()).to.not.include(task);

    await furuGelato.connect(owner).whitelistTask([target], [selector]);
  });

  it("check create and cancel task", async () => {
    const execData = counter.interface.encodeFunctionData("increaseCount", [5]);
    const target = counter.address;
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
      .withArgs(dsProxy.address, [counter.address], [execData], expectedTask);

    await expect(
      dsProxy.connect(user0).execute(taskHandler.address, dsCancelTask)
    )
      .to.emit(furuGelato, "TaskCancelled")
      .withArgs(dsProxy.address, [counter.address], [execData], expectedTask);

    await dsProxy.connect(user0).execute(taskHandler.address, dsCreateTask);
  });

  it("exec when condition passes ", async () => {
    expect(await counter.count()).to.be.eql(ethers.BigNumber.from("0"));

    const execData = counter.interface.encodeFunctionData("increaseCount", [5]);
    const target = counter.address;
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
