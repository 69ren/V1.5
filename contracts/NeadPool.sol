// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./Libraries/ERC20.sol";
import "./interfaces/IBooster.sol";
import "./interfaces/ISwappoor.sol";
import "./interfaces/IPoolRouter.sol";
import "./interfaces/IVeDepositor.sol";

contract neadPool is Initializable, BaseERC20 {
    // Reward data vars
    struct Reward {
        uint integral;
        uint delta;
    }

    // account -> token -> integral
    mapping(address => mapping(address => uint)) public rewardIntegralFor;
    // token -> integral
    mapping(address => Reward) public rewardIntegral;
    // account -> token -> claimable
    mapping(address => mapping(address => uint)) public claimable;
    // list of reward tokens
    address[] public rewards;
    mapping(address => bool) isReward;

    address booster;
    address poolRouter;
    address pool;

    address snek;
    address neadSnek;

    // events
    event RewardPaid(
        address indexed user,
        address indexed rewardsToken,
        uint256 reward
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _pool,
        address _reward,
        address _poolRouter,
        address _booster
    ) external initializer {
        pool = _pool;

        if (!isReward[_reward]) isReward[_reward] = true;
        rewards.push(_reward);

        poolRouter = _poolRouter;
        booster = _booster;
        IERC20Upgradeable(pool).approve(booster, type(uint).max);

        string memory _symbol = BaseERC20(pool).symbol();
        string memory _name = string(
            abi.encodePacked("Ennead ", _symbol, " Deposit")
        );
        _symbol = string(abi.encodePacked("nead-", _symbol));
        ERC20Init(_name, _symbol);

        snek = IBooster(_booster).snek();
        neadSnek = IBooster(_booster).veDepositor();
        IERC20Upgradeable(IPoolRouter(_poolRouter).swappoor()).approve(
            _reward,
            type(uint).max
        );
        IERC20Upgradeable(snek).approve(neadSnek, type(uint).max);
    }

    function deposit(
        address account,
        uint amount
    ) external updateRewards(account) {
        require(msg.sender == account || msg.sender == poolRouter);
        require(amount > 0, "Can't deposit 0!");

        _mint(account, amount);
        if (msg.sender == account) {
            IERC20Upgradeable(pool).transferFrom(account, booster, amount);
        } else {
            IERC20Upgradeable(pool).transferFrom(poolRouter, booster, amount);
        }
        IBooster(booster).depositInGauge(pool, amount);
    }

    function withdraw(
        address account,
        uint amount
    ) external updateRewards(account) {
        require(msg.sender == account || msg.sender == poolRouter);
        require(amount > 0, "Can't withdraw 0!");

        _burn(account, amount);
        IBooster(booster).withdrawFromGauge(pool, amount);
        IERC20Upgradeable(pool).transferFrom(booster, account, amount);
    }

    /// @notice earned is an estimation and is not exact until checkpoints have actually been updated.
    function earned(
        address account,
        address[] calldata tokens
    ) external view returns (uint[] memory) {
        uint[] memory pending = new uint[](tokens.length);
        uint bal = balanceOf[account];
        uint _totalSupply = totalSupply;

        if (bal > 0) {
            for (uint i; i < tokens.length; ++i) {
                pending[i] += claimable[account][tokens[i]];
                uint integral = rewardIntegral[tokens[i]].integral;

                if (totalSupply > 0) {
                    uint256 delta = IBooster(booster).earned(pool, tokens[i]);
                    integral += (1e18 * delta) / _totalSupply;
                }

                uint integralFor = rewardIntegralFor[account][tokens[i]];
                if (integralFor < integral)
                    pending[i] += (bal * (integral - integralFor)) / 1e18;
            }
        } else {
            for (uint i; i < tokens.length; ++i) {
                pending[i] = claimable[account][tokens[i]];
            }
        }
        return pending;
    }

    /// @dev using unchecked math, highly unlikely to over or underflow
    modifier updateRewards(address account) {
        address[] memory _rewards = rewards;
        uint len = _rewards.length;
        uint total = totalSupply;
        IBooster(booster).getRewardFromGauge(pool, _rewards);
        unchecked {
            for (uint i; i < len; ++i) {
                Reward storage _integral = rewardIntegral[_rewards[i]];
                if (total > 0) {
                    uint bal = IERC20Upgradeable(_rewards[i]).balanceOf(
                        address(this)
                    );
                    uint _delta = bal - _integral.delta;

                    if (_delta > 0) {
                        _integral.integral += (1e18 * _delta) / total;
                        _integral.delta = bal;
                    }
                }

                if (account != address(0)) {
                    uint integralFor = rewardIntegralFor[account][_rewards[i]];
                    if (integralFor < _integral.integral) {
                        claimable[account][_rewards[i]] +=
                            (balanceOf[account] *
                                (_integral.integral - integralFor)) /
                            1e18;
                        rewardIntegralFor[account][_rewards[i]] = _integral
                            .integral;
                    }
                }
            }
        }
        _;
    }

    /// @dev using unchecked math, no possibility for an under or overflow
    function getReward(address account) external updateRewards(account) {
        require(msg.sender == account || msg.sender == poolRouter);

        address[] memory _rewards = rewards;
        uint len = _rewards.length;
        unchecked {
            for (uint i; i < len; ++i) {
                uint claims = claimable[account][_rewards[i]];
                rewardIntegral[_rewards[i]].delta -= claims;
                delete claimable[account][_rewards[i]];
                if (claims > 0) {
                    IERC20Upgradeable(_rewards[i]).transfer(account, claims);
                }
                emit RewardPaid(account, _rewards[i], claims);
            }
        }
    }

    /// @notice claim neadSnek instead of snek
    function claimRewards(address account) external updateRewards(account) {
        require(msg.sender == account || msg.sender == poolRouter);

        address[] memory _rewards = rewards;
        uint len = _rewards.length;
        unchecked {
            for (uint i; i < len; ++i) {
                uint claims = claimable[account][_rewards[i]];
                rewardIntegral[_rewards[i]].delta -= claims;
                delete claimable[account][_rewards[i]];
                if (claims > 0) {
                    if (i != 0) {
                        // snek is always index 0
                        IERC20Upgradeable(_rewards[i]).transfer(
                            account,
                            claims
                        );
                        emit RewardPaid(account, _rewards[i], claims);
                    } else {
                        ISwappoor swap = ISwappoor(
                            IPoolRouter(poolRouter).swappoor()
                        );
                        bool state = swap.priceOutOfSync();
                        if (state) {
                            uint amountOut = swap.swapTokens(
                                _rewards[i],
                                neadSnek,
                                claims
                            );
                            IERC20Upgradeable(neadSnek).transfer(
                                account,
                                amountOut
                            );
                            emit RewardPaid(account, neadSnek, amountOut);
                        } else {
                            IVeDepositor(neadSnek).depositTokens(claims);
                            IERC20Upgradeable(neadSnek).transfer(
                                account,
                                claims
                            );
                            emit RewardPaid(account, neadSnek, claims);
                        }
                    }
                }
            }
        }
    }

    /// @notice In case a new reward token is added, to allow distribution to stakers.
    function addRewardToken(address token) external {
        require(msg.sender == poolRouter);
        if (!isReward[token]) {
            isReward[token] = true;
            rewards.push(token);
        }
    }

    /**
     *   @notice Remove reward tokens if there haven't been emissions in awhile. Saves a lot of gas on interactions.
     *   @dev Must be very careful when calling this function as users will not be able to claim rewards for the token that was removed.
     *   While there is some security measure in place, the caller must still ensure that all users have claimed rewards before this is called.
     */
    function removeRewardToken(address token) external {
        require(msg.sender == poolRouter);
        // 0 balance assumes each user has already claimed their rewards.
        require(IERC20Upgradeable(token).balanceOf(address(this)) == 0);
        // snek will always be index 0, can't remove that.
        require(token != rewards[0]);

        address[] memory _rewards = rewards;
        uint len = _rewards.length;
        uint idx;

        isReward[token] = false;

        // get reward token index
        for (uint i; i < len; ++i) {
            if (_rewards[i] == token) {
                idx = i;
            }
        }

        // remove from rewards list
        for (uint256 i = idx; i < len - 1; ++i) {
            rewards[i] = rewards[i + 1];
        }
        rewards.pop();
    }

    function beforeBalanceChange(
        address account
    ) internal override updateRewards(account) {}

    function rewardsListLength() external view returns (uint) {
        return rewards.length;
    }
}
