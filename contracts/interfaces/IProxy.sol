// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IProxy {
    function batchExec(
        address[] calldata tos,
        bytes32[] calldata configs,
        bytes[] calldata datas
    ) external payable;
}
