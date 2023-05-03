// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// i should probably write my own implementation of erc4626...
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./Libraries/ERC4626.sol";
import "./interfaces/IMultiRewards.sol";
import "hardhat/console.sol";

contract elmoSOLID is ERC4626, PausableUpgradeable, AccessControlEnumerableUpgradeable, UUPSUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant PROXY_ADMIN_ROLE = keccak256("PROXY_ADMIN");

    IMultiRewards public multi;
    address public proxyAdmin;

    function initialize(
        IERC20Upgradeable _token,
        IMultiRewards _multi,
        address admin,
        address setter,
        address pauser,
        address _proxyAdmin
    ) public initializer {
        __ERC4626_init(_token);
        ERC20Init("elmo", "fff"); //placeholder name
        __Pausable_init();
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(SETTER_ROLE, setter);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(PROXY_ADMIN_ROLE, _proxyAdmin);
        _setRoleAdmin(PROXY_ADMIN_ROLE, PROXY_ADMIN_ROLE);
        proxyAdmin = _proxyAdmin;
        multi = _multi;

    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override {
        _asset.transferFrom(caller, address(this), assets);
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
            require(allowance[owner][caller] >= shares, "Insufficient allowance");
            allowance[owner][caller] -= shares;
        }
        _burn(owner, shares);
        _asset.transfer(receiver, assets);
        multi.withdraw(receiver, shares);
        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(amount > 0, "Can't transfer 0!");

        
        balanceOf[from] -= amount;
        multi.withdraw(from, amount);
        
        unchecked {
            balanceOf[to] += amount;
        }
        multi.deposit(to, amount);

        emit Transfer(from, to, amount);
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
    
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(PROXY_ADMIN_ROLE) {}

    /// @dev grantRole already checks role, so no more additional checks are necessary
    function changeAdmin(address newAdmin) external {
        grantRole(PROXY_ADMIN_ROLE, newAdmin);
        renounceRole(PROXY_ADMIN_ROLE, proxyAdmin);
        proxyAdmin = newAdmin;
    }

}
