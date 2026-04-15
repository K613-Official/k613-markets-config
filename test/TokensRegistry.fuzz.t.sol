// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {TokensRegistry} from "../src/config/TokensRegistry.sol";

/// @title TokensRegistryFuzzTest
/// @notice Property-based tests around `TokensRegistry` mutations.
contract TokensRegistryFuzzTest is Test {
    TokensRegistry internal reg;
    address internal admin = address(0xAD01);

    uint256 internal constant SEEDED = 11;

    function setUp() public {
        reg = new TokensRegistry(admin);
    }

    function _isSeeded(address asset) internal view returns (bool) {
        TokensConfig.Token[] memory all = reg.getTokens();
        for (uint256 i = 0; i < SEEDED; i++) {
            if (all[i].asset == asset) return true;
        }
        return false;
    }

    /// @dev `addToken` appends, increments length by 1, and preserves indices of prior rows.
    function testFuzz_AddToken_Appends(address asset, address feed, uint8 dec) public {
        vm.assume(asset != address(0) && feed != address(0));
        vm.assume(!_isSeeded(asset));

        uint256 lenBefore = reg.tokenCount();
        TokensConfig.Token memory row = TokensConfig.Token({asset: asset, priceFeed: feed, decimals: dec, symbol: "FZ"});

        vm.prank(admin);
        reg.addToken(row);

        assertEq(reg.tokenCount(), lenBefore + 1);
        TokensConfig.Token[] memory all = reg.getTokens();
        assertEq(all[lenBefore].asset, asset);
        assertEq(all[lenBefore].priceFeed, feed);
    }

    /// @dev Adding the same asset twice must revert with `AssetAlreadyListed`.
    function testFuzz_AddToken_DuplicateReverts(address asset, address feed) public {
        vm.assume(asset != address(0) && feed != address(0));
        vm.assume(!_isSeeded(asset));

        TokensConfig.Token memory row = TokensConfig.Token({asset: asset, priceFeed: feed, decimals: 18, symbol: "FZ"});

        vm.prank(admin);
        reg.addToken(row);

        vm.prank(admin);
        vm.expectRevert(TokensRegistry.AssetAlreadyListed.selector);
        reg.addToken(row);
    }

    /// @dev Any non-admin caller is rejected for all mutating methods.
    function testFuzz_OnlyAdmin(address caller) public {
        vm.assume(caller != admin);
        TokensConfig.Token memory row =
            TokensConfig.Token({asset: address(0xC0DE), priceFeed: address(0xFEED), decimals: 18, symbol: "X"});

        vm.prank(caller);
        vm.expectRevert(TokensRegistry.Unauthorized.selector);
        reg.addToken(row);

        vm.prank(caller);
        vm.expectRevert(TokensRegistry.Unauthorized.selector);
        reg.removeTokenByAsset(address(0xC0DE));

        vm.prank(caller);
        vm.expectRevert(TokensRegistry.Unauthorized.selector);
        reg.removeTokenByIndex(0);

        vm.prank(caller);
        vm.expectRevert(TokensRegistry.Unauthorized.selector);
        reg.updateToken(address(0xC0DE), row);
    }

    /// @dev Swap-and-pop invariant: after removing any index, length shrinks by 1 and the row at
    ///      `index` is either the previous last row (if index != last) or gone.
    function testFuzz_RemoveByIndex_SwapPop(uint256 idx) public {
        uint256 n = reg.tokenCount();
        idx = bound(idx, 0, n - 1);

        TokensConfig.Token[] memory before = reg.getTokens();
        address removedAsset = before[idx].asset;
        address lastAsset = before[n - 1].asset;

        vm.prank(admin);
        reg.removeTokenByIndex(idx);

        assertEq(reg.tokenCount(), n - 1);
        TokensConfig.Token[] memory after_ = reg.getTokens();

        if (idx != n - 1) {
            // The moved tail should now sit at `idx`.
            assertEq(after_[idx].asset, lastAsset);
        }

        // The removed asset must no longer be findable at its old position.
        for (uint256 i = 0; i < after_.length; i++) {
            if (after_[i].asset == removedAsset) {
                // Only possible if the removed asset was also the last asset (trivial pop).
                assertEq(removedAsset, lastAsset);
                return;
            }
        }
    }

    /// @dev `removeTokenByIndex` must revert for any out-of-range index.
    function testFuzz_RemoveByIndex_OutOfRangeReverts(uint256 idx) public {
        idx = bound(idx, reg.tokenCount(), type(uint256).max);
        vm.prank(admin);
        vm.expectRevert(TokensRegistry.InvalidTokenIndex.selector);
        reg.removeTokenByIndex(idx);
    }

    /// @dev `removeTokenByAsset` for any non-seeded, non-zero address must revert as `AssetNotListed`.
    function testFuzz_RemoveByAsset_NotListedReverts(address asset) public {
        vm.assume(asset != address(0));
        vm.assume(!_isSeeded(asset));
        vm.prank(admin);
        vm.expectRevert(TokensRegistry.AssetNotListed.selector);
        reg.removeTokenByAsset(asset);
    }
}
