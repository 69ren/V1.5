// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";


contract multiRewards is Initializable, AccessControlEnumerableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant NOTIFIER_ROLE = keccak256("OPERATOR_ROLE");

    address public elmo;
    uint256 internal constant DURATION = 7 days;
    uint256 internal constant PRECISION = 10 ** 18;

    struct Reward {
        uint rewardRate;
        uint periodFinish;
        uint lastUpdateTime;
        uint rewardPerTokenStored;
    }
    mapping(address => Reward) public rewardData;

    mapping(address => mapping(address => uint256)) public storedRewardsPerUser;
    mapping(address => mapping(address => uint256)) public userRewardPerTokenStored;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    address[] public rewards;
    mapping(address => bool) public isReward;

    event Deposit(address indexed from, uint amount);
    event Withdraw(address indexed from, uint amount);
    event NotifyReward(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
    event ClaimRewards(
        address indexed from,
        address indexed reward,
        uint256 amount
    );

    function initialize(address _elmo, address admin, address pauser, address notifier) external initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        __AccessControlEnumerable_init();

        elmo = _elmo;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(NOTIFIER_ROLE, notifier);
        
    }

    function rewardsListLength() external view returns (uint256) {
        return rewards.length;
    }

    function lastTimeRewardApplicable(address token) public view returns (uint256) {
        return MathUpgradeable.min(block.timestamp, rewardData[token].periodFinish);
    }

    function earned(address token, address account) public view returns (uint256) {
        return (balanceOf[account] * (rewardPerToken(token) - userRewardPerTokenStored[account][token])) / PRECISION + storedRewardsPerUser[account][token];
    }

    function getReward() external nonReentrant whenNotPaused updateReward(msg.sender) {
        address[] memory _rewards = rewards;
        uint len = _rewards.length;
        for (uint256 i; i < len; ++i) {
                address token = _rewards[i];
                uint _reward = storedRewardsPerUser[msg.sender][token];
                if (_reward > 0) {
                    storedRewardsPerUser[msg.sender][token] = 0;
                    IERC20Upgradeable(token).transfer(msg.sender, _reward);
                    emit ClaimRewards(msg.sender, token, _reward);
                }
            }
        }

    function rewardPerToken(address token) public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardData[token].rewardPerTokenStored;
        }
        return
            rewardData[token].rewardPerTokenStored +
            (((lastTimeRewardApplicable(token) -
                MathUpgradeable.min(rewardData[token].lastUpdateTime, rewardData[token].periodFinish)) *
                rewardData[token].rewardRate *
                PRECISION) / totalSupply);
    }

    function deposit(address account, uint amount) external nonReentrant whenNotPaused updateReward(account) {
        require(amount > 0, "Can't stake 0!");
        require(msg.sender == elmo, "!elmo");
        
        totalSupply += amount;
        balanceOf[account] += amount;

        emit Deposit(account, amount);
    }

    function withdraw(address account, uint amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Can't stake 0!");
        require(msg.sender == elmo, "!elmo");

        totalSupply -= amount;
        balanceOf[account] -= amount;
        
        emit Withdraw(account, amount);
    }
    

    function notifyRewardAmount(address token, uint256 amount) external nonReentrant onlyRole(NOTIFIER_ROLE) updateReward(address(0)) {
        require(amount > 0);
        
        if(!isReward[token]) {
            isReward[token] = true;
            rewards.push(token);
        }
        IERC20Upgradeable(token).transferFrom(msg.sender, address(this), amount);

        if (block.timestamp >= rewardData[token].periodFinish) {
            rewardData[token].rewardRate = amount / DURATION;
        } else {
            uint256 remaining = rewardData[token].periodFinish - block.timestamp;
            uint256 left = remaining * rewardData[token].rewardRate;
            rewardData[token].rewardRate = (amount + left) / DURATION;
        }

        rewardData[token].lastUpdateTime = block.timestamp;
        rewardData[token].periodFinish = block.timestamp + DURATION;

        emit NotifyReward(msg.sender, token, amount);
    }

    function removeReward(address token) external onlyRole(NOTIFIER_ROLE) {
        require(IERC20Upgradeable(token).balanceOf(address(this)) == 0);
        
        if (!isReward[token]) {
            return;
        }
        address[] memory _rewards = rewards;
        uint len = _rewards.length;
        uint idx;

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
        isReward[token] = false;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }


    modifier updateReward(address account) {
        address[] memory _rewards = rewards;
        uint len = _rewards.length;
        for (uint256 i; i < len; ++i) {
            address token = _rewards[i];
            rewardData[token].rewardPerTokenStored = rewardPerToken(token);
            rewardData[token].lastUpdateTime = lastTimeRewardApplicable(token);
            if (account != address(0)) {
                storedRewardsPerUser[account][token] = earned(account, token);
                userRewardPerTokenStored[account][token] = rewardData[token]
                    .rewardPerTokenStored;
            }
        }
        _;
    }

    modifier onlyElmo() {
        require(msg.sender == elmo, "!elmo");
        _;
    }
}