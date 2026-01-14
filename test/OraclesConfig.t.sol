// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {OraclesConfig} from "../src/config/OraclesConfig.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {IAaveOracle} from "../src/interfaces/IAaveExternal.sol";

/// @title MockAaveOracle
/// @notice Mock oracle for testing
contract MockAaveOracle is IAaveOracle {
    mapping(address => address) public sources;
    mapping(address => uint256) public prices;

    function setAssetSources(address[] calldata assets, address[] calldata _sources) external override {
        require(assets.length == _sources.length, "Length mismatch");
        for (uint256 i = 0; i < assets.length; i++) {
            sources[assets[i]] = _sources[i];
            // Set a mock price
            prices[assets[i]] = 1000 * 1e8; // Mock price
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

/// @title OraclesConfigTest
/// @notice Tests for OraclesConfig library
contract OraclesConfigTest is Test {
    MockAaveOracle public oracle;

    function setUp() public {
        oracle = new MockAaveOracle();
    }

    function test_ConfigureOracles() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        OraclesConfig.configureOracles(address(oracle), TokensConfig.Network.ArbitrumSepolia);

        // Verify all sources are set
        for (uint256 i = 0; i < tokens.length; i++) {
            address source = oracle.getSourceOfAsset(tokens[i].asset);
            assertEq(source, tokens[i].priceFeed, "Price feed source should match");
        }
    }

    function test_VerifyOraclesWithValidPrices() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        // Configure oracles
        OraclesConfig.configureOracles(address(oracle), TokensConfig.Network.ArbitrumSepolia);

        // Set prices for all assets
        for (uint256 i = 0; i < tokens.length; i++) {
            oracle.setPrice(tokens[i].asset, 1000 * 1e8);
        }

        // Verify
        (bool success, address[] memory invalidAssets) = OraclesConfig.verifyOracles(
            address(oracle),
            TokensConfig.Network.ArbitrumSepolia
        );

        assertTrue(success, "Verification should succeed");
        assertEq(invalidAssets.length, 0, "Should have no invalid assets");
    }

    function test_VerifyOraclesWithInvalidPrices() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        // Configure oracles
        OraclesConfig.configureOracles(address(oracle), TokensConfig.Network.ArbitrumSepolia);

        // Set some prices to zero
        oracle.setPrice(tokens[0].asset, 0);
        oracle.setPrice(tokens[1].asset, 0);

        // Verify
        (bool success, address[] memory invalidAssets) = OraclesConfig.verifyOracles(
            address(oracle),
            TokensConfig.Network.ArbitrumSepolia
        );

        assertFalse(success, "Verification should fail");
        assertEq(invalidAssets.length, 2, "Should have 2 invalid assets");
        assertEq(invalidAssets[0], tokens[0].asset, "First invalid asset should match");
        assertEq(invalidAssets[1], tokens[1].asset, "Second invalid asset should match");
    }

    function test_GetPriceFeedSource() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        OraclesConfig.configureOracles(address(oracle), TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < tokens.length; i++) {
            address source = OraclesConfig.getPriceFeedSource(address(oracle), tokens[i].asset);
            assertEq(source, tokens[i].priceFeed, "Price feed source should match");
        }
    }

    function test_ConfigureOraclesForMonadMainnet() public {
        // Should not revert even with placeholder addresses
        OraclesConfig.configureOracles(address(oracle), TokensConfig.Network.MonadMainnet);
        
        // Verify it was called (no revert means success)
        assertTrue(true, "Should not revert");
    }
}
