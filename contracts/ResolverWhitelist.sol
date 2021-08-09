// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ResolverWhitelist is Ownable {
    mapping(address => bool) private _whitelistedResolvers;

    event ResolverWhitelistAdded(address resolverAddress);
    event ResolverWhitelistRemoved(address resolverAddress);

    modifier onlyValidResolver(address _resolverAddress) {
        require(isValidResolver(_resolverAddress), "Invalid resolver");
        _;
    }

    function registerResolver(address _resolverAddress) external onlyOwner {
        _whitelistedResolvers[_resolverAddress] = true;

        emit ResolverWhitelistAdded(_resolverAddress);
    }

    function unregisterResolver(address _resolverAddress)
        external
        onlyOwner
        onlyValidResolver(_resolverAddress)
    {
        _whitelistedResolvers[_resolverAddress] = false;

        emit ResolverWhitelistRemoved(_resolverAddress);
    }

    function isValidResolver(address _resolverAddress)
        public
        view
        returns (bool)
    {
        return _whitelistedResolvers[_resolverAddress];
    }
}
