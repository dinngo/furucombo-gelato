// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import {Gelatofied} from "./Gelatofied.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract FuruGelato is Ownable, Gelatofied {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public immutable proxy;
    mapping(bytes32 => address) public callerOfTask;
    EnumerableSet.AddressSet internal _whitelistedResolvers;

    event TaskCreated(address callee, address resolver, bytes taskData);
    event TaskCancelled(address callee, address resolver, bytes taskData);

    constructor(address payable _gelato, address _proxy)
        public
        Gelatofied(_gelato)
    {
        proxy = _proxy;
    }

    receive() external payable {}

    function createTask(address _resolver, bytes calldata _taskData) external {
        require(_whitelistedResolvers.contains(_resolver));

        bytes32 _task = keccak256(abi.encode(msg.sender, _resolver, _taskData));

        require(
            callerOfTask[_task] == address(0),
            "FuruGelato: createTask: Sender already started task"
        );

        callerOfTask[_task] = msg.sender;

        emit TaskCreated(msg.sender, _resolver, _taskData);
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

    function exec(
        uint256 _fee,
        address _caller,
        address _resolver,
        bytes calldata _taskData,
        bytes calldata _execData
    ) external gelatofy(_fee, ETH) {
        bytes32 _task = keccak256(abi.encode(_caller, _resolver, _taskData));

        require(
            _caller == callerOfTask[_task],
            "FuruGelato: exec: No task found"
        );

        (bool success, ) = proxy.call(_execData);
        require(success, "FuruGelato: exec: Exec failed");
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
