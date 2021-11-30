// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IDSProxy} from "../interfaces/IDSProxy.sol";
import {
    IFuruGelato,
    ITaskBlacklist,
    IDSProxyBlacklist
} from "../interfaces/IFuruGelato.sol";
import {DSProxyTask} from "../DSProxyTask.sol";
import {Resolver} from "../resolver/Resolver.sol";
import {Gelatofied} from "../Gelatofied.sol";

contract FuruGelatoMock is
    IFuruGelato,
    ITaskBlacklist,
    IDSProxyBlacklist,
    Gelatofied,
    DSProxyTask
{
    bool private _fDSProxy;
    bool private _fTask;

    constructor(address payable _gelato) Gelatofied(_gelato) {
        _fDSProxy = true;
        _fTask = true;
    }

    function createTask(address _resolverAddress, bytes calldata _resolverData)
        external
        override
    {
        (, bytes memory executionData) =
            Resolver(_resolverAddress).checker(msg.sender, _resolverData);
        bytes32 taskId = getTaskId(msg.sender, _resolverAddress, executionData);

        // Call resolver's `onCreateTask()`
        require(
            Resolver(_resolverAddress).onCreateTask(msg.sender, executionData),
            "FuruGelato: createTask: onCreateTask() failed"
        );

        emit TaskCreated(msg.sender, taskId, _resolverAddress, executionData);
    }

    function cancelTask(address _resolverAddress, bytes calldata _executionData)
        external
        override
    {
        bytes32 taskId =
            getTaskId(msg.sender, _resolverAddress, _executionData);

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

    function exec(
        uint256 _fee,
        address _proxy,
        address _resolverAddress,
        bytes calldata _executionData
    ) external override gelatofy(_fee, ETH) {
        bytes32 taskId = getTaskId(_proxy, _resolverAddress, _executionData);
        // Fetch the action to be used in dsproxy's `execute()`.
        address action = Resolver(_resolverAddress).action();

        try IDSProxy(_proxy).execute(action, _executionData) {} catch {
            revert("FuruGelato: exec: execute failed");
        }

        require(
            Resolver(_resolverAddress).onExec(_proxy, _executionData),
            "FuruGelato: exec: onExec() failed"
        );

        emit ExecSuccess(_fee, ETH, _proxy, taskId);
    }

    function getTaskIdsByUser(address)
        external
        view
        override
        returns (bytes32[] memory)
    {
        this;
        bytes32[] memory taskIds = new bytes32[](0);
        return taskIds;
    }

    function withdrawFunds(uint256, address payable) external pure override {
        return;
    }

    function banDSProxy(address) external override {
        _fDSProxy = false;
    }

    function unbanDSProxy(address) external override {
        _fDSProxy = true;
    }

    function isValidDSProxy(address) external view override returns (bool) {
        return _fDSProxy;
    }

    function banTask(bytes32) external override {
        _fTask = false;
    }

    function unbanTask(bytes32) external override {
        _fTask = true;
    }

    function isValidTask(bytes32) external view override returns (bool) {
        return _fTask;
    }
}
