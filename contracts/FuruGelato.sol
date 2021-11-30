// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDSProxy} from "./interfaces/IDSProxy.sol";
import {IFuruGelato} from "./interfaces/IFuruGelato.sol";
import {DSProxyBlacklist} from "./DSProxyBlacklist.sol";
import {DSProxyTask} from "./DSProxyTask.sol";
import {Gelatofied} from "./Gelatofied.sol";
import {Resolver} from "./resolver/Resolver.sol";
import {ResolverWhitelist} from "./ResolverWhitelist.sol";
import {TaskBlacklist} from "./TaskBlacklist.sol";

/// @title The task manager
contract FuruGelato is
    IFuruGelato,
    Ownable,
    Gelatofied,
    DSProxyTask,
    ResolverWhitelist,
    DSProxyBlacklist,
    TaskBlacklist
{
    using EnumerableSet for EnumerableSet.Bytes32Set;

    string public constant VERSION = "0.0.1";
    /// @notice The creator of the task
    mapping(bytes32 => address) public taskCreator;
    /// @notice The total task list created by user
    mapping(address => EnumerableSet.Bytes32Set) internal _createdTasks;

    constructor(address payable _gelato) Gelatofied(_gelato) {}

    receive() external payable {
        emit LogFundsDeposited(msg.sender, msg.value);
    }

    // Task related
    /// @notice Create the task through the given resolver. The resolver should
    /// be validated through a whitelist.
    /// @param _resolverAddress The resolver to generate the task execution
    /// data.
    /// @param _resolverData The data to be provided to the resolver for data
    /// generation.
    function createTask(address _resolverAddress, bytes calldata _resolverData)
        external
        override
        onlyValidResolver(_resolverAddress)
        onlyValidDSProxy(msg.sender)
    {
        // The _resolverData is passed to the resolver to generate the
        // execution data for the task.
        (, bytes memory executionData) =
            Resolver(_resolverAddress).checker(msg.sender, _resolverData);
        bytes32 taskId = getTaskId(msg.sender, _resolverAddress, executionData);
        require(
            taskCreator[taskId] == address(0),
            "FuruGelato: createTask: Sender already started task"
        );
        _createdTasks[msg.sender].add(taskId);
        taskCreator[taskId] = msg.sender;

        // Call resolver's `onCreateTask()`
        require(
            Resolver(_resolverAddress).onCreateTask(msg.sender, executionData),
            "FuruGelato: createTask: onCreateTask() failed"
        );

        emit TaskCreated(msg.sender, taskId, _resolverAddress, executionData);
    }

    /// @notice Cancel the task that was created through the given resolver.
    /// @param _resolverAddress The resolver that created the task.
    /// @param _executionData The task data to be canceled.
    function cancelTask(address _resolverAddress, bytes calldata _executionData)
        external
        override
    {
        bytes32 taskId =
            getTaskId(msg.sender, _resolverAddress, _executionData);

        require(
            taskCreator[taskId] == msg.sender,
            "FuruGelato: cancelTask: Sender did not start task yet"
        );

        _createdTasks[msg.sender].remove(taskId);
        delete taskCreator[taskId];

        require(
            Resolver(_resolverAddress).onCancelTask(msg.sender, _executionData),
            "FuruGelato: cancelTask: onCancelTask() failed"
        );

        emit TaskCancelled(
            msg.sender,
            taskId,
            _resolverAddress,
            _executionData
        );
    }

    /// @notice Execute the task created by `_proxy`through the given resolver.
    /// The resolver should be validated through a whitelist.
    /// @param _fee The fee to be paid to `gelato`
    /// @param _resolverAddress The resolver that created the task.
    /// @param _executionData The execution payload.
    function exec(
        uint256 _fee,
        address _proxy,
        address _resolverAddress,
        bytes calldata _executionData
    )
        external
        override
        gelatofy(_fee, ETH)
        onlyValidResolver(_resolverAddress)
        onlyValidDSProxy(_proxy)
    {
        bytes32 taskId = getTaskId(_proxy, _resolverAddress, _executionData);
        require(isValidTask(taskId), "FuruGelato: exec: invalid task");
        // Fetch the action to be used in dsproxy's `execute()`.
        address action = Resolver(_resolverAddress).action();

        require(
            _proxy == taskCreator[taskId],
            "FuruGelato: exec: No task found"
        );

        try IDSProxy(_proxy).execute(action, _executionData) {} catch {
            revert("FuruGelato: exec: execute failed");
        }

        require(
            Resolver(_resolverAddress).onExec(_proxy, _executionData),
            "FuruGelato: exec: onExec() failed"
        );

        emit ExecSuccess(_fee, ETH, _proxy, taskId);
    }

    /// @notice Return the tasks created by the user.
    /// @param _taskCreator The user to be queried.
    /// @return The task list.
    function getTaskIdsByUser(address _taskCreator)
        external
        view
        override
        returns (bytes32[] memory)
    {
        uint256 length = _createdTasks[_taskCreator].length();
        bytes32[] memory taskIds = new bytes32[](length);

        for (uint256 i; i < length; i++) {
            taskIds[i] = _createdTasks[_taskCreator].at(i);
        }

        return taskIds;
    }

    // Funds related
    /// @notice Withdraw the deposited funds that is used for paying fee.
    /// @param _amount The amount to be withdrawn.
    /// @param _receiver The address to be withdrawn to.
    function withdrawFunds(uint256 _amount, address payable _receiver)
        external
        override
        onlyOwner
    {
        (bool success, ) = _receiver.call{value: _amount}("");
        require(success, "FuruGelato: withdrawFunds: Withdraw funds failed");

        emit LogFundsWithdrawn(msg.sender, _amount, _receiver);
    }
}
