// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface IGelato {
  function canExec(address _executor) external view returns (bool);

  function isExecutor(address _executor) external view returns (bool);

  function executors() external view returns (address[] memory);
}
