// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./utils/MockERC20.sol";
import "./utils/SigUtils.sol";

contract PegTokenTest is Test {
    MockERC20 internal token;
    SigUtils internal sigUtils;
    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;
    address internal owner;
    address internal spender;

    function setUp() public {
        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;

        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);

        vm.startPrank(owner);
        token = new MockERC20();
        sigUtils = new SigUtils(token.DOMAIN_SEPARATOR());

        token.mint(1e18);
        vm.stopPrank();
    }

    function test_TransferOwnership() public {
        address newOwner = spender;

        assertEq(token.proposedOwner(), address(0));

        vm.prank(owner);
        token.pushOwnership(newOwner);

        assertEq(token.proposedOwner(), newOwner);

        vm.prank(newOwner);
        token.pullOwnership();

        assertEq(token.owner(), newOwner);
        assertEq(token.proposedOwner(), address(0));
    }

    function testRevert_InvalidOwner() public {
        address newOwner = spender;

        vm.expectRevert("Ownable: caller is not the owner");
        token.pushOwnership(newOwner);
    }

    function testRevert_InvalidProposedOwner() public {
        address newOwner = spender;

        vm.prank(owner);
        token.pushOwnership(newOwner);

        vm.expectRevert("Ownable: caller is not the proposed owner");
        token.pullOwnership();
    }

    function test_CancelProposedOwnership() public {
        address newOwner = spender;

        vm.prank(owner);
        token.pushOwnership(newOwner);

        assertEq(token.proposedOwner(), newOwner);

        vm.prank(owner);
        token.cancelProposedOwnership();

        assertEq(token.proposedOwner(), address(0));
    }

    function test_Mint() public {
        vm.prank(owner);
        token.mint(10e18);

        assertEq(token.balanceOf(owner), 11e18);
        assertEq(token.totalSupply(), 11e18);
    }

    function testRevert_InvalidMintOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        token.mint(10e18);
    }

    function test_Burn() public {
        vm.prank(owner);
        token.burn(1e18);

        assertEq(token.balanceOf(owner), 0);
        assertEq(token.totalSupply(), 0);
    }

    function testRevert_InvalidBurnOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        token.burn(1e18);
    }

    function testRevert_InvalidBurnAmount() public {
        vm.prank(owner);
        vm.expectRevert("ERC20: burn amount exceeds balance");
        token.burn(10e18);
    }

    function test_Pause() public {
        vm.prank(owner);
        token.pause();

        assertEq(token.paused(), true);

        vm.prank(owner);
        token.unpause();

        assertEq(token.paused(), false);
    }

    function test_ResumePause() public {
        vm.startPrank(owner);
        token.pause();
        token.unpause();

        token.approve(spender, 1e18);
        token.transfer(spender, 5e17);
        vm.stopPrank();

        vm.prank(spender);
        token.transferFrom(owner, spender, 5e17);
    }

    function testRevert_InvalidPauseOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        token.pause();
    }

    function testRevert_InvalidUnpauseOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        token.unpause();
    }

    function testRevert_PauseApprove() public {
        vm.prank(owner);
        token.pause();

        vm.expectRevert("Pausable: paused");
        token.approve(spender, 1e18);
    }

    function testRevert_PauseTransfer() public {
        vm.prank(owner);
        token.pause();

        vm.expectRevert("Pausable: paused");
        token.transfer(spender, 1e18);
    }

    function testRevert_PauseTransferFrom() public {
        vm.prank(owner);
        token.pause();

        vm.expectRevert("Pausable: paused");
        token.transferFrom(owner, spender, 1e18);
    }

    function test_Permit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: 1e18,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        token.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

        assertEq(token.allowance(owner, spender), 1e18);
        assertEq(token.nonces(owner), 1);
    }

    function testRevert_ExpiredPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: 1e18,
            nonce: token.nonces(owner),
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        vm.warp(1 days + 1 seconds); // fast forward one second past the deadline

        vm.expectRevert("ERC20Permit: expired deadline");
        token.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
    }

    function testRevert_InvalidSigner() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: 1e18,
            nonce: token.nonces(owner),
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(spenderPrivateKey, digest); // spender signs owner's approval

        vm.expectRevert("ERC20Permit: invalid signature");
        token.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
    }

    function testRevert_InvalidNonce() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: 1e18,
            nonce: 1, // owner nonce stored on-chain is 0
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        vm.expectRevert("ERC20Permit: invalid signature");
        token.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
    }

    function testRevert_SignatureReplay() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: 1e18,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        token.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

        vm.expectRevert("ERC20Permit: invalid signature");
        token.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
    }
    
    function test_TransferFromLimitedPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: 1e18,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        token.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

        vm.prank(spender);
        token.transferFrom(owner, spender, 1e18);

        assertEq(token.balanceOf(owner), 0);
        assertEq(token.balanceOf(spender), 1e18);
        assertEq(token.allowance(owner, spender), 0);
    }

    function test_TransferFromMaxPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: type(uint256).max,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        token.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

        vm.prank(spender);
        token.transferFrom(owner, spender, 1e18);

        assertEq(token.balanceOf(owner), 0);
        assertEq(token.balanceOf(spender), 1e18);
        assertEq(token.allowance(owner, spender), type(uint256).max);
    }

    function testFail_InvalidAllowance() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: 5e17, // approve only 0.5 tokens
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        token.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

        vm.prank(spender);
        token.transferFrom(owner, spender, 1e18); // attempt to transfer 1 token
    }

    function testFail_InvalidBalance() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: 2e18, // approve 2 tokens
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        token.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

        vm.prank(spender);
        token.transferFrom(owner, spender, 2e18); // attempt to transfer 2 tokens (owner only owns 1)
    }
}
