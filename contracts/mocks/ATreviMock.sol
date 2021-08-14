// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract ATreviMock {
    uint256 public count;

    constructor() {
        count = 0;
    }

    function harvestAngelsAndCharge(
        address,
        address[] calldata,
        address[] calldata
    ) external returns (bool) {
        count++;
        return true;
    }

    function deposit(address, uint256) external returns (bool) {
        count++;
        return true;
    }
}
