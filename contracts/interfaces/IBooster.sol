// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IBooster {
    function depositInGauge(address pool, uint amount) external;
    function withdrawFromGauge(address pool, uint amount)  external;
    function getRewardFromGauge(address pool, address[] calldata tokens) external;
    function claimBribes(address pool) external returns (address[] memory bribes);
    function poke(address token) external;
    function setTokenForPool(address pool, address token) external;
}