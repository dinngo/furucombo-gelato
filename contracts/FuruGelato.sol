// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {Gelatofied} from "./Gelatofied.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IDSProxy} from "./interfaces/IDSProxy.sol";
import {IProxy} from "./interfaces/IProxy.sol";

contract FuruGelato is Ownable, Gelatofied {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public immutable furuProxy;
    mapping(bytes32 => address) public callerOfTask;
    EnumerableSet.AddressSet internal _whitelistedResolvers;

    event TaskCreated(address caller, address resolver, bytes taskData);
    event TaskCancelled(address caller, address resolver, bytes taskData);

    constructor(address payable _gelato, address _furuProxy)
        Gelatofied(_gelato)
    {
        furuProxy = _furuProxy;
    }

    receive() external payable {}

    function createTask(
        address _proxy,
        address _resolver,
        bytes calldata _taskData
    ) external {
        require(_whitelistedResolvers.contains(_resolver));

        bytes32 _task = keccak256(abi.encode(_proxy, _resolver, _taskData));
        require(
            callerOfTask[_task] == address(0),
            "FuruGelato: createTask: Sender already started task"
        );

        callerOfTask[_task] = _proxy;

        emit TaskCreated(_proxy, _resolver, _taskData);
    }

    function cancelTask(address _resolver, bytes calldata _taskData) external {
        bytes32 _task = keccak256(abi.encode(msg.sender, _resolver, _taskData));

        require(
            callerOfTask[_task] != address(0),
            "FuruGelato: cancelTask: Sender did not start task yet"
        );

        delete callerOfTask[_task];

        emit TaskCancelled(msg.sender, _resolver, _taskData);
    }

    function dsProxyExecute(bytes calldata _execData) public {
        (bool success, ) = furuProxy.call(_execData);

        require(success, "FuruGelato: exec: Exec failed");
    }

    function exec(
        uint256 _fee,
        address _proxy,
        address _resolver,
        bytes calldata _taskData,
        bytes calldata _execData
    ) external gelatofy(_fee, ETH) {
        bytes32 _task = keccak256(abi.encode(_proxy, _resolver, _taskData));

        require(
            _proxy == callerOfTask[_task],
            "FuruGelato: exec: No task found"
        );

        bytes memory dsData =
            abi.encodeWithSelector(this.dsProxyExecute.selector, _execData);

        address target = address(this);

        IDSProxy(_proxy).execute(target, dsData);
    }

    function whitelistResolver(address _resolver) external onlyOwner {
        require(
            !_whitelistedResolvers.contains(_resolver),
            "FuruGelato: whitelistResolver: Resolver already whitelisted"
        );

        _whitelistedResolvers.add(_resolver);
    }

    function removeResolverFromWhitelist(address _resolver) external onlyOwner {
        require(
            _whitelistedResolvers.contains(_resolver),
            "FuruGelato: whitelistResolver: Resolver not whitelisted"
        );

        _whitelistedResolvers.remove(_resolver);
    }

    function withdrawFunds(uint256 _amount) external onlyOwner {
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "FuruGelato: withdrawFunds: Withdraw funds failed");
    }

    function getWhitelistedResolvers()
        external
        view
        returns (address[] memory _resolvers)
    {
        uint256 length = _whitelistedResolvers.length();
        _resolvers = new address[](length);
        for (uint256 i = 0; i < length; i++)
            _resolvers[i] = _whitelistedResolvers.at(i);
    }
}
