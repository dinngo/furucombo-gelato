// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract ResolverBase {
    address public immutable action;
    address public immutable furuGelato;

    modifier onlyFuruGelato() {
        require(msg.sender == furuGelato, "not FuruGelato");
        _;
    }

    constructor(address _action, address _furuGelato) {
        action = _action;
        furuGelato = _furuGelato;
    }

    function checker(address taskCreator, bytes calldata resolverData)
        external
        view
        virtual
        returns (bool canExec, bytes memory executionData);

    function onCreateTask(address taskCreator, bytes calldata executionData)
        external
        virtual
        onlyFuruGelato
        returns (bool)
    {
        taskCreator;
        executionData;
        return true;
    }

    function onCancelTask(address taskCreator, bytes calldata executionData)
        external
        virtual
        onlyFuruGelato
        returns (bool)
    {
        taskCreator;
        executionData;
        return true;
    }

    function onExec(address taskCreator, bytes calldata executionData)
        external
        virtual
        onlyFuruGelato
        returns (bool)
    {
        taskCreator;
        executionData;
        return true;
    }
}
