// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {TokensRegistry} from "../src/config/TokensRegistry.sol";

contract TokensRegistryTest is Test {
    TokensRegistry internal reg;
    address internal admin = address(0xAD01);
    address internal stranger = address(0xBEEF);

    address internal constant USDC_ASSET = 0x754704Bc059F8C67012fEd69BC8A327a5aafb603;

    function setUp() public {
        reg = new TokensRegistry(admin);
    }

    function test_ConstructorRevertsOnZeroAdmin() public {
        vm.expectRevert(TokensRegistry.InvalidAdmin.selector);
        new TokensRegistry(address(0));
    }

    function test_SetAdmin_TransfersAndEmits() public {
        vm.expectEmit(true, true, false, false);
        emit TokensRegistry.AdminUpdated(admin, stranger);
        vm.prank(admin);
        reg.setAdmin(stranger);
        assertEq(reg.admin(), stranger);
    }

    function test_SetAdmin_RevertUnauthorized() public {
        vm.prank(stranger);
        vm.expectRevert(TokensRegistry.Unauthorized.selector);
        reg.setAdmin(stranger);
    }

    function test_SetAdmin_RevertZero() public {
        vm.prank(admin);
        vm.expectRevert(TokensRegistry.InvalidAdmin.selector);
        reg.setAdmin(address(0));
    }

    function test_AddToken_Appends() public {
        TokensConfig.Token memory row =
            TokensConfig.Token({asset: address(0xC0DE), priceFeed: address(0xFEED), decimals: 18, symbol: "TST"});
        vm.prank(admin);
        reg.addToken(row);
        assertEq(reg.tokenCount(), 12);
        assertEq(reg.getTokens()[11].symbol, "TST");
    }

    function test_AddToken_RevertUnauthorized() public {
        TokensConfig.Token memory row =
            TokensConfig.Token({asset: address(0xC0DE), priceFeed: address(0xFEED), decimals: 18, symbol: "TST"});
        vm.prank(stranger);
        vm.expectRevert(TokensRegistry.Unauthorized.selector);
        reg.addToken(row);
    }

    function test_AddToken_RevertZeroAsset() public {
        TokensConfig.Token memory row =
            TokensConfig.Token({asset: address(0), priceFeed: address(1), decimals: 18, symbol: "X"});
        vm.prank(admin);
        vm.expectRevert(TokensRegistry.ZeroAsset.selector);
        reg.addToken(row);
    }

    function test_AddToken_RevertZeroFeed() public {
        TokensConfig.Token memory row =
            TokensConfig.Token({asset: address(1), priceFeed: address(0), decimals: 18, symbol: "X"});
        vm.prank(admin);
        vm.expectRevert(TokensRegistry.ZeroPriceFeed.selector);
        reg.addToken(row);
    }

    function test_AddToken_RevertDuplicate() public {
        TokensConfig.Token memory row =
            TokensConfig.Token({asset: USDC_ASSET, priceFeed: address(0x1111), decimals: 6, symbol: "USDC2"});
        vm.prank(admin);
        vm.expectRevert(TokensRegistry.AssetAlreadyListed.selector);
        reg.addToken(row);
    }

    function test_RemoveTokenByAsset_SwapPop() public {
        uint256 beforeCount = reg.tokenCount();
        vm.prank(admin);
        reg.removeTokenByAsset(USDC_ASSET);
        assertEq(reg.tokenCount(), beforeCount - 1);
    }

    function test_RemoveTokenByAsset_RevertZeroAsset() public {
        vm.prank(admin);
        vm.expectRevert(TokensRegistry.ZeroAsset.selector);
        reg.removeTokenByAsset(address(0));
    }

    function test_RemoveTokenByAsset_RevertNotListed() public {
        vm.prank(admin);
        vm.expectRevert(TokensRegistry.AssetNotListed.selector);
        reg.removeTokenByAsset(address(0xDEAD));
    }

    function test_RemoveTokenByIndex_RevertOutOfRange() public {
        uint256 outOfRange = reg.tokenCount();
        vm.expectRevert(TokensRegistry.InvalidTokenIndex.selector);
        vm.prank(admin);
        reg.removeTokenByIndex(outOfRange);
    }

    function test_RemoveTokenByIndex_RemovesFirst() public {
        vm.prank(admin);
        reg.removeTokenByIndex(0);
        assertEq(reg.tokenCount(), 10);
    }

    function test_UpdateToken_ReplacesRow() public {
        address newFeed = address(0xAAA001);
        TokensConfig.Token memory row =
            TokensConfig.Token({asset: USDC_ASSET, priceFeed: newFeed, decimals: 6, symbol: "USDC"});
        vm.prank(admin);
        reg.updateToken(USDC_ASSET, row);
        assertEq(reg.getTokens()[0].priceFeed, newFeed);
    }

    function test_UpdateToken_RevertNotListed() public {
        address missing = address(0xDeaD0001);
        TokensConfig.Token memory row =
            TokensConfig.Token({asset: missing, priceFeed: address(1), decimals: 18, symbol: "ZZ"});
        vm.prank(admin);
        vm.expectRevert(TokensRegistry.AssetNotListed.selector);
        reg.updateToken(missing, row);
    }

    function test_UpdateToken_RevertZeroAssetInRow() public {
        TokensConfig.Token memory row =
            TokensConfig.Token({asset: address(0), priceFeed: address(1), decimals: 18, symbol: "X"});
        vm.prank(admin);
        vm.expectRevert(TokensRegistry.ZeroAsset.selector);
        reg.updateToken(USDC_ASSET, row);
    }
}
