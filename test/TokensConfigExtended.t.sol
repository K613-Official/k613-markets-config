// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";

/// @title TokensConfigExtendedTest
/// @notice Extended tests to improve branch coverage
contract TokensConfigExtendedTest is Test {
    function test_TokensConfigArbitrumSepoliaBranch() public view {
        // Test ArbitrumSepolia branch
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);
        assertEq(tokens.length, 5, "ArbitrumSepolia should return 5 tokens");
    }

    function test_TokensConfigMonadMainnetBranch() public view {
        // Test MonadMainnet branch
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.MonadMainnet);
        assertEq(tokens.length, 5, "MonadMainnet should return 5 tokens");
    }

    function test_ArbitrumSepoliaTokensHaveCorrectStructure() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        // Verify all tokens have correct structure
        for (uint256 i = 0; i < tokens.length; i++) {
            assertNotEq(tokens[i].asset, address(0), "Asset should not be zero");
            assertNotEq(tokens[i].priceFeed, address(0), "Price feed should not be zero");
            assertGt(tokens[i].decimals, 0, "Decimals should be greater than 0");
            assertGt(bytes(tokens[i].symbol).length, 0, "Symbol should not be empty");
        }
    }

    function test_MonadMainnetTokensHavePlaceholderStructure() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.MonadMainnet);

        // Verify all tokens have placeholder structure (5 tokens with zero addresses)
        assertEq(tokens.length, 5, "MonadMainnet should return 5 placeholder tokens");

        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(tokens[i].asset, address(0), "Asset should be placeholder");
            assertEq(tokens[i].priceFeed, address(0), "Price feed should be placeholder");
            assertGt(tokens[i].decimals, 0, "Decimals should still be set");
            assertGt(bytes(tokens[i].symbol).length, 0, "Symbol should still be set");
        }
    }

    function test_TokenSymbolsMatchExpected() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        string[5] memory expectedSymbols = ["WETH", "USDC", "USDT", "DAI", "BTC"];

        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(
                keccak256(bytes(tokens[i].symbol)),
                keccak256(bytes(expectedSymbols[i])),
                string.concat("Symbol should match for index ", vm.toString(i))
            );
        }
    }

    function test_TokenDecimalsMatchExpected() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        uint8[5] memory expectedDecimals = [18, 6, 6, 18, 8];

        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(
                tokens[i].decimals,
                expectedDecimals[i],
                string.concat("Decimals should match for index ", vm.toString(i))
            );
        }
    }

    function test_BothNetworksReturnSameSymbols() public {
        TokensConfig.Token[] memory arbitrumTokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);
        TokensConfig.Token[] memory monadTokens = TokensConfig.getTokens(TokensConfig.Network.MonadMainnet);

        assertEq(arbitrumTokens.length, monadTokens.length, "Both networks should have same token count");

        for (uint256 i = 0; i < arbitrumTokens.length; i++) {
            assertEq(
                keccak256(bytes(arbitrumTokens[i].symbol)),
                keccak256(bytes(monadTokens[i].symbol)),
                "Symbols should match between networks"
            );
            assertEq(arbitrumTokens[i].decimals, monadTokens[i].decimals, "Decimals should match between networks");
        }
    }
}
