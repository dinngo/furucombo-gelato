// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IProxy} from "./interfaces/IProxy.sol";

contract DummyResolver {
    address public immutable dummyHandler;
    bool public allowExec;

    constructor(address _dummyHandler) public {
        allowExec = false;
        dummyHandler = _dummyHandler;
    }

    function genPayloadAndCanExec(bytes calldata taskData)
        external
        view
        returns (bytes memory execData, bool _canExec)
    {
        address[] memory tos = new address[](1);
        tos[0] = dummyHandler;

        bytes32[] memory configs = new bytes32[](1);
        configs[0] = bytes32(0);

        bytes[] memory data = new bytes[](1);
        data[0] = taskData;

        bytes4 selector =
            bytes4(keccak256("batchExec(address[],bytes32[],bytes[])"));
        execData = abi.encodeWithSelector(selector, tos, configs, data);

        _canExec = canExec(taskData);
    }

    function canExec(bytes calldata data) public view returns (bool _canExec) {
        data;
        _canExec = allowExec;
    }

    function toggleAllowExec() external {
        allowExec = !allowExec;
    }
}
