// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Libraries/Proxy.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract EnneadProxyDeployer is Initializable, AccessControlEnumerableUpgradeable {
    address[] public deployedProxies;
    address public proxyAdmin;

    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");

    function initialize(
        address _proxyAdmin,
        address admin,
        address deployer
    ) public initializer {
        __AccessControlEnumerable_init();

        proxyAdmin = _proxyAdmin;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DEPLOYER_ROLE, deployer);
    }

     function deployedProxiesLength() public view returns (uint256) {
        return deployedProxies.length;
    }

    function deployProxy(uint salt) public onlyRole(DEPLOYER_ROLE) returns (address) {
        bytes32 _salt = bytes32(salt);
        EnneadProxy proxy = new EnneadProxy{salt: _salt}();
        deployedProxies.push(address(proxy));
        return (address(proxy));
    }

    function deployMany(uint[] calldata salt) external onlyRole(DEPLOYER_ROLE) returns (address[] memory proxies) {
        uint len = salt.length;
        proxies = new address[](len);
        for(uint i; i < len;) {
            proxies[i] = deployProxy(salt[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getDeployedProxies() external view returns (address[] memory) {
        return deployedProxies;
    }
    

}
