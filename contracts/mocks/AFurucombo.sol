pragma solidity ^0.8.0;

contract AFurucomboMock {
    uint256 public count;

    constructor() {
        count = 0;
    }

    function injectAndBatchExec(
        address[] calldata,
        uint256[] calldata,
        address[] calldata,
        address[] calldata,
        bytes32[] calldata,
        bytes[] calldata
    ) external returns (bool) {
        count++;
        return true;
    }
}
