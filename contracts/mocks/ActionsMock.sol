// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract ActionsMock {
    address public immutable THIS;

    modifier onlyDelegatecall() {
        require(
            THIS != address(this),
            "FuruGelato: batchExec: Only delegatecall"
        );
        _;
    }

    constructor() {
        THIS = address(this);
    }

    /// @notice Delegatecalled by User Proxies
    function multiCall(address[] memory _targets, bytes[] memory _datas)
        external
        onlyDelegatecall
    {
        for (uint256 i; i < _targets.length; i++) {
            (bool success, ) = _targets[i].call(_datas[i]);
            require(success, "Call failed");
        }
    }
}
