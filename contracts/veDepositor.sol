// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/Ramses/IVotingEscrow.sol";
import "./Libraries/ERC20.sol";
import "./interfaces/Ramses/IRewardsDistributor.sol";
import "./interfaces/IMultiRewards.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract VeDepositor is
    Initializable,
    BaseERC20,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant PROXY_ADMIN_ROLE = keccak256("PROXY_ADMIN");

    IERC20Upgradeable public token;
    IVotingEscrow public votingEscrow;
    IRewardsDistributor public veDistributor;

    address public booster;
    address public neadStake;
    address public proxyAdmin;

    uint256 public tokenID;
    uint256 public unlockTime;
    uint256 public constant WEEK = 1 weeks;
    uint256 public constant MAX_LOCK_TIME = 4 * 365 * 86400;

    event ClaimedFromVeDistributor(address indexed user, uint256 amount);
    event Merged(address indexed user, uint256 tokenID, uint256 amount);
    event UnlockTimeUpdated(uint256 unlockTime);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        IERC20Upgradeable _token,
        IVotingEscrow _votingEscrow,
        IRewardsDistributor _veDist,
        address admin,
        address pauser,
        address setter,
        address _proxyAdmin
    ) public initializer {
        __Pausable_init();
        __AccessControlEnumerable_init();
        ERC20Init("neadRAM: Tokenized veRAM", "neadRAM");

        token = _token;
        votingEscrow = _votingEscrow;
        veDistributor = _veDist;

        // approve vesting escrow to transfer RAM (for adding to lock)
        _token.approve(address(_votingEscrow), type(uint256).max);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(SETTER_ROLE, setter);
        _grantRole(PROXY_ADMIN_ROLE, _proxyAdmin);
        _setRoleAdmin(PROXY_ADMIN_ROLE, PROXY_ADMIN_ROLE);
        proxyAdmin = _proxyAdmin;
    }

    function setAddresses(
        address _booster,
        address _neadStake
    ) external onlyRole(SETTER_ROLE) {
        booster = _booster;
        allowance[address(this)][_neadStake] = type(uint).max;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenID,
        bytes calldata
    ) external whenNotPaused returns (bytes4) {
        require(
            msg.sender == address(votingEscrow),
            "Can only receive veRAM NFTs"
        );

        require(_tokenID > 0, "Cannot receive zero tokenID");

        (uint256 amount, uint256 end) = votingEscrow.locked(_tokenID);

        if (tokenID == 0) {
            tokenID = _tokenID;
            unlockTime = end;
            votingEscrow.safeTransferFrom(address(this), booster, _tokenID);
        } else {
            votingEscrow.merge(_tokenID, tokenID);
            if (end > unlockTime) unlockTime = end;
            emit Merged(_operator, _tokenID, amount);
        }

        _mint(_operator, amount);
        extendLockTime();

        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    /**
        @notice Merge a veRAM NFT previously sent to this contract with the main NFT
        @dev This is primarily meant to allow claiming balances from NFTs incorrectly sent using `transferFrom`.
        @param _tokenID ID of the NFT to merge
        @return bool success
     */
    function merge(uint256 _tokenID) external whenNotPaused returns (bool) {
        require(tokenID != _tokenID, "ENNEAD TOKEN ID");
        (uint256 amount, uint256 end) = votingEscrow.locked(_tokenID);
        require(amount > 0, "ZERO Amount");

        votingEscrow.merge(_tokenID, tokenID);
        if (end > unlockTime) unlockTime = end;
        emit Merged(msg.sender, _tokenID, amount);

        _mint(msg.sender, amount);
        extendLockTime();

        return true;
    }

    /**
        @notice Deposit RAM tokens and mint neadRAM
        @param _amount Amount of RAM to deposit
        @return bool success
     */
    function depositTokens(
        uint256 _amount
    ) external whenNotPaused returns (bool) {
        require(tokenID != 0, "First deposit must be NFT");

        token.transferFrom(msg.sender, address(this), _amount);
        votingEscrow.increase_amount(tokenID, _amount);
        _mint(msg.sender, _amount);
        extendLockTime();

        return true;
    }

    /**
        @notice Extend the lock time of the protocol's veRAM NFT
        @dev Lock times are also extended each time new neadRAM is minted.
     */
    function extendLockTime() public {
        uint256 maxUnlock = ((block.timestamp + MAX_LOCK_TIME) / WEEK) * WEEK;
        if (maxUnlock > unlockTime) {
            votingEscrow.increase_unlock_time(tokenID, MAX_LOCK_TIME);
            unlockTime = maxUnlock;
            emit UnlockTimeUpdated(unlockTime);
        }
    }

    /**
        @notice claim weekly veRam rebase and mint new tokens
    */
    function claimRebase() external whenNotPaused returns (bool) {
        veDistributor.claim(tokenID);

        (uint256 amount, ) = votingEscrow.locked(tokenID);
        amount -= totalSupply;

        if (amount > 0) {
            _mint(address(this), amount);
            IMultiRewards(neadStake).notifyRewardAmount(address(this), amount);
        }

        return true;
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
