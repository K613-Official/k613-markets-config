// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {OraclesConfig} from "../src/config/OraclesConfig.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {TokensRegistry} from "../src/config/TokensRegistry.sol";
import {ITokensRegistry} from "../src/config/interface/ITokensRegistry.sol";

contract MockAaveOracle {
    error ArrayLengthMismatch();

    mapping(address => address) public sources;
    mapping(address => uint256) public prices;

    function setAssetSources(address[] calldata assets, address[] calldata _sources) external {
        if (assets.length != _sources.length) revert ArrayLengthMismatch();
        for (uint256 i = 0; i < assets.length; i++) {
            sources[assets[i]] = _sources[i];
            prices[assets[i]] = 1000 * 1e8;
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

contract OraclesConfigTest is Test {
    MockAaveOracle public oracle;
    ITokensRegistry public tokensRegistry;

    function setUp() public {
        oracle = new MockAaveOracle();
        tokensRegistry = ITokensRegistry(address(new TokensRegistry(address(this))));
    }

    function test_ConfigureOracles() public {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        OraclesConfig.configureOracles(address(oracle), tokensRegistry, TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < tokens.length; i++) {
            address source = oracle.getSourceOfAsset(tokens[i].asset);
            assertEq(source, tokens[i].priceFeed, "Price feed source should match");
        }
    }

    function test_VerifyOraclesWithValidPrices() public {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        OraclesConfig.configureOracles(address(oracle), tokensRegistry, TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < tokens.length; i++) {
            oracle.setPrice(tokens[i].asset, 1000 * 1e8);
        }

        (bool success, address[] memory invalidAssets) =
            OraclesConfig.verifyOracles(address(oracle), tokensRegistry, TokensConfig.Network.ArbitrumSepolia);

        assertTrue(success, "Verification should succeed");
        assertEq(invalidAssets.length, 0, "Should have no invalid assets");
    }

    function test_VerifyOraclesWithInvalidPrices() public {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        OraclesConfig.configureOracles(address(oracle), tokensRegistry, TokensConfig.Network.ArbitrumSepolia);

        oracle.setPrice(tokens[0].asset, 0);
        oracle.setPrice(tokens[1].asset, 0);

        (bool success, address[] memory invalidAssets) =
            OraclesConfig.verifyOracles(address(oracle), tokensRegistry, TokensConfig.Network.ArbitrumSepolia);

        assertFalse(success, "Verification should fail");
        assertEq(invalidAssets.length, 2, "Should have 2 invalid assets");
        assertEq(invalidAssets[0], tokens[0].asset, "First invalid asset should match");
        assertEq(invalidAssets[1], tokens[1].asset, "Second invalid asset should match");
    }

    function test_GetPriceFeedSource() public {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        OraclesConfig.configureOracles(address(oracle), tokensRegistry, TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < tokens.length; i++) {
            address source = OraclesConfig.getPriceFeedSource(address(oracle), tokens[i].asset);
            assertEq(source, tokens[i].priceFeed, "Price feed source should match");
        }
    }

    function test_ConfigureOraclesForMonadMainnet() public {
        OraclesConfig.configureOracles(address(oracle), tokensRegistry, TokensConfig.Network.MonadMainnet);

        assertTrue(true, "Should not revert");
    }
}
