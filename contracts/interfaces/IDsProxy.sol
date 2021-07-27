// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IDsProxy {
    function owner() external view returns (address);

    function execute(address _target, bytes memory _data)
        external
        payable
        returns (bytes memory response);

    function setAuthority(address _authority) external;

    event LogSetAuthority(address indexed authority);
}

interface IProxyRegistry {
    function build() external returns (address proxy);

    function proxies(address _userAddress)
        external
        view
        returns (address proxy);
}
