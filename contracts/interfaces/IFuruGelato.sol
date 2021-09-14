// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFuruGelato {
    event TaskCreated(
        address indexed taskCreator,
        bytes32 taskId,
        address indexed resolverAddress,
        bytes executionData
    );
    event TaskCancelled(
        address indexed taskCreator,
        bytes32 taskId,
        address indexed resolverAddress,
        bytes executionData
    );
    event ExecSuccess(
        uint256 indexed txFee,
        address indexed feeToken,
        address indexed taskExecutor,
        bytes32 taskId
    );

    event LogFundsDeposited(address indexed sender, uint256 amount);
    event LogFundsWithdrawn(
        address indexed sender,
        uint256 amount,
        address receiver
    );

    function createTask(address _resolverAddress, bytes calldata _resolverData)
        external;

    function cancelTask(address _resolverAddress, bytes calldata _resolverData)
        external;

    function exec(
        uint256 _fee,
        address _proxy,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external;

    function getTaskIdsByUser(address _taskCreator)
        external
        view
        returns (bytes32[] memory);

    function withdrawFunds(uint256 _amount, address payable _receiver) external;
}

interface IDSProxyBlacklist {
    function banDSProxy(address _dsProxy) external;

    function unbanDSProxy(address _dsProxy) external;

    function isValidDSProxy(address _dsProxy) external view returns (bool);
}

interface IResolverWhitelist {
    function registerResolver(address _resolverAddress) external;

    function unregisterResolver(address _resolverAddress) external;

    function isValidResolver(address _resolverAddress)
        external
        view
        returns (bool);
}

interface ITaskBlacklist {
    function banTask(bytes32 _taskId) external;

    function unbanTask(bytes32 _taskId) external;

    function isValidTask(bytes32 _taskId) external view returns (bool);
}
