// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/Ramses/IVoter.sol";
import "./interfaces/Ramses/IVotingEscrow.sol";
import "./interfaces/Ramses/IGauge.sol";
import "./interfaces/Ramses/IFeeDistributor.sol";
import "./interfaces/IMultiRewards.sol";
import "./interfaces/ISwappoor.sol";
import "./interfaces/IBooster.sol";
import "./interfaces/IVeDepositor.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
    @notice contract that stores platform performance fees and handles bribe distribution
    @notice a callFee is set to incentivize bots to process performance fees / bribes instead of letting lp's shoulder the cost
    @notice any token sent to this contract will be processed!
    @dev performance fees and bribe claiming is separate 
*/

contract feeHandler is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant PROXY_ADMIN_ROLE = keccak256("PROXY_ADMIN");

    address public treasury;
    address public ram;
    address public swapTo;
    address veDepositor;
    address public proxyAdmin;

    IMultiRewards public neadStake;
    ISwappoor public swap;
    IBooster booster;
    IVoter voter;

    uint public bribeCallFee;
    uint public performanceCallFee;
    uint public platformFee; // initially set to 15%
    uint treasuryFee; // initially set to 5%
    uint stakerFee; // initially set to 10%
    uint tokenID;

    mapping(address => bool) isApproved; // check if swapper is approved to spend a token
    // pool -> bribe
    mapping(address => address) public bribeForPool;

    function initialize(
        address _treasury,
        address pauser,
        address setter,
        address _proxyAdmin,
        ISwappoor _swap,
        IBooster _booster,
        IMultiRewards _neadStake
    ) external initializer {
        __Pausable_init();
        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _treasury);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(SETTER_ROLE, setter);
        _grantRole(PROXY_ADMIN_ROLE, _proxyAdmin);
        _setRoleAdmin(PROXY_ADMIN_ROLE, PROXY_ADMIN_ROLE);
        proxyAdmin = _proxyAdmin;

        treasury = _treasury;
        swap = _swap;
        booster = _booster;
        voter = IVoter(_booster.voter());
        tokenID = booster.tokenID();
        ram = _booster.ram();
        veDepositor = _booster.veDepositor();
        neadStake = _neadStake;
        swapTo = swap.weth();
        IERC20Upgradeable(swapTo).approve(address(_neadStake), type(uint).max);

        IERC20Upgradeable(ram).approve(address(swap), type(uint).max);
        IERC20Upgradeable(ram).approve(veDepositor, type(uint).max);
        isApproved[ram] = true;
        IERC20Upgradeable(veDepositor).approve(address(swap), type(uint).max);
        IERC20Upgradeable(veDepositor).approve(
            address(neadStake),
            type(uint).max
        );
        isApproved[veDepositor] = true;
    }

    /// @notice syncs tokenId for booster, needed to make this contract function correctly
    function syncTokenId() external {
        tokenID = booster.tokenID();
    }

    function setSwapTo(address _swapTo) external onlyRole(SETTER_ROLE) {
        swapTo = _swapTo;
        IERC20Upgradeable(_swapTo).approve(address(neadStake), type(uint).max);
    }

    function setCallFees(
        uint _bribeCallFee,
        uint _performanceCallFee
    ) external onlyRole(SETTER_ROLE) {
        bribeCallFee = _bribeCallFee;
        performanceCallFee = _performanceCallFee;
    }

    function setRewardsFees(
        uint _platformFee,
        uint _treasuryFee,
        uint _stakersFee
    ) external onlyRole(SETTER_ROLE) {
        platformFee = _platformFee;
        treasuryFee = _treasuryFee;
        stakerFee = _stakersFee;
        require(treasuryFee + stakerFee == platformFee, "!Total");
        booster.setFee(_platformFee);
    }

    function claimBribes(
        address pool
    ) public returns (address[] memory bribes) {
        address feeDistributor = bribeForPool[pool];
        if (feeDistributor == address(0)) {
            address gauge = voter.gauges(pool);
            feeDistributor = voter.feeDistributers(gauge);
            bribeForPool[pool] = feeDistributor;
        }
        IFeeDistributor feeDist = IFeeDistributor(feeDistributor);
        bribes = feeDist.getRewardTokens();
        feeDist.getReward(tokenID, bribes);
    }

    /// @notice swaps bribes to weth, or locks to neadRam if the reward token is ram and notifies multiRewards
    function processBribes(address pool, address to) public {
        address[] memory tokens = claimBribes(pool);
        uint len = tokens.length;
        uint fee;
        unchecked {
            for (uint i; i < len; ++i) {
                uint bal = IERC20Upgradeable(tokens[i]).balanceOf(
                    address(this)
                );

                if (bal > 0) {
                    fee = (bal * bribeCallFee) / 1e18;
                    if (tokens[i] == ram) {
                        IERC20Upgradeable(tokens[i]).transfer(to, fee);
                        IVeDepositor(veDepositor).depositTokens(bal - fee);
                        neadStake.notifyRewardAmount(veDepositor, bal - fee);
                    } else if (tokens[i] == veDepositor) {
                        IERC20Upgradeable(tokens[i]).transfer(to, fee);
                        neadStake.notifyRewardAmount(tokens[i], bal - fee);
                    } else if (tokens[i] == swapTo) {
                        IERC20Upgradeable(tokens[i]).transfer(to, fee);
                        neadStake.notifyRewardAmount(tokens[i], bal - fee);
                    } else {
                        if (!isApproved[tokens[i]])
                            IERC20Upgradeable(tokens[i]).approve(
                                address(swap),
                                type(uint).max
                            );
                        uint amountOut = swap.swapTokens(
                            tokens[i],
                            swapTo,
                            bal
                        );
                        fee = (amountOut * bribeCallFee) / 1e18;
                        IERC20Upgradeable(swapTo).transfer(to, fee);
                        neadStake.notifyRewardAmount(swapTo, amountOut - fee);
                    }
                }
            }
        }
    }

    /// @notice processes multiple bribes
    function batchProcessBribes(address[] calldata pools, address to) external {
        for (uint i; i < pools.length; ) {
            processBribes(pools[i], to);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice swaps/locks performance fees and sends to multiRewards
    function processPerformanceFees(address token, address to) public {
        booster.poke(token);
        IERC20Upgradeable _token = IERC20Upgradeable(token);
        uint bal = _token.balanceOf(address(this));
        uint treasuryShare;
        uint stakersShare;

        if (bal > 0) {
            unchecked {
                // calculate call fee
                uint fee = (bal * performanceCallFee) / 1e18;
                _token.transfer(to, fee);
                bal -= fee;
                // calculate fee to treasury
                treasuryShare = (fee * treasuryFee) / platformFee;
                // calculate fee to stakers
                stakersShare = (fee * stakerFee) / platformFee;
            }
            _token.transfer(treasury, treasuryShare);
            if (token == ram) {
                bool state = swap.priceOutOfSync();
                if (state) {
                    uint amountOut = swap.swapTokens(ram, veDepositor, stakersShare);
                    IMultiRewards(neadStake).notifyRewardAmount(veDepositor, amountOut);
                } else {
                    IVeDepositor(veDepositor).depositTokens(stakersShare);
                    // neadRam is minted in a 1:1 ratio
                    IMultiRewards(neadStake).notifyRewardAmount(veDepositor, stakersShare);
                }
            } else if (token == veDepositor) {
                IMultiRewards(neadStake).notifyRewardAmount(veDepositor, stakersShare);
            } else {
                if (!isApproved[token]) IERC20Upgradeable(token).approve(address(swap),type(uint).max);
                uint amountOut = swap.swapTokens(token, swapTo, stakersShare);
                IMultiRewards(neadStake).notifyRewardAmount(swapTo, amountOut);
            }
        }
    }

    function batchProcessPerformanceFees(
        address[] calldata tokens,
        address to
    ) external {
        for (uint i; i < tokens.length; ) {
            processPerformanceFees(tokens[i], to);
            unchecked {
                ++i;
            }
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(PROXY_ADMIN_ROLE) {}

    /// @dev grantRole already checks role, so no more additional checks are necessary
    function changeAdmin(address newAdmin) external {
        grantRole(PROXY_ADMIN_ROLE, newAdmin);
        renounceRole(PROXY_ADMIN_ROLE, proxyAdmin);
        proxyAdmin = newAdmin;
    }
}
