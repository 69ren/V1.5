// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/Ramses/IVoter.sol";
import "./interfaces/Ramses/IVotingEscrow.sol";
import "./interfaces/Ramses/IGauge.sol";
import "./interfaces/Ramses/IFeeDistributor.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract Booster is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    IVoter public voter;
    IVotingEscrow votingEscrow;

    // Ennead contracts
    address public veDepositor;
    uint public tokenID;
    address public feeHandler;
    address public poolRouter;

    address public ram;

    uint public platformFee; // mirrored from feeHandler to reduce external calls
    // pool -> gauge
    mapping(address => address) public gaugeForPool;
    // pool -> token
    mapping(address => address) public tokenForPool; // mirrored from poolRouter to save on external calls

    mapping(address => uint) public unclaimedFees;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        IVoter _voter,
        address _veDepositor,
        address admin,
        address pauser,
        address voterRole,
        address operator
    ) public initializer {
        __Pausable_init();
        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(VOTER_ROLE, voterRole);
        _grantRole(OPERATOR_ROLE, operator);

        voter = _voter;
        votingEscrow = IVotingEscrow(voter._ve());
        ram = voter.base();

        veDepositor = _veDepositor;
        votingEscrow.setApprovalForAll(_veDepositor, true);
    }

    function setAddresses(
        address _veDepositor,
        address _feeHandler,
        address _poolRouter
    ) external onlyRole(OPERATOR_ROLE) {
        if (_veDepositor != address(0)) {
            votingEscrow.setApprovalForAll(veDepositor, false);
            veDepositor = _veDepositor;
            votingEscrow.setApprovalForAll(veDepositor, true);
        }
        if (_feeHandler != address(0)) {
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

    function depositInGauge(address pool, uint amount) external whenNotPaused {
        require(msg.sender == tokenForPool[pool], "!neadPool");
        address gauge = gaugeForPool[pool];
        if (gauge == address(0)) {
            gauge = voter.gauges(pool);
            gaugeForPool[pool] = gauge;
            IERC20Upgradeable(pool).approve(gauge, type(uint).max);
        }
        IERC20Upgradeable(pool).transferFrom(msg.sender, address(this), amount);
        IGauge(gauge).deposit(amount, tokenID);
    }

    function withdrawFromGauge(
        address pool,
        uint amount
    ) external whenNotPaused {
        require(msg.sender == tokenForPool[pool], "!neadPool");
        address gauge = gaugeForPool[pool];
        IGauge(gauge).withdraw(amount);
        IERC20Upgradeable(pool).transfer(msg.sender, amount);
    }

    function getRewardFromGauge(
        address pool,
        address[] calldata tokens
    ) external whenNotPaused {
        require(msg.sender == tokenForPool[pool], "!neadPool");
        address gauge = gaugeForPool[pool];
        IGauge(gauge).getReward(address(this), tokens);

        uint len = tokens.length;
        for (uint i; i < len; ++i) {
            uint bal = IERC20Upgradeable(tokens[i]).balanceOf(address(this)) -
                unclaimedFees[tokens[i]];
            if (bal > 0) {
                uint fee = (bal * platformFee) / 1e18;
                unclaimedFees[tokens[i]] += fee;
                IERC20Upgradeable(tokens[i]).transfer(msg.sender, bal - fee);
            }
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
}
