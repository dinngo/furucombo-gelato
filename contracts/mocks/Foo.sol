// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Foo {
    bool public ok = false;

    function bar() external returns (bool) {
        ok = true;
        return ok;
    }
}
