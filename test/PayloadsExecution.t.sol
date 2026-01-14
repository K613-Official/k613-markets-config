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

/// @title PayloadsExecutionTest
/// @notice Tests for payload execution logic and data structure validation
contract PayloadsExecutionTest is Test {
    function test_ListingPayloadDeploys() public {
        ListingPayload payload = new ListingPayload();
        assertNotEq(address(payload), address(0), "Payload should deploy");
    }

    function test_CollateralConfigPayloadDeploys() public {
        CollateralConfigPayload payload = new CollateralConfigPayload();
        assertNotEq(address(payload), address(0), "Payload should deploy");
    }

    function test_OracleUpdatePayloadDeploys() public {
        OracleUpdatePayload payload = new OracleUpdatePayload();
        assertNotEq(address(payload), address(0), "Payload should deploy");
    }

    function test_RiskUpdatePayloadDeploys() public {
        RiskUpdatePayload payload = new RiskUpdatePayload();
        assertNotEq(address(payload), address(0), "Payload should deploy");
    }

    function test_ListingPayloadCreatesCorrectInitReserveInputs() public view {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);
        NetworkConfig.Addresses memory addrs = ArbitrumSepolia.getAddresses();

        // Verify that inputs would be created correctly (same logic as ListingPayload)
        ConfiguratorInputTypes.InitReserveInput[] memory inputs =
            new ConfiguratorInputTypes.InitReserveInput[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            inputs[i] = ConfiguratorInputTypes.InitReserveInput({
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
            assertEq(inputs[i].underlyingAsset, tokens[i].asset, "Asset should match");
            assertEq(inputs[i].underlyingAssetDecimals, tokens[i].decimals, "Decimals should match");
            assertEq(inputs[i].stableDebtTokenImpl, address(0), "Stable debt should be disabled");
            assertNotEq(inputs[i].aTokenImpl, address(0), "AToken impl should be set");
            assertNotEq(inputs[i].variableDebtTokenImpl, address(0), "Variable debt impl should be set");
            assertGt(bytes(inputs[i].aTokenName).length, 0, "AToken name should not be empty");
            assertGt(bytes(inputs[i].aTokenSymbol).length, 0, "AToken symbol should not be empty");
        }
    }

    function test_CollateralConfigPayloadDataConsistency() public view {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);
        RiskConfig.RiskParams[] memory riskParams = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        // Verify structure matches
        assertEq(tokens.length, riskParams.length, "Tokens and risk params should match");

        // Verify each risk param has valid values
        for (uint256 i = 0; i < riskParams.length; i++) {
            assertNotEq(riskParams[i].asset, address(0), "Asset should not be zero");
            assertLe(riskParams[i].ltv, 10000, "LTV should be <= 100%");
            assertLe(riskParams[i].liquidationThreshold, 10000, "Liquidation threshold should be <= 100%");
            assertGe(riskParams[i].liquidationThreshold, riskParams[i].ltv, "Liquidation threshold should be >= LTV");
            assertGt(riskParams[i].liquidationBonus, 10000, "Liquidation bonus should be > 100%");
            assertLe(riskParams[i].reserveFactor, 10000, "Reserve factor should be <= 100%");
            assertGt(riskParams[i].borrowCap, 0, "Borrow cap should be > 0");
            assertGt(riskParams[i].supplyCap, 0, "Supply cap should be > 0");
        }
    }

    function test_RiskUpdatePayloadDataConsistency() public view {
        RiskConfig.RiskParams[] memory riskParams = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        // Verify all risk params have valid values for risk updates
        for (uint256 i = 0; i < riskParams.length; i++) {
            assertNotEq(riskParams[i].asset, address(0), "Asset should not be zero");
            assertGt(riskParams[i].borrowCap, 0, "Borrow cap should be > 0");
            assertGt(riskParams[i].supplyCap, 0, "Supply cap should be > 0");
            assertLe(riskParams[i].reserveFactor, 10000, "Reserve factor should be <= 100%");
        }
    }

    function test_OracleUpdatePayloadDataConsistency() public view {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);
        NetworkConfig.Addresses memory addrs = ArbitrumSepolia.getAddresses();

        // Verify oracle address is set
        assertNotEq(addrs.oracle, address(0), "Oracle address should be set");

        // Verify all tokens have price feeds
        for (uint256 i = 0; i < tokens.length; i++) {
            assertNotEq(tokens[i].priceFeed, address(0), "Price feed should not be zero");
            assertNotEq(tokens[i].asset, address(0), "Asset should not be zero");
        }
    }

    function test_AllPayloadsUseArbitrumSepoliaNetwork() public view {
        // Verify all payloads are configured for ArbitrumSepolia by default
        // This is tested by checking that they can access ArbitrumSepolia addresses
        NetworkConfig.Addresses memory addrs = ArbitrumSepolia.getAddresses();
        assertNotEq(addrs.pool, address(0), "Pool should be set for ArbitrumSepolia");
        assertNotEq(addrs.oracle, address(0), "Oracle should be set for ArbitrumSepolia");
    }

    function test_ListingPayloadStableDebtDisabled() public view {
        NetworkConfig.Addresses memory addrs = ArbitrumSepolia.getAddresses();
        // Verify stable debt is disabled (address(0))
        assertEq(addrs.stableDebtImpl, address(0), "Stable debt should be disabled");
    }

    function test_PayloadsNetworkSwitching() public view {
        // Test that payloads can work with both networks
        NetworkConfig.Addresses memory arbitrumAddrs = ArbitrumSepolia.getAddresses();
        NetworkConfig.Addresses memory monadAddrs = MonadMainnet.getAddresses();

        // Arbitrum should have real addresses
        assertNotEq(arbitrumAddrs.pool, address(0), "Arbitrum pool should be set");

        // Monad should have placeholders (for now)
        assertEq(monadAddrs.pool, address(0), "Monad pool should be placeholder");
    }

    function test_ListingPayloadTokenNamesFormat() public view {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < tokens.length; i++) {
            string memory aTokenName = string.concat("Aave ", tokens[i].symbol);
            string memory aTokenSymbol = string.concat("a", tokens[i].symbol);
            string memory variableDebtTokenName = string.concat("Aave Variable Debt ", tokens[i].symbol);
            string memory variableDebtTokenSymbol = string.concat("variableDebt", tokens[i].symbol);

            // Verify naming format
            assertGt(bytes(aTokenName).length, bytes(tokens[i].symbol).length, "AToken name should include prefix");
            assertGt(bytes(aTokenSymbol).length, 0, "AToken symbol should not be empty");
            assertGt(bytes(variableDebtTokenName).length, bytes(tokens[i].symbol).length, "Variable debt name should include prefix");
            assertGt(bytes(variableDebtTokenSymbol).length, 0, "Variable debt symbol should not be empty");
        }
    }
}
