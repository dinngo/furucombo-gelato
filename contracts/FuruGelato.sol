// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {Gelatofied} from "./Gelatofied.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IDSProxy} from "./interfaces/IDSProxy.sol";
import {IProxy} from "./interfaces/IProxy.sol";
import {GelatoBytes} from "./GelatoBytes.sol";

contract FuruGelato is Ownable, Gelatofied {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using GelatoBytes for bytes;

    string public constant VERSION = "0.0.1";
    address public immutable THIS;
    address public furuProxy;
    mapping(bytes32 => address) public callerOfTask;
    EnumerableSet.Bytes32Set internal _whitelistedTasks;

    event TaskCreated(
        address caller,
        address[] targets,
        bytes[] taskDatas,
        bytes32 _hash
    );
    event TaskCancelled(
        address caller,
        address[] targets,
        bytes[] taskDatas,
        bytes32 _hash
    );

    constructor(address payable _gelato, address _furuProxy)
        Gelatofied(_gelato)
    {
        furuProxy = _furuProxy;
        THIS = address(this);
    }

    receive() external payable {}

    function createTask(
        address[] calldata _targets,
        bytes[] calldata _execDatas
    ) external {
        require(
            verifyHash(getHash(_targets, _execDatas)),
            "FuruGelato: createTask: Task not whitelisted"
        );

        bytes32 task = keccak256(abi.encode(msg.sender, _targets, _execDatas));
        require(
            callerOfTask[task] == address(0),
            "FuruGelato: createTask: Sender already started task"
        );

        callerOfTask[task] = msg.sender;

        emit TaskCreated(msg.sender, _targets, _execDatas, task);
    }

    function cancelTask(
        address[] calldata _targets,
        bytes[] calldata _execDatas
    ) external {
        bytes32 task = keccak256(abi.encode(msg.sender, _targets, _execDatas));

        require(
            callerOfTask[task] != address(0),
            "FuruGelato: cancelTask: Sender did not start task yet"
        );

        delete callerOfTask[task];

        emit TaskCancelled(msg.sender, _targets, _execDatas, task);
    }

    function exec(
        uint256 _fee,
        address _proxy,
        address[] calldata _targets,
        bytes[] calldata _execDatas
    ) external gelatofy(_fee, ETH) {
        bytes32 task = keccak256(abi.encode(_proxy, _targets, _execDatas));

        require(
            _proxy == callerOfTask[task],
            "FuruGelato: exec: No task found"
        );

        bytes memory execData =
            abi.encodeWithSelector(
                this.batchExec.selector,
                _targets,
                _execDatas
            );

        IDSProxy(_proxy).execute(address(this), execData);
    }

    /// @notice Delegatecalled by User Proxies
    function batchExec(address[] memory _targets, bytes[] memory _datas)
        external
    {
        require(
            THIS != address(this),
            "FuruGelato: batchExec: Only delegatecall"
        );

        for (uint256 i; i < _targets.length; i++) {
            (bool success, ) = _targets[i].delegatecall(_datas[i]);
            require(success, "FuruGelato: batchExec: Delegatecall failed");
        }
    }

    function whitelistTask(
        address[] memory _targets,
        bytes4[] memory _selectors
    ) external onlyOwner {
        bytes32 taskHash = keccak256(abi.encode(_targets, _selectors));
        _whitelistedTasks.add(taskHash);
    }

    function removeTask(bytes32 _taskHash) external onlyOwner {
        require(
            _whitelistedTasks.contains(_taskHash),
            "FuruGelato: whitelistResolver: Task not whitelisted"
        );

        _whitelistedTasks.remove(_taskHash);
    }

    function withdrawFunds(uint256 _amount, address payable _receiver)
        external
        onlyOwner
    {
        (bool success, ) = _receiver.call{value: _amount}("");
        require(success, "FuruGelato: withdrawFunds: Withdraw funds failed");
    }

    function updateFuruProxy(address _newFuruProxy) external onlyOwner {
        require(
            _newFuruProxy != address(0),
            "FuruGelato: updateFurucomboProxy: Address Zero"
        );

        furuProxy = _newFuruProxy;
    }

    function getWhitelistedResolvers()
        external
        view
        returns (bytes32[] memory _tasks)
    {
        uint256 length = _whitelistedTasks.length();
        _tasks = new bytes32[](length);
        for (uint256 i = 0; i < length; i++)
            _tasks[i] = _whitelistedTasks.at(i);
    }

    function verifyHash(bytes32 _hash) public view returns (bool) {
        return _whitelistedTasks.contains(_hash);
    }

    function getHash(address[] memory _targets, bytes[] memory _datas)
        public
        pure
        returns (bytes32 _hash)
    {
        require(
            _targets.length == _datas.length,
            "FuruGelato: verifyHash: Length mismatch"
        );

        bytes4[] memory selectors = getSelectors(_datas);

        _hash = keccak256(abi.encode(_targets, selectors));
    }

    function getSelectors(bytes[] memory _datas)
        public
        pure
        returns (bytes4[] memory _selectors)
    {
        for (uint256 i = 0; i < _datas.length; i++) {
            _selectors[i] = _datas[i].memorySliceSelector();
        }
    }
}
