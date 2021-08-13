// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ResolverWhitelist is Ownable {
    /// @notice The whitelist of valid resolvers.
    mapping(address => bool) private _whitelistedResolvers;

    event ResolverWhitelistAdded(address resolverAddress);
    event ResolverWhitelistRemoved(address resolverAddress);

    modifier onlyValidResolver(address _resolverAddress) {
        require(isValidResolver(_resolverAddress), "Invalid resolver");
        _;
    }

    /// @notice Register the resolver to the whitelist. Can only be called
    /// by owner.
    /// @param _resolverAddress The resolver to be registered.
    function registerResolver(address _resolverAddress) external onlyOwner {
        _whitelistedResolvers[_resolverAddress] = true;

        emit ResolverWhitelistAdded(_resolverAddress);
    }

    /// @notice Unregister the resolver from the whitelist. Can only be called
    /// by owner.
    /// @param _resolverAddress The resolver to be unregistered.
    function unregisterResolver(address _resolverAddress)
        external
        onlyOwner
        onlyValidResolver(_resolverAddress)
    {
        _whitelistedResolvers[_resolverAddress] = false;

        emit ResolverWhitelistRemoved(_resolverAddress);
    }

    /// @notice Return if the resolver is valid.
    /// @param _resolverAddress The address to be queried.
    function isValidResolver(address _resolverAddress)
        public
        view
        returns (bool)
    {
        return _whitelistedResolvers[_resolverAddress];
    }
}
