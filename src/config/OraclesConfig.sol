// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokensConfig} from "./TokensConfig.sol";
import {IAaveOracle} from "lib/K613-Protocol/src/contracts/interfaces/IAaveOracle.sol";

/// @title OraclesConfig
/// @notice Configures and validates `AaveOracle` asset sources from `TokensConfig`.
/// @dev Uses `IAaveOracle.setAssetSources` and read paths for verification.
library OraclesConfig {
    /// @notice Registers Chainlink (or custom) feeds for every configured asset.
    /// @param oracle On-chain `AaveOracle` proxy.
    /// @param network Deployment whose token list is applied.
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

    /// @notice Checks that each configured asset returns a non-zero price from the oracle.
    /// @param oracle On-chain `AaveOracle` proxy.
    /// @param network Deployment whose token list is checked.
    /// @return success True when every price is non-zero and calls succeed.
    /// @return invalidAssets Subset of assets that failed validation (zero price or revert).
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

    /// @notice Reads the registered feed address for an asset.
    /// @param oracle On-chain `AaveOracle` proxy.
    /// @param asset Underlying asset to query.
    /// @return source Aggregator or adapter registered for `asset`.
    function getPriceFeedSource(address oracle, address asset) internal view returns (address source) {
        return IAaveOracle(oracle).getSourceOfAsset(asset);
    }
}
