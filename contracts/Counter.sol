// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

contract Counter {
    uint256 public count;

    function increaseCount(uint256 amount) external {
        count += amount;
    }
}
