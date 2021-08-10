// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

abstract contract Resolver {
    address public immutable action;

    constructor(address _action) {
        action = _action;
    }

    function checker(address taskCreator, bytes calldata resolverData)
        external
        view
        virtual
        returns (bool canExec, bytes memory executionData);

    function onCreateTask(address taskCreator, bytes calldata executionData)
        external
        virtual
        returns (bool)
    {
        taskCreator;
        executionData;
        return true;
    }

    function onCancelTask(address taskCreator, bytes calldata executionData)
        external
        virtual
        returns (bool)
    {
        taskCreator;
        executionData;
        return true;
    }

    function onExec(address taskExecutor, bytes calldata executionData)
        external
        virtual
        returns (bool)
    {
        taskExecutor;
        executionData;
        return true;
    }
}
