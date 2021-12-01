// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ITaskBlacklist, IDSProxyBlacklist} from "../interfaces/IFuruGelato.sol";
import {DSProxyTask} from "../DSProxyTask.sol";
import {StandardResolver} from "./StandardResolver.sol";

/// @title RQuickswap is a implementation of resolver for generating tasks
/// that can be executed repeatedly after a specific time period.
contract RQuickswap is StandardResolver {
    address public immutable aQuickswapFarm;
    address public immutable aFurucombo;

    bytes4 private constant _GET_REWARD_AND_CHARGE_SIG =
        bytes4(keccak256(bytes("getRewardAndCharge(address)")));

    bytes4 private constant _GET_REWARD_SIG =
        bytes4(keccak256(bytes("getReward(address)")));

    bytes4 private constant _DQUICK_LEAVE_SIG =
        bytes4(keccak256(bytes("dQuickLeave()")));

    bytes4 private constant _EXEC_SIG =
        bytes4(
            keccak256(
                bytes(
                    "injectAndBatchExec(address[],uint256[],address[],address[],bytes32[],bytes[])"
                )
            )
        );

    constructor(
        address _action,
        address _furuGelato,
        address _aQuickswapFarm,
        address _aFurucombo,
        uint256 _period
    ) StandardResolver(_action, _furuGelato, _period) {
        aQuickswapFarm = _aQuickswapFarm;
        aFurucombo = _aFurucombo;
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

        require(tos[0] == aQuickswapFarm, "Invalid tos[0]");
        require(tos[1] == aQuickswapFarm, "Invalid tos[1]");
        require(tos[2] == aFurucombo, "Invalid tos[2]");

        require(
            bytes4(datas[0]) == _GET_REWARD_AND_CHARGE_SIG,
            "Invalid datas[0]"
        );
        require(bytes4(datas[1]) == _DQUICK_LEAVE_SIG, "Invalid datas[1]");
        require(bytes4(datas[2]) == _EXEC_SIG, "Invalid datas[2]");

        return true;
    }
}
