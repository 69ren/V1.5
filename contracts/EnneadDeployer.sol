// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Libraries/Proxy.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract EnneadProxyDeployer is
    Initializable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable
{
    address[] public deployedProxies;
    address public proxyAdmin;

    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    bytes32 public constant PROXY_ADMIN_ROLE = keccak256("PROXY_ADMIN");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address _proxyAdmin,
        address admin,
        address deployer
    ) public initializer {
        __AccessControlEnumerable_init();

        proxyAdmin = _proxyAdmin;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DEPLOYER_ROLE, deployer);
        _grantRole(PROXY_ADMIN_ROLE, _proxyAdmin);
        _setRoleAdmin(PROXY_ADMIN_ROLE, PROXY_ADMIN_ROLE);
    }

    function deployedProxiesLength() public view returns (uint256) {
        return deployedProxies.length;
    }

    function deployProxy(
        uint salt
    ) public onlyRole(DEPLOYER_ROLE) returns (address) {
        bytes32 _salt = bytes32(salt);
        EnneadProxy proxy = new EnneadProxy{salt: _salt}();
        deployedProxies.push(address(proxy));
        return (address(proxy));
    }

    function deployMany(
        uint[] calldata salt
    ) external onlyRole(DEPLOYER_ROLE) returns (address[] memory proxies) {
        uint len = salt.length;
        proxies = new address[](len);
        for (uint i; i < len; ) {
            proxies[i] = deployProxy(salt[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getDeployedProxies() external view returns (address[] memory) {
        return deployedProxies;
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
