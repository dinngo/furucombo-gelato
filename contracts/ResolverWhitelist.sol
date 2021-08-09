// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ResolverWhitelist is Ownable {
    mapping(address => bool) private _whitelistedResolvers;

    event ResolverWhitelistAdded(address resolverAddress);
    event ResolverWhitelistRemoved(address resolverAddress);

    modifier isValidResolver(address _resolver) {
        require(_whitelistedResolvers[_resolver], "Invalid resolver");
        _;
    }

    /// Resolver related
    function registerResolver(address _resolverAddress) external onlyOwner {
        _whitelistedResolvers[_resolverAddress] = true;

        emit ResolverWhitelistAdded(_resolverAddress);
    }

    function unregisterResolver(address _resolverAddress) external onlyOwner {
        require(
            _whitelistedResolvers[_resolverAddress],
            "Resolver not registered"
        );
        _whitelistedResolvers[_resolverAddress] = false;

        emit ResolverWhitelistRemoved(_resolverAddress);
    }
}
