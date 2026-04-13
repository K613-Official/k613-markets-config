// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title TokensConfig
/// @notice Shared types for network-scoped token listings used by registries and payloads.
library TokensConfig {
    /// @notice Supported deployment networks for token configuration.
    enum Network {
        ArbitrumSepolia,
        MonadMainnet
    }

    /// @notice Static metadata for a listed reserve asset.
    /// @param asset ERC20 address of the underlying on the target network.
    /// @param priceFeed Chainlink-style oracle feed used by the pool for this asset.
    /// @param decimals Token decimals mirrored for configuration consumers.
    /// @param symbol Human-readable ticker used for risk and cap routing.
    struct Token {
        address asset;
        address priceFeed;
        uint8 decimals;
        string symbol;
    }
}
