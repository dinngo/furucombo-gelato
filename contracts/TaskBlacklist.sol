// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TaskBlacklist is Ownable {
    mapping(bytes32 => bool) private _blacklistedTasks;

    event TaskBlacklistAdded(bytes32 taskId);
    event TaskBlacklistRemoved(bytes32 taskId);

    modifier onlyValidTask(bytes32 _taskId) {
        require(isValidTask(_taskId), "Invalid task");
        _;
    }

    function banTask(bytes32 _taskId) external onlyOwner {
        _blacklistedTasks[_taskId] = true;

        emit TaskBlacklistAdded(_taskId);
    }

    function unbanTask(bytes32 _taskId) external onlyOwner {
        require(!isValidTask(_taskId), "Not banned");
        _blacklistedTasks[_taskId] = false;

        emit TaskBlacklistRemoved(_taskId);
    }

    function isValidTask(bytes32 _taskId) public view returns (bool) {
        return (!_blacklistedTasks[_taskId]);
    }
}
