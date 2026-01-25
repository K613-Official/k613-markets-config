// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokensConfig} from "./TokensConfig.sol";
import {IAaveOracle} from "lib/L2-Protocol/src/contracts/interfaces/IAaveOracle.sol";

/// @title OraclesConfig
/// @notice Configuration and utilities for Aave v3 Oracle setup
/// @dev Provides functions to configure price feeds via AaveOracle
library OraclesConfig {
    /// @notice Configures oracle price feeds for all tokens
    /// @param oracle Address of the AaveOracle contract
    /// @param network The network to configure oracles for
    function configureOracles(address oracle, TokensConfig.Network network) internal {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(network);

        address[] memory assets = new address[](tokens.length);
        address[] memory sources = new address[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            assets[i] = tokens[i].asset;
            sources[i] = tokens[i].priceFeed;
        }

        IAaveOracle(oracle).setAssetSources(assets, sources);
    }

    /// @notice Verifies that all oracle prices are set (non-zero)
    /// @param oracle Address of the AaveOracle contract
    /// @param network The network to verify oracles for
    /// @return success True if all prices are valid
    /// @return invalidAssets Array of assets with invalid prices
    function verifyOracles(address oracle, TokensConfig.Network network)
        internal
        view
        returns (bool success, address[] memory invalidAssets)
    {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(network);
        address[] memory invalid = new address[](tokens.length);
        uint256 invalidCount;

        for (uint256 i = 0; i < tokens.length; i++) {
            try IAaveOracle(oracle).getAssetPrice(tokens[i].asset) returns (uint256 price) {
                if (price == 0) {
                    invalid[invalidCount] = tokens[i].asset;
                    invalidCount++;
                }
            } catch {
                // Price feed doesn't exist or is invalid
                invalid[invalidCount] = tokens[i].asset;
                invalidCount++;
            }
        }

        if (invalidCount == 0) {
            success = true;
            invalidAssets = new address[](0);
        } else {
            success = false;
            // Resize array to actual invalid count
            invalidAssets = new address[](invalidCount);
            for (uint256 i = 0; i < invalidCount; i++) {
                invalidAssets[i] = invalid[i];
            }
        }
    }

    /// @notice Gets the price feed source for an asset
    function getPriceFeedSource(address oracle, address asset) internal view returns (address source) {
        return IAaveOracle(oracle).getSourceOfAsset(asset);
    }
}
