// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract FAction {
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
    function batchExec(address[] memory _targets, bytes[] memory _datas)
        external
        onlyDelegatecall
    {
        for (uint256 i; i < _targets.length; i++) {
            (bool success, ) = _targets[i].call(_datas[i]);
            require(success, "FuruGelato: batchExec: Delegatecall failed");
        }
    }
}
