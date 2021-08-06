// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

abstract contract Resolver {
    address public immutable action;

    constructor(address _action) {
        action = _action;
    }

    function checker(address taskCreator, bytes calldata resolverData)
        external
        view
        virtual
        returns (bool canExec, bytes memory execPayload);

    function onCreateTask(address executor, bytes calldata resolverData)
        external
        virtual
        returns (bool)
    {
        executor;
        resolverData;
        return true;
    }

    function onCancelTask(address executor, bytes calldata resolverData)
        external
        virtual
        returns (bool)
    {
        executor;
        resolverData;
        return true;
    }

    function onExec(address executor, bytes calldata resolverData)
        external
        virtual
        returns (bool)
    {
        executor;
        resolverData;
        return true;
    }
}
