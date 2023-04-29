// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IRewardsDistributor {
    function claim(uint _tokenId) external returns (uint);
}
