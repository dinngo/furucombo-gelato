// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract DSProxyTask {
    /// @notice Return the id of the task.
    /// @param _dsProxy The creator of the task.
    /// @param _resolverAddress The resolver of the task.
    /// @param _executionData The execution data of the task.
    /// @return The task id.
    function getTaskId(
        address _dsProxy,
        address _resolverAddress,
        bytes memory _executionData
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encode(_dsProxy, _resolverAddress, _executionData));
    }
}
