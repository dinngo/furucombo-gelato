// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IFuruGelato} from "./interfaces/IFuruGelato.sol";

contract CreateTaskHandler {
    address public immutable furuGelato;

    constructor(address _furuGelato) {
        furuGelato = _furuGelato;
    }

    function createTask(address _resolverAddress, bytes calldata _resolverData)
        external
    {
        IFuruGelato(furuGelato).createTask(_resolverAddress, _resolverData);
    }

    function cancelTask(address _resolverAddress, bytes calldata _resolverData)
        external
    {
        IFuruGelato(furuGelato).cancelTask(_resolverAddress, _resolverData);
    }
}
