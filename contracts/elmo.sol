// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// i should probably write my own implementation of erc4626...
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./Libraries/ERC4626.sol";
import "./interfaces/IMultiRewards.sol";

contract elmoSOLID is
    ERC4626Upgradeable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");

    IMultiRewards public multi;

    function initialize(
        IERC20Upgradeable _token,
        address admin,
        address setter,
        address pauser
    ) public initializer {
        __ERC4626_init(_token);
        __ERC20_init("elmo", "fff"); //placeholder name
        __Pausable_init();
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(SETTER_ROLE, setter);
        _grantRole(PAUSER_ROLE, pauser);

        _pause();
    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override {
        SafeERC20Upgradeable.safeTransferFrom(
            _asset,
            caller,
            address(this),
            assets
        );
        _mint(receiver, shares);
        multi.deposit(receiver, shares);
        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _burn(owner, shares);
        SafeERC20Upgradeable.safeTransfer(_asset, receiver, assets);
        multi.withdraw(receiver, shares);
        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function setAddresses(address _multi) external onlyRole(SETTER_ROLE) {
        multi = IMultiRewards(_multi);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
