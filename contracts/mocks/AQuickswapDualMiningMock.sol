// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract AQuickswapDualMiningMock {
    uint256 public count;

    constructor() {
        count = 0;
    }

    function stake(address, uint256) external {
        count++;
    }

    function getRewardAndCharge(address) external returns (uint256, uint256) {
        count++;
        return (count, count);
    }

    function getReward(address) external returns (uint256, uint256) {
        count++;
        return (count, count);
    }

    function dQuickLeave(uint256) external returns (uint256) {
        count++;
        return count;
    }

    function exit(address)
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        count++;
        return (count, count, count);
    }
}
