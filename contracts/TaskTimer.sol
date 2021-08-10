// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Resolver} from "./Resolver.sol";
import {DSProxyTask} from "./DSProxyTask.sol";

contract TaskTimer is Resolver, DSProxyTask, Ownable {
    mapping(bytes32 => uint256) public lastExecTimes;

    address public immutable furuGelato;
    address public immutable aFurucombo;
    address public immutable aTrevi;
    uint256 public period;

    bytes4 private constant _HARVEST_SIG =
        bytes4(
            keccak256(
                bytes("harvestAngelsAndCharge(address,address[],address[])")
            )
        );
    bytes4 private constant _EXEC_SIG =
        bytes4(
            keccak256(
                bytes(
                    "injectAndBatchExec(address[],uint256[],address[],address[],bytes32[],bytes[])"
                )
            )
        );
    bytes4 private constant _DEPOSIT_SIG =
        bytes4(keccak256(bytes("deposit(address,uint256)")));

    event PeriodSet(uint256 period);

    modifier onlyFuruGelato() {
        require(msg.sender == furuGelato, "not FuruGelato");
        _;
    }

    constructor(
        address _action,
        address _furuGelato,
        address _aFurucombo,
        address _aTrevi,
        uint256 _period
    ) Resolver(_action) {
        furuGelato = _furuGelato;
        aFurucombo = _aFurucombo;
        aTrevi = _aTrevi;
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
