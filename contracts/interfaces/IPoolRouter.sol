// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPoolRouter {
    function deposit(address pool, uint amount) external;
    function tokenForPool(address pool) external view returns (address);
    function swappoor() external view returns (address);
    }    
    
