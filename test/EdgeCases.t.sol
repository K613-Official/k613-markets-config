// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {RiskParametersFixture} from "./RiskParametersFixture.sol";
import {IRiskParametersConfig} from "../src/config/interface/IRiskParametersConfig.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {OraclesConfig} from "../src/config/OraclesConfig.sol";

/// @title MockOracleEdgeCases
/// @notice Mock oracle for edge case testing
contract MockOracleEdgeCases {
    error ArrayLengthMismatch();

    mapping(address => address) public sources;
    mapping(address => uint256) public prices;

    function setAssetSources(address[] calldata assets, address[] calldata _sources) external {
        if (assets.length != _sources.length) revert ArrayLengthMismatch();
        for (uint256 i = 0; i < assets.length; i++) {
            sources[assets[i]] = _sources[i];
        }
    }

    function getAssetPrice(address asset) external view returns (uint256) {
        return prices[asset];
    }

    function getSourceOfAsset(address asset) external view returns (address) {
        return sources[asset];
    }

    function setPrice(address asset, uint256 price) external {
        prices[asset] = price;
    }
}

/// @title EdgeCasesTest
/// @notice Tests for edge cases and boundary conditions
contract EdgeCasesTest is RiskParametersFixture {
    MockOracleEdgeCases public oracle;

    function setUp() public override {
        super.setUp();
        oracle = new MockOracleEdgeCases();
    }

    function test_EmptyOracleVerification() public {
        // Configure oracles but don't set prices
        OraclesConfig.configureOracles(address(oracle), tokensRegistry, TokensConfig.Network.ArbitrumSepolia);

        (bool success, address[] memory invalidAssets) =
            OraclesConfig.verifyOracles(address(oracle), tokensRegistry, TokensConfig.Network.ArbitrumSepolia);

        assertFalse(success, "Should fail when prices are zero");
        assertEq(invalidAssets.length, 5, "All assets should be invalid");
    }

    function test_PartialOracleVerification() public {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        OraclesConfig.configureOracles(address(oracle), tokensRegistry, TokensConfig.Network.ArbitrumSepolia);

        // Set prices for only first 2 tokens
        oracle.setPrice(tokens[0].asset, 1000 * 1e8);
        oracle.setPrice(tokens[1].asset, 2000 * 1e8);

        (bool success, address[] memory invalidAssets) =
            OraclesConfig.verifyOracles(address(oracle), tokensRegistry, TokensConfig.Network.ArbitrumSepolia);

        assertFalse(success, "Should fail when some prices are zero");
        assertEq(invalidAssets.length, 3, "Should have 3 invalid assets");
    }

    function test_AllTokensHaveNonZeroAddresses() public {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < tokens.length; i++) {
            assertNotEq(tokens[i].asset, address(0), "Token asset should not be zero");
            assertNotEq(tokens[i].priceFeed, address(0), "Price feed should not be zero");
        }
    }

    function test_RiskParamsCapsAreNonZero() public view {
        IRiskParametersConfig.RiskParams[] memory params =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < params.length; i++) {
            assertGt(params[i].borrowCap, 0, "Borrow cap should be greater than 0");
            assertGt(params[i].supplyCap, 0, "Supply cap should be greater than 0");
            assertGt(params[i].supplyCap, params[i].borrowCap, "Supply cap should be greater than borrow cap");
        }
    }

    function test_TokenDecimalsAreValid() public {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < tokens.length; i++) {
            assertGt(tokens[i].decimals, 0, "Decimals should be greater than 0");
            assertLe(tokens[i].decimals, 18, "Decimals should not exceed 18");
        }
    }

    function test_TokenSymbolsAreNonEmpty() public {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < tokens.length; i++) {
            bytes memory symbolBytes = bytes(tokens[i].symbol);
            assertGt(symbolBytes.length, 0, "Symbol should not be empty");
            assertLe(symbolBytes.length, 10, "Symbol should be reasonable length");
        }
    }

    function test_RiskParamsLiquidationThresholdSafety() public view {
        IRiskParametersConfig.RiskParams[] memory params =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < params.length; i++) {
            uint256 minLiquidationThreshold = params[i].ltv + (risk.BASIS_POINTS() / 40);
            assertGe(
                params[i].liquidationThreshold,
                minLiquidationThreshold,
                "Liquidation threshold should provide reasonable safety margin"
            );
        }
    }

    function test_MonadMainnetTokensHaveDeployedAddresses() public {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.MonadMainnet);

        for (uint256 i = 0; i < tokens.length; i++) {
            assertNotEq(tokens[i].asset, address(0), "Mainnet token asset should be set");
            assertNotEq(tokens[i].priceFeed, address(0), "Mainnet price feed should be set");
        }
    }
}
