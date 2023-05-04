// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


import "./interfaces/IBooster.sol";
import "./interfaces/INeadPool.sol";


contract PoolRouter is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant PROXY_ADMIN_ROLE = keccak256("PROXY_ADMIN");

    IBooster public booster;
    // pool -> deposit token
    mapping(address => address) public tokenForPool;

    address public poolBeacon;
    address public proxyAdmin;
    address ram;
    address public swappoor;

    function initialize(
        address _poolBeacon,
        IBooster _booster,
        address _swappoor,
        address admin,
        address pauser,
        address operator,
        address _proxyAdmin
    ) external initializer {
        __Pausable_init();
        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(OPERATOR_ROLE, operator);
        _grantRole(PROXY_ADMIN_ROLE, _proxyAdmin);
        _setRoleAdmin(PROXY_ADMIN_ROLE, PROXY_ADMIN_ROLE);

        proxyAdmin = _proxyAdmin;
        poolBeacon = _poolBeacon;
        booster = _booster;
        ram = booster.ram();
        swappoor = _swappoor;
    }

    /// @notice creating pools is permissionless, if it doesn't already exist one is created on the first deposit
    function createPool(
        address _pool,
        address _reward
    ) public returns (address token) {
        require(tokenForPool[_pool] == address(0), "exists");
        BeaconProxy _token = new BeaconProxy(
            poolBeacon,
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                _pool,
                _reward,
                address(this),
                address(booster)
            )
        );
        token = address(_token);
        tokenForPool[_pool] = token;
        IERC20Upgradeable(_pool).approve(token, type(uint).max);
        booster.setTokenForPool(_pool, token);
    }

    function deposit(address pool, uint amount) external whenNotPaused {
        address _pool = tokenForPool[pool];
        if (_pool == address(0)) {
            _pool = createPool(pool, ram);
        }
        IERC20Upgradeable(pool).transferFrom(msg.sender, address(this), amount);
        INeadPool(_pool).deposit(msg.sender, amount);
    }

    function withdraw(address pool, uint amount) external whenNotPaused {
        address _pool = tokenForPool[pool];
        INeadPool(_pool).withdraw(msg.sender, amount);
    }

    function getReward(address[] calldata pools) external whenNotPaused {
        for (uint i; i < pools.length; ) {
            INeadPool(pools[i]).getReward(msg.sender);
            unchecked {
                ++i;
            }
        }
    }

    function claimRewards(address[] calldata pools) external whenNotPaused {
        for (uint i; i < pools.length; ) {
            INeadPool(pools[i]).claimRewards(msg.sender);
        }
    }

    function addRewardsPerPool(
        address[] calldata pools,
        address[][] calldata tokens
    ) external onlyRole(OPERATOR_ROLE) {
        for (uint i; i < pools.length; ++i) {
            address pool = pools[i];
            address[] memory token = tokens[i];

            for (uint j; j < token.length; ++j) {
                INeadPool(pool).addRewardToken(token[j]);
            }
        }
    }

    function removeRewardsPerPool(
        address[] calldata pools,
        address[][] calldata tokens
    ) external onlyRole(OPERATOR_ROLE) {
        for (uint i; i < pools.length; ++i) {
            address pool = pools[i];
            address[] memory token = tokens[i];
            uint len = token.length;

            for (uint j; j < len; ++j) {
                INeadPool(pool).removeRewardToken(token[j]);
            }
        }
    }

    function setSwappoor(address _swappoor) external onlyRole(SETTER_ROLE) {
        swappoor = _swappoor;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(PROXY_ADMIN_ROLE) {}

    /// @dev grantRole already checks role, so no more additional checks are necessary
    function changeAdmin(address newAdmin) external {
        grantRole(PROXY_ADMIN_ROLE, newAdmin);
        renounceRole(PROXY_ADMIN_ROLE, proxyAdmin);
        proxyAdmin = newAdmin;
    }

}
