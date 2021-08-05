// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

abstract contract Resolver {
    address public immutable actions;

    constructor(address _actions) {
        actions = _actions;
    }

    function checker(address taskCreator, bytes calldata resolverData)
        external
        view
        virtual
        returns (bool canExec, bytes memory execPayload);

    function onCreateTask(address executor, bytes calldata execData)
        external
        virtual
        returns (bool)
    {
        executor;
        execData;
        return true;
    }

    function onCancelTask(address executor, bytes32 taskId)
        external
        virtual
        returns (bool)
    {
        executor;
        taskId;
        return true;
    }

    function onExec(address executor, bytes calldata execData)
        external
        virtual
        returns (bool)
    {
        executor;
        execData;
        return true;
    }
}
