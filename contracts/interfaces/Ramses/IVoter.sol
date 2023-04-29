// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IVoter {
    function bribes(address gauge) external view returns (address bribe);
    function gauges(address pool) external view returns (address gauge);
    function poolForGauge(address gauge) external view returns (address pool);
    function createGauge(address pool) external returns (address);
    function feeDistributers(address gauge) external view returns (address);
    function vote(
        uint256 tokenId,
        address[] calldata pools,
        uint256[] calldata weights
    ) external;
    function _ve() external view returns (address);
    function base() external view returns (address);

}
