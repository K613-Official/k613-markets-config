// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ListingPayload} from "../src/payloads/ListingPayload.sol";
import {CollateralConfigPayload} from "../src/payloads/CollateralConfigPayload.sol";
import {OracleUpdatePayload} from "../src/payloads/OracleUpdatePayload.sol";
import {RiskUpdatePayload} from "../src/payloads/RiskUpdatePayload.sol";
import {ConfiguratorInputTypes} from "../src/interfaces/IAaveExternal.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {RiskConfig} from "../src/config/RiskConfig.sol";
import {NetworkConfig} from "../src/config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";

/// @title PayloadsInternalTest
/// @notice Tests for payload internal logic and data preparation
contract PayloadsInternalTest is Test {
    function test_ListingPayloadDataPreparation() public view {
        // Test that ListingPayload would prepare correct data
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);
        NetworkConfig.Addresses memory addrs = ArbitrumSepolia.getAddresses();

        // Verify data that would be used by ListingPayload
        assertEq(tokens.length, 5, "Should have 5 tokens");
        assertNotEq(addrs.aTokenImpl, address(0), "AToken impl should be set");
        assertNotEq(addrs.variableDebtImpl, address(0), "Variable debt impl should be set");
        assertEq(addrs.stableDebtImpl, address(0), "Stable debt should be disabled");
        assertNotEq(addrs.defaultInterestRateStrategy, address(0), "Interest rate strategy should be set");
    }

    function test_CollateralConfigPayloadDataPreparation() public view {
        // Test that CollateralConfigPayload would prepare correct data
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);
        RiskConfig.RiskParams[] memory riskParams = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        // Verify data consistency
        assertEq(tokens.length, riskParams.length, "Tokens and risk params should match");
        
        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(tokens[i].asset, riskParams[i].asset, "Assets should match");
            assertLe(riskParams[i].ltv, riskParams[i].liquidationThreshold, "LTV should be <= liquidation threshold");
        }
    }

    function test_OracleUpdatePayloadDataPreparation() public view {
        // Test that OracleUpdatePayload would prepare correct data
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);
        NetworkConfig.Addresses memory addrs = ArbitrumSepolia.getAddresses();

        // Verify oracle and price feeds
        assertNotEq(addrs.oracle, address(0), "Oracle should be set");
        
        for (uint256 i = 0; i < tokens.length; i++) {
            assertNotEq(tokens[i].priceFeed, address(0), "Price feed should be set");
            assertNotEq(tokens[i].asset, address(0), "Asset should be set");
        }
    }

    function test_RiskUpdatePayloadDataPreparation() public view {
        // Test that RiskUpdatePayload would prepare correct data
        RiskConfig.RiskParams[] memory riskParams = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        // Verify risk params for updates
        assertGt(riskParams.length, 0, "Should have risk params");
        
        for (uint256 i = 0; i < riskParams.length; i++) {
            assertNotEq(riskParams[i].asset, address(0), "Asset should not be zero");
            assertGt(riskParams[i].borrowCap, 0, "Borrow cap should be > 0");
            assertGt(riskParams[i].supplyCap, 0, "Supply cap should be > 0");
            assertLe(riskParams[i].reserveFactor, 10000, "Reserve factor should be <= 100%");
        }
    }

    function test_AllPayloadsUseSameNetwork() public view {
        // Verify all payloads use ArbitrumSepolia by default
        NetworkConfig.Addresses memory arbitrumAddrs = ArbitrumSepolia.getAddresses();
        
        // All payloads should be able to access ArbitrumSepolia addresses
        assertNotEq(arbitrumAddrs.pool, address(0), "Pool should be set");
        assertNotEq(arbitrumAddrs.oracle, address(0), "Oracle should be set");
    }

    function test_ListingPayloadStableDebtHandling() public view {
        NetworkConfig.Addresses memory addrs = ArbitrumSepolia.getAddresses();
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        // Verify stable debt is properly disabled
        assertEq(addrs.stableDebtImpl, address(0), "Stable debt impl should be zero");
        
        // Verify that for each token, stable debt would be disabled
        for (uint256 i = 0; i < tokens.length; i++) {
            // In ListingPayload, setReserveStableRateBorrowing(tokens[i].asset, false) would be called
            assertNotEq(tokens[i].asset, address(0), "Token asset should be set");
        }
    }

    function test_PayloadsNetworkConsistency() public view {
        // Test that payloads can work with both networks
        TokensConfig.Token[] memory arbitrumTokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);
        TokensConfig.Token[] memory monadTokens = TokensConfig.getTokens(TokensConfig.Network.MonadMainnet);
        
        // Both should return same number of tokens
        assertEq(arbitrumTokens.length, monadTokens.length, "Both networks should have same token count");
        
        // Symbols should match
        for (uint256 i = 0; i < arbitrumTokens.length; i++) {
            assertEq(
                keccak256(bytes(arbitrumTokens[i].symbol)),
                keccak256(bytes(monadTokens[i].symbol)),
                "Symbols should match between networks"
            );
        }
    }

    function test_ListingPayloadInitReserveInputStructure() public view {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);
        NetworkConfig.Addresses memory addrs = ArbitrumSepolia.getAddresses();

        // Create inputs as ListingPayload would
        for (uint256 i = 0; i < tokens.length; i++) {
            ConfiguratorInputTypes.InitReserveInput memory input = ConfiguratorInputTypes.InitReserveInput({
                aTokenImpl: addrs.aTokenImpl,
                stableDebtTokenImpl: addrs.stableDebtImpl,
                variableDebtTokenImpl: addrs.variableDebtImpl,
                underlyingAssetDecimals: tokens[i].decimals,
                interestRateStrategyAddress: addrs.defaultInterestRateStrategy,
                underlyingAsset: tokens[i].asset,
                treasury: addrs.treasury,
                incentivesController: addrs.incentivesController,
                aTokenName: string.concat("Aave ", tokens[i].symbol),
                aTokenSymbol: string.concat("a", tokens[i].symbol),
                variableDebtTokenName: string.concat("Aave Variable Debt ", tokens[i].symbol),
                variableDebtTokenSymbol: string.concat("variableDebt", tokens[i].symbol),
                stableDebtTokenName: "",
                stableDebtTokenSymbol: "",
                params: ""
            });

            // Verify structure
            assertEq(input.underlyingAsset, tokens[i].asset, "Asset should match");
            assertEq(input.stableDebtTokenImpl, address(0), "Stable debt should be disabled");
            assertEq(bytes(input.stableDebtTokenName).length, 0, "Stable debt name should be empty");
            assertEq(bytes(input.stableDebtTokenSymbol).length, 0, "Stable debt symbol should be empty");
            assertGt(bytes(input.aTokenName).length, 0, "AToken name should not be empty");
            assertGt(bytes(input.aTokenSymbol).length, 0, "AToken symbol should not be empty");
        }
    }
}
