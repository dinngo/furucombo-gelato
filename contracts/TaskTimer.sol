// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

import {Resolver} from "./Resolver.sol";
import {FuruGelato} from "./FuruGelato.sol";
import {DSProxyTask} from "./DSProxyTask.sol";

contract TaskTimer is Resolver, DSProxyTask {
    mapping(bytes32 => uint256) public lastExecTimes;

    address public immutable furuGelato;
    uint256 public immutable period;

    modifier onlyFuruGelato() {
        require(msg.sender == furuGelato, "not FuruGelato");
        _;
    }

    constructor(
        address _actions,
        address _furuGelato,
        uint256 _period
    ) Resolver(_actions) {
        furuGelato = _furuGelato;
        period = _period;
    }

    function checker(address _taskCreator, bytes calldata _resolverData)
        external
        view
        override
        returns (bool, bytes memory)
    {
        bytes32 task = getTaskId(_taskCreator, address(this), _resolverData);
        return (_isReady(task), _resolverData);
    }

    function onCreateTask(address _executor, bytes calldata _resolverData)
        external
        override
        onlyFuruGelato
        returns (bool)
    {
        bytes32 task = getTaskId(_executor, address(this), _resolverData);
        lastExecTimes[task] = block.timestamp;

        return true;
    }

    function onExec(address _executor, bytes calldata _resolverData)
        external
        override
        onlyFuruGelato
        returns (bool)
    {
        bytes32 task = getTaskId(_executor, address(this), _resolverData);
        _reset(task);

        return true;
    }

    function _reset(bytes32 taskId) internal {
        require(_isReady(taskId), "Not yet");
        lastExecTimes[taskId] = block.timestamp;
    }

    function _isReady(bytes32 task) internal view returns (bool) {
        return block.timestamp >= lastExecTimes[task] + period ? true : false;
    }
}
