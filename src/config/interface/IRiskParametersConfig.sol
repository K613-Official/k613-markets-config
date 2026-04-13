// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokensConfig} from "../TokensConfig.sol";
import {ITokensRegistry} from "./ITokensRegistry.sol";

/// @title IRiskParametersConfig
/// @notice Source of Aave-style risk parameters and caps aligned with `ITokensRegistry` listings.
interface IRiskParametersConfig {
    /// @notice Registry whose token list drives `getRiskParams` ordering and membership.
    /// @return registry Configured immutable `ITokensRegistry`.
    function tokensRegistry() external view returns (ITokensRegistry registry);

    /// @notice Per-asset risk row produced for governance payloads and scripts.
    /// @param asset Underlying asset address from the registry entry.
    /// @param ltv Loan-to-value in basis points.
    /// @param liquidationThreshold Liquidation threshold in basis points.
    /// @param liquidationBonus Liquidation bonus in basis points (must be at least 10_000).
    /// @param reserveFactor Reserve factor in basis points.
    /// @param borrowCap Protocol borrow cap for the asset.
    /// @param supplyCap Protocol supply cap for the asset.
    struct RiskParams {
        address asset;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 reserveFactor;
        uint256 borrowCap;
        uint256 supplyCap;
    }

    /// @notice Builds risk rows for every token listed on `network`.
    /// @param network Target chain deployment.
    /// @return params Parallel array to `getTokens(network)` with class risk and caps resolved.
    function getRiskParams(TokensConfig.Network network) external view returns (RiskParams[] memory params);
}
