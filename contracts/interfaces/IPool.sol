// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPool {
    function deposit(address account, uint amount) external;
    function withdraw(address account, uint amount) external;
    function getReward(address account) external;
    function addRewardToken(address token) external;
    function removeRewardToken(address token) external;
}