// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {Gelatofied} from "./Gelatofied.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IDSProxy} from "./interfaces/IDSProxy.sol";
import {IProxy} from "./interfaces/IProxy.sol";
import {Resolver} from "./Resolver.sol";
import {GelatoBytes} from "./GelatoBytes.sol";
import {DSProxyTask} from "./DSProxyTask.sol";

contract FuruGelato is Ownable, Gelatofied, DSProxyTask {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using GelatoBytes for bytes;

    string public constant VERSION = "0.0.1";
    mapping(bytes32 => address) public taskCreator;
    mapping(address => EnumerableSet.Bytes32Set) internal _createdTasks;

    event TaskCreated(
        address indexed taskCreator,
        bytes32 taskId,
        address indexed resolverAddress,
        bytes resolverData
    );
    event TaskCancelled(
        address indexed taskCreator,
        bytes32 taskId,
        address indexed resolverAddress,
        bytes resolverData
    );
    event ExecSuccess(
        uint256 indexed txFee,
        address indexed feeToken,
        address indexed execAddress,
        bytes32 taskId
    );

    event LogFundsDeposited(address indexed sender, uint256 amount);
    event LogFundsWithdrawn(
        address indexed sender,
        uint256 amount,
        address receiver
    );

    constructor(address payable _gelato) Gelatofied(_gelato) {}

    receive() external payable {
        emit LogFundsDeposited(msg.sender, msg.value);
    }

    function createTask(address _resolverAddress, bytes calldata _resolverData)
        external
    {
        bytes32 task = getTaskId(msg.sender, _resolverAddress, _resolverData);

        require(
            taskCreator[task] == address(0),
            "FuruGelato: createTask: Sender already started task"
        );

        _createdTasks[msg.sender].add(task);
        taskCreator[task] = msg.sender;

        require(
            Resolver(_resolverAddress).onCreateTask(msg.sender, _resolverData),
            "FuruGelato: createTask: onCreateTask() failed"
        );

        emit TaskCreated(msg.sender, task, _resolverAddress, _resolverData);
    }

    function cancelTask(address _resolverAddress, bytes calldata _resolverData)
        external
    {
        bytes32 taskId = getTaskId(msg.sender, _resolverAddress, _resolverData);

        require(
            taskCreator[taskId] == msg.sender,
            "FuruGelato: cancelTask: Sender did not start task yet"
        );

        _createdTasks[msg.sender].remove(taskId);
        delete taskCreator[taskId];

        require(
            Resolver(_resolverAddress).onCancelTask(msg.sender, _resolverData),
            "FuruGelato: cancelTask: onCancelTask() failed"
        );

        emit TaskCancelled(msg.sender, taskId, _resolverAddress, _resolverData);
    }

    function exec(
        uint256 _fee,
        address _proxy,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external gelatofy(_fee, ETH) {
        bytes32 task = getTaskId(_proxy, _resolverAddress, _resolverData);
        address actions = Resolver(_resolverAddress).action();

        (bool ok, bytes memory executeData) =
            Resolver(_resolverAddress).checker(_proxy, _resolverData);
        require(ok, "FuruGelato: exec: Checker failed");
        require(_proxy == taskCreator[task], "FuruGelato: exec: No task found");

        try IDSProxy(_proxy).execute(actions, executeData) {} catch {
            revert("FuruGelato: exec: execute failed");
        }

        require(
            Resolver(_resolverAddress).onExec(_proxy, _resolverData),
            "FuruGelato: exec: onExec() failed"
        );

        emit ExecSuccess(_fee, ETH, _proxy, task);
    }

    function withdrawFunds(uint256 _amount, address payable _receiver)
        external
        onlyOwner
    {
        (bool success, ) = _receiver.call{value: _amount}("");
        require(success, "FuruGelato: withdrawFunds: Withdraw funds failed");

        emit LogFundsWithdrawn(msg.sender, _amount, _receiver);
    }

    function getTaskIdsByUser(address _taskCreator)
        external
        view
        returns (bytes32[] memory)
    {
        uint256 length = _createdTasks[_taskCreator].length();
        bytes32[] memory taskIds = new bytes32[](length);

        for (uint256 i; i < length; i++) {
            taskIds[i] = _createdTasks[_taskCreator].at(i);
        }

        return taskIds;
    }
}
