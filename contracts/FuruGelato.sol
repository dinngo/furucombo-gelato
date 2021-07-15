// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IGelato} from "./interfaces/IGelato.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract FuruGelato is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    uint256 public txFee;
    IGelato public immutable gelato;
    address public immutable proxy;
    mapping(bytes32 => address) public calleeOfTask;
    EnumerableSet.AddressSet internal _whitelistedResolvers;

    event TaskCreated(address resolver, bytes taskData);

    constructor(
        uint256 _txFee,
        address _gelato,
        address _proxy
    ) public {
        txFee = _txFee;
        gelato = IGelato(_gelato);
        proxy = _proxy;
    }

    receive() external payable {}

    function createTask(address _resolver, bytes calldata _taskData) external {
        require(_whitelistedResolvers.contains(_resolver));

        bytes32 _task = keccak256(abi.encode(_resolver, _taskData));

        require(
            calleeOfTask[_task] == address(0),
            "FuruGelato: createTask: Sender already started task"
        );

        calleeOfTask[_task] = msg.sender;

        emit TaskCreated(_resolver, _taskData);
    }

    function cancelTask(address _resolver, bytes calldata _taskData) external {
        bytes32 _task = keccak256(abi.encode(_resolver, _taskData));

        require(
            calleeOfTask[_task] != address(0),
            "FuruGelato: cancelTask: Sender did not start task yet"
        );

        delete calleeOfTask[_task];
    }

    function exec(
        address _resolver,
        bytes calldata _taskData,
        bytes calldata _execData
    ) external {
        require(
            gelato.isExecutor(msg.sender),
            "FuruGelato: exec: Only executors"
        );

        bytes32 _task = keccak256(abi.encode(_resolver, _taskData));

        address _callee = calleeOfTask[_task];
        require(_callee != address(0), "FuruGelato: cancelTask: No task found");

        proxy.call(_execData);

        (bool success, ) = msg.sender.call{value: txFee}("");
        require(success, "FuruGelato: exec: Transfer to executor failed");
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
