// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFuruGelato {
    function createTask(address _resolverAddress, bytes calldata _resolverData)
        external;

    function cancelTask(address _resolverAddress, bytes calldata _resolverData)
        external;

    function exec(
        uint256 _fee,
        address _proxy,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external;
}
