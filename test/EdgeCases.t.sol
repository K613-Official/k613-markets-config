// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {RiskConfig} from "../src/config/RiskConfig.sol";
import {OraclesConfig} from "../src/config/OraclesConfig.sol";
import {IAaveOracle} from "../src/interfaces/IAaveExternal.sol";

/// @title MockOracleEdgeCases
/// @notice Mock oracle for edge case testing
contract MockOracleEdgeCases is IAaveOracle {
    mapping(address => address) public sources;
    mapping(address => uint256) public prices;

    function setAssetSources(address[] calldata assets, address[] calldata _sources) external override {
        require(assets.length == _sources.length, "Length mismatch");
        for (uint256 i = 0; i < assets.length; i++) {
            sources[assets[i]] = _sources[i];
        }
    }

    function getAssetPrice(address asset) external view override returns (uint256) {
        return prices[asset];
    }

    function getSourceOfAsset(address asset) external view override returns (address) {
        return sources[asset];
    }

    function setPrice(address asset, uint256 price) external {
        prices[asset] = price;
    }
}

/// @title EdgeCasesTest
/// @notice Tests for edge cases and boundary conditions
contract EdgeCasesTest is Test {
    MockOracleEdgeCases public oracle;

    function setUp() public {
        oracle = new MockOracleEdgeCases();
    }

    function test_EmptyOracleVerification() public {
        // Configure oracles but don't set prices
        OraclesConfig.configureOracles(address(oracle), TokensConfig.Network.ArbitrumSepolia);

        (bool success, address[] memory invalidAssets) =
            OraclesConfig.verifyOracles(address(oracle), TokensConfig.Network.ArbitrumSepolia);

        assertFalse(success, "Should fail when prices are zero");
        assertEq(invalidAssets.length, 5, "All assets should be invalid");
    }

    function test_PartialOracleVerification() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        OraclesConfig.configureOracles(address(oracle), TokensConfig.Network.ArbitrumSepolia);

        // Set prices for only first 2 tokens
        oracle.setPrice(tokens[0].asset, 1000 * 1e8);
        oracle.setPrice(tokens[1].asset, 2000 * 1e8);

        (bool success, address[] memory invalidAssets) =
            OraclesConfig.verifyOracles(address(oracle), TokensConfig.Network.ArbitrumSepolia);

        assertFalse(success, "Should fail when some prices are zero");
        assertEq(invalidAssets.length, 3, "Should have 3 invalid assets");
    }

    function test_AllTokensHaveNonZeroAddresses() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < tokens.length; i++) {
            assertNotEq(tokens[i].asset, address(0), "Token asset should not be zero");
            assertNotEq(tokens[i].priceFeed, address(0), "Price feed should not be zero");
        }
    }

    function test_RiskParamsCapsAreNonZero() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < params.length; i++) {
            assertGt(params[i].borrowCap, 0, "Borrow cap should be greater than 0");
            assertGt(params[i].supplyCap, 0, "Supply cap should be greater than 0");
            assertGt(params[i].supplyCap, params[i].borrowCap, "Supply cap should be greater than borrow cap");
        }
    }

    function test_TokenDecimalsAreValid() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < tokens.length; i++) {
            assertGt(tokens[i].decimals, 0, "Decimals should be greater than 0");
            assertLe(tokens[i].decimals, 18, "Decimals should not exceed 18");
        }
    }

    function test_TokenSymbolsAreNonEmpty() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < tokens.length; i++) {
            bytes memory symbolBytes = bytes(tokens[i].symbol);
            assertGt(symbolBytes.length, 0, "Symbol should not be empty");
            assertLe(symbolBytes.length, 10, "Symbol should be reasonable length");
        }
    }

    function test_RiskParamsLiquidationThresholdSafety() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < params.length; i++) {
            // Safety check: liquidation threshold should be greater than LTV (already tested elsewhere)
            // This test just verifies the difference is reasonable (at least 2.5%)
            uint256 minLiquidationThreshold = params[i].ltv + (RiskConfig.BASIS_POINTS / 40); // 2.5%
            assertGe(
                params[i].liquidationThreshold,
                minLiquidationThreshold,
                "Liquidation threshold should provide reasonable safety margin"
            );
        }
    }

    function test_MonadMainnetTokensHavePlaceholders() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.MonadMainnet);

        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(tokens[i].asset, address(0), "Mainnet tokens should have placeholder addresses");
            assertEq(tokens[i].priceFeed, address(0), "Mainnet price feeds should be placeholders");
        }
    }
}
