// SPDX-License-Identifier: MIT

/**
    @notice ERC4626 based on OpenZeppelin implementation.
    @dev minimal changes from default OZ
*/

pragma solidity 0.8.19;

import "./ERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


abstract contract ERC4626 is Initializable, BaseERC20 {
    using MathUpgradeable for uint256;

    IERC20Upgradeable internal _asset;

    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
     event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
 
    function __ERC4626_init(IERC20Upgradeable asset_) internal onlyInitializing {
        _asset = asset_;
    }

    function asset() public view virtual returns (address) {
        return address(_asset);
    }

    function totalAssets() public view virtual returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view virtual  returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    function convertToAssets(uint256 shares) public view virtual  returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    function maxDeposit(address) public view virtual returns (uint256) {
        return _isVaultHealthy() ? type(uint256).max : 0;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return _convertToAssets(balanceOf[owner], MathUpgradeable.Rounding.Down);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Up);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Up);
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    function deposit(uint256 assets, address receiver) public virtual returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(msg.sender, receiver, assets, shares);

        return shares;
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(msg.sender, receiver, assets, shares);

        return assets;
    }

    function withdraw(uint256 assets, address receiver, address owner) public virtual returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;
    }

    function _convertToShares(uint256 assets, MathUpgradeable.Rounding rounding) internal view virtual returns (uint256) {
        uint256 supply = totalSupply;
        return
            (assets == 0 || supply == 0)
                ? _initialConvertToShares(assets, rounding)
                : assets.mulDiv(supply, totalAssets(), rounding);
    }

   
    function _initialConvertToShares(
        uint256 assets,
        MathUpgradeable.Rounding /*rounding*/
    ) internal view virtual returns (uint256 shares) {
        return assets;
    }

   
    function _convertToAssets(uint256 shares, MathUpgradeable.Rounding rounding) internal view virtual returns (uint256) {
        uint256 supply = totalSupply;
        return
            (supply == 0) ? _initialConvertToAssets(shares, rounding) : shares.mulDiv(totalAssets(), supply, rounding);
    }

  
    function _initialConvertToAssets(
        uint256 shares,
        MathUpgradeable.Rounding /*rounding*/
    ) internal view virtual returns (uint256) {
        return shares;
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual {
        SafeERC20Upgradeable.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            require(allowance[owner][caller] >= shares, "Insufficient allowance");
            allowance[owner][caller] -= shares;
        }
        _burn(owner, shares);
        SafeERC20Upgradeable.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _isVaultHealthy() private view returns (bool) {
        return totalAssets() > 0 || totalSupply == 0;
    }

    uint256[49] private __gap;
}
