// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDSProxyFactory {
    event Created(
        address indexed sender,
        address indexed owner,
        address proxy,
        address cache
    );

    function build() external returns (address proxy);
}
