// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {IFuruGelato} from "./interfaces/IFuruGelato.sol";

contract CreateTaskHandler {
    address public immutable furuGelato;

    constructor(address _furuGelato) {
        furuGelato = _furuGelato;
    }

    function createTask(
        address[] calldata _targets,
        bytes[] calldata _execDatas
    ) external {
        IFuruGelato(furuGelato).createTask(_targets, _execDatas);
    }

    function cancelTask(
        address[] calldata _targets,
        bytes[] calldata _execDatas
    ) external {
        IFuruGelato(furuGelato).cancelTask(_targets, _execDatas);
    }
}
