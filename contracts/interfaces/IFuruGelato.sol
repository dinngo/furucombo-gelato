// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IFuruGelato {
    function createTask(address _resolver, bytes calldata _taskData) external;

    function cancelTask(address _resolver, bytes calldata _taskData) external;

    function exec(
        uint256 _fee,
        address _caller,
        address _resolver,
        bytes calldata _taskData,
        bytes calldata _execData
    ) external;

    function dsProxyExecute(bytes calldata _execData) external;

    function whitelistResolver(address _resolver) external;

    function removeResolverFromWhitelist(address _resolver) external;

    function withdrawFunds(uint256 _amount) external;

    function getWhitelistedResolvers()
        external
        view
        returns (address[] memory _resolvers);
}
