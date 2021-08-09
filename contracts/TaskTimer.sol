// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Resolver} from "./Resolver.sol";
import {FuruGelato} from "./FuruGelato.sol";
import {DSProxyTask} from "./DSProxyTask.sol";

contract TaskTimer is Resolver, DSProxyTask, Ownable {
    mapping(bytes32 => uint256) public lastExecTimes;

    address public immutable furuGelato;
    uint256 public period;

    event PeriodSet(uint256 period);

    modifier onlyFuruGelato() {
        require(msg.sender == furuGelato, "not FuruGelato");
        _;
    }

    constructor(
        address _action,
        address _furuGelato,
        uint256 _period
    ) Resolver(_action) {
        furuGelato = _furuGelato;
        period = _period;
    }

    function checker(address _taskCreator, bytes calldata _resolverData)
        external
        view
        override
        returns (bool, bytes memory)
    {
        // Verify if _resolverData is valid
        require(_isValidResolverData(_resolverData[4:]), "Data not valid");

        bytes32 task = getTaskId(_taskCreator, address(this), _resolverData);
        return (_isReady(task), _resolverData);
    }

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

    function onExec(address _taskExecutor, bytes calldata _executionData)
        external
        override
        onlyFuruGelato
        returns (bool)
    {
        bytes32 taskId =
            getTaskId(_taskExecutor, address(this), _executionData);
        _reset(taskId);

        return true;
    }

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
        this;
        (address[] memory tos, bytes32[] memory configs, bytes[] memory datas) =
            abi.decode(data, (address[], bytes32[], bytes[]));
        tos;
        configs;
        datas;

        return true;
    }
}
