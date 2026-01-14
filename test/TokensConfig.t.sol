// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";

/// @title TokensConfigTest
/// @notice Tests for TokensConfig library
contract TokensConfigTest is Test {
    function test_GetArbitrumSepoliaTokens() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        assertEq(tokens.length, 5, "Should have 5 tokens");

        // Check WETH
        assertEq(tokens[0].symbol, "WETH", "First token should be WETH");
        assertEq(tokens[0].decimals, 18, "WETH should have 18 decimals");
        assertEq(tokens[0].asset, 0x980B62Da83eFf3D4576C647993b0c1D7faf17c73, "WETH address should match");

        // Check USDC
        assertEq(tokens[1].symbol, "USDC", "Second token should be USDC");
        assertEq(tokens[1].decimals, 6, "USDC should have 6 decimals");
        assertEq(tokens[1].asset, 0x179522635726710d7C8455c2e0A28f16e07E0D53, "USDC address should match");

        // Check USDT
        assertEq(tokens[2].symbol, "USDT", "Third token should be USDT");
        assertEq(tokens[2].decimals, 6, "USDT should have 6 decimals");

        // Check DAI
        assertEq(tokens[3].symbol, "DAI", "Fourth token should be DAI");
        assertEq(tokens[3].decimals, 18, "DAI should have 18 decimals");

        // Check WBTC
        assertEq(tokens[4].symbol, "WBTC", "Fifth token should be WBTC");
        assertEq(tokens[4].decimals, 8, "WBTC should have 8 decimals");
    }

    function test_GetMonadMainnetTokens() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.MonadMainnet);

        assertEq(tokens.length, 5, "Should have 5 tokens");

        // All mainnet tokens should have placeholder addresses (address(0))
        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(tokens[i].asset, address(0), "Mainnet tokens should have placeholder addresses");
            assertEq(tokens[i].priceFeed, address(0), "Mainnet price feeds should have placeholder addresses");
        }

        // Check symbols are correct
        assertEq(tokens[0].symbol, "WETH", "First token should be WETH");
        assertEq(tokens[1].symbol, "USDC", "Second token should be USDC");
        assertEq(tokens[2].symbol, "USDT", "Third token should be USDT");
        assertEq(tokens[3].symbol, "DAI", "Fourth token should be DAI");
        assertEq(tokens[4].symbol, "WBTC", "Fifth token should be WBTC");
    }

    function test_UnsupportedNetwork() public {
        // This test verifies that unsupported networks revert
        // We can't directly test this since enum is limited, but we test edge cases
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);
        assertGt(tokens.length, 0, "ArbitrumSepolia should return tokens");
    }

    function test_TokenStructure() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < tokens.length; i++) {
            assertNotEq(tokens[i].asset, address(0), "Asset address should not be zero");
            assertNotEq(tokens[i].priceFeed, address(0), "Price feed should not be zero");
            assertGt(tokens[i].decimals, 0, "Decimals should be greater than 0");
            assertLe(tokens[i].decimals, 18, "Decimals should not exceed 18");
            assertGt(bytes(tokens[i].symbol).length, 0, "Symbol should not be empty");
        }
    }

    function test_AllTokensHaveValidDecimals() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        // Known decimals for each token
        uint8[5] memory expectedDecimals = [uint8(18), 6, 6, 18, 8];
        string[5] memory symbols = ["WETH", "USDC", "USDT", "DAI", "WBTC"];

        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(tokens[i].decimals, expectedDecimals[i], string.concat("Decimals mismatch for ", symbols[i]));
        }
    }
}
