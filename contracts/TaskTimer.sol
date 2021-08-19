// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ITaskBlacklist, IDSProxyBlacklist} from "./interfaces/IFuruGelato.sol";
import {DSProxyTask} from "./DSProxyTask.sol";
import {Resolver} from "./Resolver.sol";

/// @title Task timer is a implementation of resolver for generating tasks
/// that can be executed repeatedly after a specific time period.
contract TaskTimer is Resolver, DSProxyTask, Ownable {
    /// @notice The last execution time of the task.
    mapping(bytes32 => uint256) public lastExecTimes;

    address public immutable aFurucombo;
    address public immutable aTrevi;
    uint256 public period;

    // solhint-disable
    // prettier-ignore
    bytes4 private constant _HARVEST_SIG =
        bytes4(keccak256(bytes("harvestAngelsAndCharge(address,address[],address[])")));
    // prettier-ignore
    bytes4 private constant _EXEC_SIG =
        bytes4(keccak256(bytes("injectAndBatchExec(address[],uint256[],address[],address[],bytes32[],bytes[])")));
    // prettier-ignore
    bytes4 private constant _DEPOSIT_SIG =
        bytes4(keccak256(bytes("deposit(address,uint256)")));
    // solhint-enable

    event PeriodSet(uint256 period);

    constructor(
        address _action,
        address _furuGelato,
        address _aFurucombo,
        address _aTrevi,
        uint256 _period
    ) Resolver(_action, _furuGelato) {
        aFurucombo = _aFurucombo;
        aTrevi = _aTrevi;
        period = _period;
    }

    /// @notice Checker can generate the execution payload for the given data
    /// that is available for an user, and also examines if the task can be
    /// executed.
    /// @param _taskCreator The creator of the task.
    /// @param _resolverData The data for resolver to generate the task.
    /// Currently identical to the execution data of DSProxy.
    /// @return If the task can be executed.
    /// @return The generated execution data for the given `_resolverData`.
    function checker(address _taskCreator, bytes calldata _resolverData)
        external
        view
        override
        returns (bool, bytes memory)
    {
        // Verify if _taskCreator is valid
        require(
            IDSProxyBlacklist(furuGelato).isValidDSProxy(_taskCreator),
            "Creator not valid"
        );
        // Verify if _resolverData is valid
        require(_isValidResolverData(_resolverData[4:]), "Data not valid");

        // Use `_resolverData` to generate task Id since that exection data
        // is resolver data in TaskTimee's implementation.
        bytes32 task = getTaskId(_taskCreator, address(this), _resolverData);
        // Verify if the task is valid
        require(ITaskBlacklist(furuGelato).isValidTask(task), "Task not valid");
        return (_isReady(task), _resolverData);
    }

    /// @notice Update the last execution time to now when a task is created.
    /// @param _taskCreator The creator of the task.
    /// @param _executionData The execution data of the task.
    function onCreateTask(address _taskCreator, bytes calldata _executionData)
        external
        override
        onlyFuruGelato
        returns (bool)
    {
        bytes32 task = getTaskId(_taskCreator, address(this), _executionData);
        lastExecTimes[task] = block.timestamp;

        return true;
    }

    /// @notice Delete the last execution time to now when a task is canceled.
    /// @param _taskCreator The creator of the task.
    /// @param _executionData The execution data of the task.
    function onCancelTask(address _taskCreator, bytes calldata _executionData)
        external
        override
        onlyFuruGelato
        returns (bool)
    {
        bytes32 taskId = getTaskId(_taskCreator, address(this), _executionData);
        delete lastExecTimes[taskId];

        return true;
    }

    /// @notice Update the last execution time to now when a task is executed.
    /// @param _taskCreator The creator of the task.
    /// @param _executionData The execution data of the task.
    function onExec(address _taskCreator, bytes calldata _executionData)
        external
        override
        onlyFuruGelato
        returns (bool)
    {
        bytes32 taskId = getTaskId(_taskCreator, address(this), _executionData);
        _reset(taskId);

        return true;
    }

    /// @notice Set the new time period for task execution.
    /// @param _period The new time period.
    function setPeriod(uint256 _period) external onlyOwner {
        period = _period;

        emit PeriodSet(_period);
    }

    function _reset(bytes32 taskId) internal {
        require(_isReady(taskId), "Not yet");
        lastExecTimes[taskId] = block.timestamp;
    }

    function _isReady(bytes32 taskId) internal view returns (bool) {
        if (lastExecTimes[taskId] == 0) {
            return false;
        } else if (block.timestamp < lastExecTimes[taskId] + period) {
            return false;
        } else {
            return true;
        }
    }

    function _isValidResolverData(bytes memory data)
        internal
        view
        returns (bool)
    {
        (address[] memory tos, , bytes[] memory datas) =
            abi.decode(data, (address[], bytes32[], bytes[]));
        require(tos.length == 3, "Invalid tos length");
        require(tos[0] == aTrevi, "Invalid tos[0]");
        require(tos[1] == aFurucombo, "Invalid tos[1]");
        require(tos[2] == aTrevi, "Invalid tos[2]");
        require(bytes4(datas[0]) == _HARVEST_SIG, "Invalid datas[0]");
        require(bytes4(datas[1]) == _EXEC_SIG, "Invalid datas[1]");
        require(bytes4(datas[2]) == _DEPOSIT_SIG, "Invalid datas[2]");

        return true;
    }
}
