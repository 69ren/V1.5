// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/SoliSnek/IRouter.sol";
import "./interfaces/SoliSnek/IFactory.sol";
import "./interfaces/SoliSnek/IPair.sol";
import "./interfaces/IPoolRouter.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Swaps bribe/fee tokens to weth. Loosely based on Tarot optiswap. All swaps are made through ramses.
// it is now also a rudimentary zapper XD
contract bribeSwappoor is
    Initializable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant PROXY_ADMIN_ROLE = keccak256("PROXY_ADMIN");
/**
0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
0xAAA20D08e59F6561f242b08513D36266C5A29415
0x1542D005D7b73c53a75D4Cd98a1a6bF3DC27842B
0x1E50482e9185D9DAC418768D14b2F2AC2b4DAF39
0xAAA6C1E32C55A7Bfa8066A6FAE9b42650F262418
0x40301951Af3f80b8C1744ca77E55111dd3c1dba1
0x1863736c768f232189F95428b5ed9A51B0eCcAe5
 */
    // Setting all these as constants because they are unlikely to change
    address public weth;
    IFactory factory;
    address neadSnekWeth;
    address snekWeth;
    address snek;
    address neadSnek;
    IPoolRouter poolRouter;
    uint public targetRatio;
    uint public priceBasis;
    address public proxyAdmin;

    // token -> bridge token.
    mapping(address => address) tokenBridge;
    mapping(address => mapping(address => bool)) checkStable;
    // if token is tax token ffs...
    mapping(address => bool) isTax;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin,
        address setter,
        address _proxyAdmin,
        address _weth,
        IFactory poolFactory, // solisnek pool factory
        address _neadSnekWeth,
        address _snek,
        address _neadSnek,
        IPoolRouter _poolRouter
    ) external initializer {
        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(SETTER_ROLE, setter);
        _grantRole(PROXY_ADMIN_ROLE, _proxyAdmin);
        _setRoleAdmin(PROXY_ADMIN_ROLE, PROXY_ADMIN_ROLE);
        proxyAdmin = _proxyAdmin;

        weth = _weth;
        factory = poolFactory;
        neadSnekWeth = _neadSnekWeth;
        snek = _snek;
        neadSnek = _neadSnek;
        poolRouter = _poolRouter;
    }

    // @notice checks if neadSnek in or close to peg
    // @dev using the built in twap price feeds from baseV1Pair.
    function priceOutOfSync() public view returns (bool state) {
        // get current twap price of 100 neadSnek in weth
        uint priceInWeth = IPair(neadSnekWeth).current(neadSnek, priceBasis);
        // get current twap of priceInWeth in snek
        uint priceInSnek = IPair(snekWeth).current(weth, priceInWeth);
        state = priceInSnek >= targetRatio ? false : true;
    }

    function setTargetRatio(uint ratio) external onlyRole(SETTER_ROLE) {
        targetRatio = ratio;
    }

    function setBasis(uint amount) external onlyRole(SETTER_ROLE) {
        priceBasis = amount;
    }

    function getBridgeToken(address _token) public view returns (address) {
        if (tokenBridge[_token] == address(0)) {
            return weth;
        }
        return tokenBridge[_token];
    }

    function addBridgeToken(
        address token,
        address bridge,
        bool stable
    ) external onlyRole(SETTER_ROLE) {
        require(token != weth, "Nope");
        tokenBridge[token] = bridge;
        checkStable[token][bridge] = stable;
    }

    function addBridgeTokenBulk(
        address[] calldata token,
        address[] calldata bridge,
        bool[] calldata stable
    ) external onlyRole(SETTER_ROLE) {
        for (uint i; i < token.length; ++i) {
            require(token[i] != weth, "Nope");
            tokenBridge[token[i]] = bridge[i];
            checkStable[token[i]][bridge[i]] = stable[i];
        }
    }

    function addTaxToken(address token) external onlyRole(SETTER_ROLE) {
        isTax[token] = true;
    }

    function removeBridge(
        address token,
        address bridge
    ) external onlyRole(SETTER_ROLE) {
        require(token != weth);
        delete tokenBridge[token];
        delete checkStable[token][bridge];
    }

    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "BaseV1Router: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "BaseV1Router: ZERO_ADDRESS");
    }

    function _pairFor(
        address tokenA,
        address tokenB,
        bool stable
    ) internal view returns (address pair) {
        pair = factory.getPair(tokenA, tokenB, stable);
    }

    function getAmountOut(
        uint amountA,
        bool stable,
        uint reserve0,
        uint reserve1,
        uint decimals0,
        uint decimals1
    ) internal pure returns (uint) {
        uint amountB;
        // gas savings, soliSnek pair contract would revert anyway if amountOut under/overflows
        unchecked {
            if (!stable) {
                amountB = (amountA * reserve1) / (reserve0 * 10000 + amountA);
            } else {
                amountA = amountA / 10000;
                uint xy = _k(reserve0, reserve1, decimals0, decimals1);
                amountA = (amountA * 10 ** 18) / decimals0;
                uint y = ((reserve1 * 10 ** 18) / decimals1) -
                    getY(
                        amountA + ((reserve0 * 10 ** 18) / decimals0),
                        xy,
                        reserve1
                    );
                amountB = (y * decimals1) / 10 ** 18;
            }
        }
        return amountB;
    }

    function getMetadata(
        address tokenA,
        address tokenB,
        address pair
    )
        internal
        view
        returns (uint decimalsA, uint decimalsB, uint reserveA, uint reserveB)
    {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (
            uint decimals0,
            uint decimals1,
            uint reserve0,
            uint reserve1,
            ,
            ,

        ) = IPair(pair).metadata();
        (decimalsA, decimalsB, reserveA, reserveB) = tokenA == token0
            ? (decimals0, decimals1, reserve0, reserve1)
            : (decimals1, decimals0, reserve1, reserve0);
    }

    /**
     * @notice approve lpDepositor to spend neadSnek/weth lp
     */
    function approveDepositor() external {
        IERC20Upgradeable(neadSnekWeth).approve(
            address(poolRouter),
            type(uint).max
        );
    }

    /*
     * @notice zaps weth or neadSnek to neadSnek/weth lp only
     */
    function zapIn(bool isWeth, uint amountA, address to) external {
        address tokenA;
        address tokenB;
        (tokenA, tokenB) = isWeth ? (weth, neadSnek) : (neadSnek, weth);

        IERC20Upgradeable(tokenA).transferFrom(
            msg.sender,
            address(this),
            amountA
        );
        (uint amountB, uint swapAmount) = _swapToLp(
            tokenA,
            tokenB,
            neadSnekWeth,
            amountA
        );

        IERC20Upgradeable(tokenA).transfer(neadSnekWeth, amountA - swapAmount);
        IERC20Upgradeable(tokenB).transfer(neadSnekWeth, amountB);
        uint liquidity = IPair(neadSnekWeth).mint(address(this));
        poolRouter.deposit(neadSnekWeth, liquidity);
        IERC20Upgradeable(poolRouter.tokenForPool(neadSnekWeth)).transfer(
            to,
            liquidity
        );
    }

    // @notice separate swap function specifically for zap() _swap is not compatible
    function _swapToLp(
        address tokenA,
        address tokenB,
        address pair,
        uint amount
    ) internal returns (uint, uint) {
        uint fee = factory.pairFee(pair) * 10000;
        (, , uint reserve0, uint reserve1) = getMetadata(tokenA, tokenB, pair);
        uint swapAmount = _calcSwap(reserve0, amount, fee);

        fee = 10000 - (fee / 10000);
        amount = swapAmount * fee;
        uint amountB = (amount * reserve1) / (reserve0 * 10000 + amount);

        IERC20Upgradeable(tokenA).transfer(pair, swapAmount);

        if (tokenA < tokenB) {
            IPair(pair).swap(0, amountB, address(this), "");
        } else {
            IPair(pair).swap(amountB, 0, address(this), "");
        }
        return (amountB, swapAmount);
    }

    function _swap(
        address tokenA,
        address tokenB,
        uint amountA,
        bool stable
    ) internal returns (uint) {
        address pair = _pairFor(tokenA, tokenB, stable);
        uint fee = factory.pairFee(pair);
        if (fee == 0) {
            fee = factory.getFee(stable);
        }
        fee *= 10000;
        (
            uint decimals0,
            uint decimals1,
            uint reserve0,
            uint reserve1
        ) = getMetadata(tokenA, tokenB, pair);
        unchecked {
            fee = 10000 - (fee / 10000);
        }

        amountA = IERC20Upgradeable(tokenA).balanceOf(address(this));

        IERC20Upgradeable(tokenA).transfer(pair, amountA);
        uint amountOut;
        amountOut = getAmountOut(
            amountA * fee,
            stable,
            reserve0,
            reserve1,
            decimals0,
            decimals1
        );
        // honestly ffs ppl shouldnt have to go through this, i hate external calls
        if (isTax[tokenA]) {
            uint pairBal = IERC20Upgradeable(tokenA).balanceOf(pair);
            amountOut = getAmountOut(
                (pairBal - reserve0) * fee,
                stable,
                reserve0,
                reserve1,
                decimals0,
                decimals1
            );
        }

        if (tokenA < tokenB) {
            IPair(pair).swap(0, amountOut, address(this), "");
        } else {
            IPair(pair).swap(amountOut, 0, address(this), "");
        }
        return (amountOut);
    }

    function swapOptimal(
        address tokenA,
        address tokenB,
        uint amount
    ) internal returns (uint) {
        address bridge;
        bool stable;
        if (tokenA == tokenB) {
            return amount;
        }
        bridge = getBridgeToken(tokenA);
        if (bridge == tokenB) {
            stable = checkStable[tokenA][bridge];
            return _swap(tokenA, tokenB, amount, stable);
        }
        address nextBridge = getBridgeToken(tokenB);
        if (tokenA == nextBridge) {
            stable = checkStable[tokenA][nextBridge];
            return _swap(tokenA, tokenB, amount, stable);
        }
        uint bridgeAmountOut;
        if (nextBridge != tokenA) {
            stable = checkStable[tokenA][bridge];
            bridgeAmountOut = _swap(tokenA, bridge, amount, stable);
        } else {
            bridgeAmountOut = amount;
        }
        if (bridge == nextBridge) {
            stable = checkStable[nextBridge][tokenB];
            return _swap(bridge, tokenB, bridgeAmountOut, stable);
        } else if (nextBridge == tokenB) {
            return swapOptimal(bridge, tokenB, bridgeAmountOut);
        } else {
            stable = checkStable[bridge][nextBridge];
            uint nextBridgeAmount = swapOptimal(
                bridge,
                nextBridge,
                bridgeAmountOut
            );
            stable = checkStable[nextBridge][tokenB];
            return _swap(nextBridge, tokenB, nextBridgeAmount, stable);
        }
    }

    function swapTokens(
        address tokenA,
        address tokenB,
        uint amount
    ) external returns (uint) {
        IERC20Upgradeable(tokenA).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        uint amountOut = swapOptimal(tokenA, tokenB, amount);
        uint bal = IERC20Upgradeable(tokenB).balanceOf(address(this));
        IERC20Upgradeable(tokenB).transfer(msg.sender, bal);
        amountOut = (amountOut * 900) / 1000;
        require(bal >= amountOut, "slippage");
        return bal;
    }

    function _calcSwap(
        uint reserve0,
        uint amountA,
        uint fee
    ) internal pure returns (uint) {
        uint x = 20000 - (fee / 10000);
        uint y = (4 * (10000 - (fee / 10000)) * 10000);
        uint z = 2 * (10000 - (fee / 10000));
        return
            (MathUpgradeable.sqrt(reserve0 * (x * x * reserve0 + amountA * y)) -
                reserve0 *
                x) / z;
    }

    // Doing all calculations locally instead of calling router.

    // k = xy(x^2 + y^2)
    function _k(
        uint x,
        uint y,
        uint decimals0,
        uint decimals1
    ) internal pure returns (uint) {
        unchecked {
            uint _x = (x * 10 ** 18) / decimals0;
            uint _y = (y * 10 ** 18) / decimals1;
            uint _a = (_x * _y) / 10 ** 18;
            uint _b = ((_x * _x) + (_y * _y)) / 10 ** 18;
            return (_a * _b) / 10 ** 18;
        }
    }

    function getY(uint x0, uint xy, uint y) internal pure returns (uint) {
        unchecked {
            for (uint i = 0; i < 255; ++i) {
                uint y_prev = y;
                uint k = _f(x0, y);
                if (k < xy) {
                    uint dy = ((xy - k) * 10 ** 18) / _d(x0, y);
                    y = y + dy;
                } else {
                    uint dy = ((k - xy) * 10 ** 18) / _d(x0, y);
                    y = y - dy;
                }
                if (y > y_prev) {
                    if (y - y_prev <= 1) {
                        return y;
                    }
                } else {
                    if (y_prev - y <= 1) {
                        return y;
                    }
                }
            }
            return y;
        }
    }

    function _f(uint x0, uint y) internal pure returns (uint) {
        unchecked {
            uint x3 = (x0 * x0 * x0) / 10 ** 36;
            uint y3 = (y * y * y) / 10 ** 36;
            uint a = (x0 * y3) / 10 ** 18;
            uint b = (x3 * y) / 10 ** 18;
            return a + b;
        }
    }

    function _d(uint x0, uint y) internal pure returns (uint) {
        unchecked {
            uint y2 = y * y;
            uint x3 = (x0 * x0 * x0) / 10 ** 36;
            uint a = 3 * x0 * y2;
            return (a / 10 ** 36) + x3;
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

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}
