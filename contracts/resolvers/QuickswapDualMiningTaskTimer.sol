// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {TaskTimer} from "./TaskTimer.sol";

contract QuickswapDualMiningTaskTimer is TaskTimer {
    address public immutable aQuickswapDualMining;
    address public immutable aFurucombo;

    // solhint-disable
    // prettier-ignore
    bytes4 private constant _GET_REWARD_AND_CHARGE_SIG =
        bytes4(keccak256(bytes("getRewardAndCharge(address)")));
    // prettier-ignore
    bytes4 private constant _DQUICK_LEAVE_SIG =
        bytes4(keccak256(bytes("dQuickLeave(uint256)")));
    // prettier-ignore
    bytes4 private constant _STAKE_SIG =
        bytes4(keccak256(bytes("stake(address,uint256)")));
    // prettier-ignore
    bytes4 private constant _EXEC_SIG =
        bytes4(keccak256(bytes("injectAndBatchExec(address[],uint256[],address[],address[],bytes32[],bytes[])")));

    constructor(
        address _action,
        address _furuGelato,
        address _aQuickswapDualMining,
        address _aFurucombo,
        uint256 _period
    ) TaskTimer(_action, _furuGelato, _period) {
        aQuickswapDualMining = _aQuickswapDualMining;
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
        require(tos.length == 4, "Invalid tos length");

        require(tos[0] == aQuickswapDualMining, "Invalid tos[0]");
        require(tos[1] == aQuickswapDualMining, "Invalid tos[1]");
        require(tos[2] == aFurucombo, "Invalid tos[2]");
        require(tos[3] == aQuickswapDualMining, "Invalid tos[3]");

        require(
            bytes4(datas[0]) == _GET_REWARD_AND_CHARGE_SIG,
            "Invalid datas[0]"
        );
        require(bytes4(datas[1]) == _DQUICK_LEAVE_SIG, "Invalid datas[1]");
        require(bytes4(datas[2]) == _EXEC_SIG, "Invalid datas[2]");
        require(bytes4(datas[3]) == _STAKE_SIG, "Invalid datas[3]");

        return true;
    }
}
