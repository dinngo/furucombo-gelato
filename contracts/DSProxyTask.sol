// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract DSProxyTask {
    function getTaskId(
        address _dsProxy,
        address _resolverAddress,
        bytes memory _resolverData
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_dsProxy, _resolverAddress, _resolverData));
    }
}
