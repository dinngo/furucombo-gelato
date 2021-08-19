// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DSProxyBlacklist is Ownable {
    /// @notice The blacklist of the dsProxys.
    mapping(address => bool) private _blacklistedDSProxies;

    event DSProxyBlacklistAdded(address dsProxy);
    event DSProxyBlacklistRemoved(address dsProxy);

    modifier onlyValidDSProxy(address _dsProxy) {
        require(isValidDSProxy(_dsProxy), "Invalid dsProxy");
        _;
    }

    /// @notice Ban the dsProxy from being able to be executed.
    /// @param _dsProxy The dsProxy to be banned.
    function banDSProxy(address _dsProxy) external onlyOwner {
        _blacklistedDSProxies[_dsProxy] = true;

        emit DSProxyBlacklistAdded(_dsProxy);
    }

    /// @notice Unban the dsProxy.
    /// @param _dsProxy The dsProxy to be unbanned.
    function unbanDSProxy(address _dsProxy) external onlyOwner {
        require(!isValidDSProxy(_dsProxy), "Not banned");
        _blacklistedDSProxies[_dsProxy] = false;

        emit DSProxyBlacklistRemoved(_dsProxy);
    }

    /// @notice Return if the dsProxy is valid.
    /// @param _dsProxy The dsProxy to be queried.
    function isValidDSProxy(address _dsProxy) public view returns (bool) {
        return (!_blacklistedDSProxies[_dsProxy]);
    }
}
