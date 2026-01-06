// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {MarketsAddresses} from "./MarketsAddresses.sol";
import {IAaveOracle} from "../interfaces/IAaveExternal.sol";
import {TokensConfig} from "./TokensConfig.sol";

/// @title OraclesConfig
/// @notice Configuration for Aave v3 price oracles
/// @dev Sets up Chainlink price feeds for assets via AaveOracle
contract OraclesConfig {
    IAaveOracle public immutable ORACLE;
    TokensConfig public immutable TOKENS_CONFIG;

    constructor() {
        ORACLE = IAaveOracle(MarketsAddresses.ORACLE);
        TOKENS_CONFIG = new TokensConfig();
    }

    /// @notice Configures price feeds for all tokens
    /// @dev Reads AaveOracle from MarketsAddresses and calls setAssetSources
    function configureOracles() external {
        TokensConfig.TokenConfig[] memory tokens = TOKENS_CONFIG.getAllTokens();

        address[] memory assets = new address[](tokens.length);
        address[] memory feeds = new address[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            assets[i] = tokens[i].asset;
            feeds[i] = tokens[i].priceFeed;
        }

        ORACLE.setAssetSources(assets, feeds);
    }

    /// @notice Configures price feed for a single token
    /// @param asset Token address
    function configureOracle(address asset) external {
        TokensConfig.TokenConfig memory token = TOKENS_CONFIG.getTokenByAsset(asset);

        address[] memory assets = new address[](1);
        address[] memory feeds = new address[](1);

        assets[0] = token.asset;
        feeds[0] = token.priceFeed;

        ORACLE.setAssetSources(assets, feeds);
    }

    /// @notice Verifies that price feeds are configured correctly
    /// @dev Checks that getAssetPrice != 0 for all tokens
    /// @return success True if all prices are valid
    /// @return invalidAssets Array of assets with invalid prices
    function verifyOracles() external view returns (bool success, address[] memory invalidAssets) {
        TokensConfig.TokenConfig[] memory tokens = TOKENS_CONFIG.getAllTokens();
        address[] memory invalid = new address[](tokens.length);
        uint256 invalidCount = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 price = ORACLE.getAssetPrice(tokens[i].asset);
            if (price == 0) {
                invalid[invalidCount] = tokens[i].asset;
                invalidCount++;
            }
        }

        // Resize array to actual invalid count
        address[] memory result = new address[](invalidCount);
        for (uint256 i = 0; i < invalidCount; i++) {
            result[i] = invalid[i];
        }

        return (invalidCount == 0, result);
    }

    /// @notice Gets the price of an asset
    /// @param asset Token address
    /// @return price The price of the asset
    function getAssetPrice(address asset) external view returns (uint256 price) {
        return ORACLE.getAssetPrice(asset);
    }
}

