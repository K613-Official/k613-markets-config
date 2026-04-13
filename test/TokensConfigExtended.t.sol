// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {RiskParametersFixture} from "./RiskParametersFixture.sol";
import {IRiskParametersConfig} from "../src/config/interface/IRiskParametersConfig.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";

/// @title TokensConfigExtendedTest
/// @notice Extended tests to improve branch coverage
contract TokensConfigExtendedTest is RiskParametersFixture {
    function test_TokensConfigArbitrumSepoliaBranch() public view {
        // Test ArbitrumSepolia branch
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);
        assertEq(tokens.length, 5, "ArbitrumSepolia should return 5 tokens");
    }

    function test_TokensConfigMonadMainnetBranch() public view {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.MonadMainnet);
        assertEq(tokens.length, 11, "MonadMainnet should return 11 tokens");
    }

    function test_ArbitrumSepoliaTokensHaveCorrectStructure() public {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        // Verify all tokens have correct structure
        for (uint256 i = 0; i < tokens.length; i++) {
            assertNotEq(tokens[i].asset, address(0), "Asset should not be zero");
            assertNotEq(tokens[i].priceFeed, address(0), "Price feed should not be zero");
            assertGt(tokens[i].decimals, 0, "Decimals should be greater than 0");
            assertGt(bytes(tokens[i].symbol).length, 0, "Symbol should not be empty");
        }
    }

    function test_MonadMainnetTokensHaveDeployedStructure() public {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.MonadMainnet);

        assertEq(tokens.length, 11);

        for (uint256 i = 0; i < tokens.length; i++) {
            assertNotEq(tokens[i].asset, address(0), "Asset should be set");
            assertNotEq(tokens[i].priceFeed, address(0), "Price feed should be set");
            assertGt(tokens[i].decimals, 0, "Decimals should be set");
            assertGt(bytes(tokens[i].symbol).length, 0, "Symbol should be set");
        }
    }

    function test_TokenSymbolsMatchExpected() public {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

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
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        uint8[5] memory expectedDecimals = [18, 6, 6, 18, 8];

        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(
                tokens[i].decimals,
                expectedDecimals[i],
                string.concat("Decimals should match for index ", vm.toString(i))
            );
        }
    }

    function test_SharedSymbolsMatchAcrossNetworks() public view {
        TokensConfig.Token[] memory arbitrumTokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);
        TokensConfig.Token[] memory monadTokens = tokensRegistry.getTokens(TokensConfig.Network.MonadMainnet);
        IRiskParametersConfig.RiskParams[] memory arbitrumParams =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.ArbitrumSepolia);
        IRiskParametersConfig.RiskParams[] memory monadParams =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.MonadMainnet);

        assertEq(arbitrumTokens.length, 5);
        assertEq(monadTokens.length, 11);

        for (uint256 i = 0; i < arbitrumTokens.length; i++) {
            bytes32 sym = keccak256(bytes(arbitrumTokens[i].symbol));
            for (uint256 j = 0; j < monadTokens.length; j++) {
                if (keccak256(bytes(monadTokens[j].symbol)) != sym) {
                    continue;
                }
                assertEq(arbitrumTokens[i].decimals, monadTokens[j].decimals);
                assertEq(arbitrumParams[i].ltv, monadParams[j].ltv);
                assertEq(arbitrumParams[i].liquidationThreshold, monadParams[j].liquidationThreshold);
                assertEq(arbitrumParams[i].liquidationBonus, monadParams[j].liquidationBonus);
                assertEq(arbitrumParams[i].reserveFactor, monadParams[j].reserveFactor);
                break;
            }
        }
    }
}
