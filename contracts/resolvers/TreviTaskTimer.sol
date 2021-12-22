// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import {TaskTimer} from "./TaskTimer.sol";

/// @title Task timer is a implementation of resolver for generating tasks
/// that can be executed repeatedly after a specific time period.
contract TreviTaskTimer is TaskTimer {
    address public immutable aFurucombo;
    address public immutable aTrevi;

    // solhint-disable
    // prettier-ignore
    bytes4 private constant _HARVEST_SIG =
        bytes4(keccak256(bytes("harvestAngelsAndCharge(address,address[],address[])")));
    // prettier-ignore
    bytes4 private constant _EXEC_SIG =
        bytes4(keccak256(bytes("injectAndBatchExec(address[],uint256[],address[],address[],bytes32[],bytes[])")));
    // prettier-ignore
    bytes4 private constant _DEPOSIT_SIG =
        bytes4(keccak256(bytes("deposit(address,uint256)")));

    constructor(
        address _action,
        address _furuGelato,
        address _aFurucombo,
        address _aTrevi,
        uint256 _period
    ) TaskTimer(_action, _furuGelato, _period) {
        aFurucombo = _aFurucombo;
        aTrevi = _aTrevi;
    }

    function _isValidResolverData(bytes memory data)
        internal
        view
        override
        returns (bool)
    {
        (address[] memory tos, , bytes[] memory datas) =
            abi.decode(data, (address[], bytes32[], bytes[]));
        require(tos.length == 3, "Invalid tos length");
        require(tos[0] == aTrevi, "Invalid tos[0]");
        require(tos[1] == aFurucombo, "Invalid tos[1]");
        require(tos[2] == aTrevi, "Invalid tos[2]");
        require(bytes4(datas[0]) == _HARVEST_SIG, "Invalid datas[0]");
        require(bytes4(datas[1]) == _EXEC_SIG, "Invalid datas[1]");
        require(bytes4(datas[2]) == _DEPOSIT_SIG, "Invalid datas[2]");

        return true;
    }
}
