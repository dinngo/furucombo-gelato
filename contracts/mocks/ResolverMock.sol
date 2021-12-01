// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Resolver} from "../resolvers/Resolver.sol";

contract ResolverMock is Resolver {
    constructor(address _action, address _furuGelato)
        Resolver(_action, _furuGelato)
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
