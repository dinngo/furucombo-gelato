// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IFuruGelato {
    function createTask(
        address[] calldata _targets,
        bytes[] calldata _execDatas
    ) external;

    function cancelTask(
        address[] calldata _targets,
        bytes[] calldata _execDatas
    ) external;

    function exec(
        uint256 _fee,
        address _proxy,
        address[] calldata _targets,
        bytes[] calldata _execDatas
    ) external;
}
