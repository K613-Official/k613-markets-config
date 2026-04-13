// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokensConfig} from "./TokensConfig.sol";
import {ITokensRegistry} from "./interface/ITokensRegistry.sol";
import {IAaveOracle} from "lib/K613-Protocol/src/contracts/interfaces/IAaveOracle.sol";

/// @title OraclesConfig
/// @notice Internal helpers to push registry feeds into `IAaveOracle` and validate them.
library OraclesConfig {
    /// @notice Sets oracle sources for all assets listed for `network`.
    /// @param oracle Aave oracle contract on the target chain.
    /// @param registry Token registry providing asset and feed pairs.
    /// @param network Network whose listing is applied.
    function configureOracles(address oracle, ITokensRegistry registry, TokensConfig.Network network) internal {
        TokensConfig.Token[] memory tokens = registry.getTokens(network);

        address[] memory assets = new address[](tokens.length);
        address[] memory sources = new address[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            assets[i] = tokens[i].asset;
            sources[i] = tokens[i].priceFeed;
        }

        IAaveOracle(oracle).setAssetSources(assets, sources);
    }

    /// @notice Checks that `oracle` returns a non-zero price for every listed asset.
    /// @param oracle Aave oracle contract on the target chain.
    /// @param registry Token registry whose assets are verified.
    /// @param network Network whose listing is verified.
    /// @return success True when no invalid prices were observed.
    /// @return invalidAssets Subset of assets that returned zero price or reverted on read.
    function verifyOracles(address oracle, ITokensRegistry registry, TokensConfig.Network network)
        internal
        view
        returns (bool success, address[] memory invalidAssets)
    {
        TokensConfig.Token[] memory tokens = registry.getTokens(network);
        address[] memory invalid = new address[](tokens.length);
        uint256 invalidCount;

        for (uint256 i = 0; i < tokens.length; i++) {
            try IAaveOracle(oracle).getAssetPrice(tokens[i].asset) returns (uint256 price) {
                if (price == 0) {
                    invalid[invalidCount] = tokens[i].asset;
                    invalidCount++;
                }
            } catch {
                invalid[invalidCount] = tokens[i].asset;
                invalidCount++;
            }
        }

        if (invalidCount == 0) {
            success = true;
            invalidAssets = new address[](0);
        } else {
            success = false;
            invalidAssets = new address[](invalidCount);
            for (uint256 i = 0; i < invalidCount; i++) {
                invalidAssets[i] = invalid[i];
            }
        }
    }

    /// @notice Reads the configured feed source for a single asset from the oracle.
    /// @param oracle Aave oracle contract on the target chain.
    /// @param asset Underlying asset address.
    /// @return source Feed contract registered for `asset`.
    function getPriceFeedSource(address oracle, address asset) internal view returns (address source) {
        return IAaveOracle(oracle).getSourceOfAsset(asset);
    }
}
