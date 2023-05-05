// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/SoliSnek/IVoter.sol";
import "./interfaces/SoliSnek/IVotingEscrow.sol";
import "./interfaces/SoliSnek/IGauge.sol";
import "./interfaces/SoliSnek/IFeeDistributor.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Booster is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant PROXY_ADMIN_ROLE = keccak256("PROXY_ADMIN");

    IVoter public voter;
    IVotingEscrow votingEscrow;

    address public veDepositor;
    address public feeHandler;
    address public poolRouter;
    address public snek;

    uint public tokenID;
    uint public platformFee; // mirrored from feeHandler to reduce external calls
    mapping(address => uint) public unclaimedFees;
    // pool -> gauge
    mapping(address => address) public gaugeForPool;
    // pool -> token
    mapping(address => address) public tokenForPool; // mirrored from poolRouter to save on external calls

    address public proxyAdmin;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        IVoter _voter,
        address admin,
        address pauser,
        address voterRole,
        address operator,
        address _proxyAdmin
    ) public initializer {
        __Pausable_init();
        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(VOTER_ROLE, voterRole);
        _grantRole(OPERATOR_ROLE, operator);
        _grantRole(PROXY_ADMIN_ROLE, _proxyAdmin);
        _setRoleAdmin(PROXY_ADMIN_ROLE, PROXY_ADMIN_ROLE);
        proxyAdmin = _proxyAdmin;

        voter = _voter;
        votingEscrow = IVotingEscrow(voter._ve());
        snek = voter.base();
    }

    function setAddresses(
        address _veDepositor,
        address _feeHandler,
        address _poolRouter
    ) external onlyRole(OPERATOR_ROLE) {
        if (_veDepositor != address(0)) {
            if (veDepositor != address(0))
                votingEscrow.setApprovalForAll(veDepositor, false);
            veDepositor = _veDepositor;
            votingEscrow.setApprovalForAll(veDepositor, true);
        }
        if (_feeHandler != address(0)) {
            if (feeHandler != address(0))
                votingEscrow.setApprovalForAll(feeHandler, false);
            feeHandler = _feeHandler;
            votingEscrow.setApprovalForAll(_feeHandler, true);
        }
        if (_poolRouter != address(0)) {
            poolRouter = _poolRouter;
        }
    }

    function setTokenForPool(address pool, address token) external {
        require(msg.sender == poolRouter);
        tokenForPool[pool] = token;
        IERC20Upgradeable(pool).approve(token, type(uint).max);
        address gauge = gaugeForPool[pool];
        if (gauge == address(0)) {
            gauge = voter.gauges(pool);
            if (gauge == address(0)) {
                gauge = voter.createGauge(pool);
            }
            gaugeForPool[pool] = gauge;
            IERC20Upgradeable(pool).approve(gauge, type(uint).max);
        }
    }

    function setFee(uint fee) external {
        require(msg.sender == feeHandler);
        platformFee = fee;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint _tokenID,
        bytes calldata
    ) external whenNotPaused returns (bytes4) {
        require(_operator == veDepositor);

        require(msg.sender == address(votingEscrow));

        if (tokenID == 0) {
            tokenID = _tokenID;
        }

        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    /**
        @notice stakes lp tokens in gauge, only pool contracts can call this function
        @dev does not do transferFrom, it relies on the pool to send the lp tokens beforehand.
    */
    function depositInGauge(address pool, uint amount) external whenNotPaused {
        require(msg.sender == tokenForPool[pool], "!neadPool");
        address gauge = gaugeForPool[pool];
        IGauge(gauge).deposit(amount, tokenID);
    }

    function withdrawFromGauge(
        address pool,
        uint amount
    ) external whenNotPaused {
        require(msg.sender == tokenForPool[pool], "!neadPool");
        address gauge = gaugeForPool[pool];
        IGauge(gauge).withdraw(amount);
    }

    function getRewardFromGauge(
        address pool,
        address[] calldata tokens
    ) external whenNotPaused {
        require(msg.sender == tokenForPool[pool], "!neadPool");
        address gauge = gaugeForPool[pool];
        IGauge(gauge).getReward(address(this), tokens);
        unchecked {
            for (uint i; i < tokens.length; ++i) {
                uint bal = IERC20Upgradeable(tokens[i]).balanceOf(
                    address(this)
                ) - unclaimedFees[tokens[i]];
                if (bal > 0) {
                    uint fee = (bal * platformFee) / 1e18;
                    bal -= fee;
                    unclaimedFees[tokens[i]] += fee;
                    IERC20Upgradeable(tokens[i]).transfer(msg.sender, bal);
                }
            }
        }
    }

    function earned(
        address pool,
        address token
    ) external view returns (uint rewards) {
        address gauge = gaugeForPool[pool];
        rewards = IGauge(gauge).earned(token, address(this));
        unchecked {
            rewards -= (rewards * platformFee) / 1e18;
        }
    }

    function poke(address token) external {
        require(msg.sender == feeHandler);
        uint amount = unclaimedFees[token];
        unclaimedFees[token] = 0;
        IERC20Upgradeable(token).transfer(feeHandler, amount);
    }

    function vote(
        address[] memory pools,
        uint[] memory weights
    ) external onlyRole(VOTER_ROLE) {
        voter.vote(tokenID, pools, weights);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
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

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}
