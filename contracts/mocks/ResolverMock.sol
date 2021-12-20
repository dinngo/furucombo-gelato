// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ResolverBase} from "../resolvers/ResolverBase.sol";

contract ResolverMock is ResolverBase {
    constructor(address _action, address _furuGelato)
        ResolverBase(_action, _furuGelato)
    {}

    function checker(address, bytes calldata resolverData)
        external
        view
        override
        returns (bool, bytes memory)
    {
        this;
        return (true, resolverData);
    }
}
