// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TaskBlacklist is Ownable {
    /// @notice The blacklist of the tasks.
    mapping(bytes32 => bool) private _blacklistedTasks;

    event TaskBlacklistAdded(bytes32 taskId);
    event TaskBlacklistRemoved(bytes32 taskId);

    modifier onlyValidTask(bytes32 _taskId) {
        require(isValidTask(_taskId), "Invalid task");
        _;
    }

    /// @notice Ban the task from being able to be executed.
    /// @param _taskId The task to be banned.
    function banTask(bytes32 _taskId) external onlyOwner {
        _blacklistedTasks[_taskId] = true;

        emit TaskBlacklistAdded(_taskId);
    }

    /// @notice Unban the task.
    /// @param _taskId The task to be unbanned.
    function unbanTask(bytes32 _taskId) external onlyOwner {
        require(!isValidTask(_taskId), "Not banned");
        _blacklistedTasks[_taskId] = false;

        emit TaskBlacklistRemoved(_taskId);
    }

    /// @notice Return if the task is valid.
    /// @param _taskId The task to be queried.
    function isValidTask(bytes32 _taskId) public view returns (bool) {
        return (!_blacklistedTasks[_taskId]);
    }
}
