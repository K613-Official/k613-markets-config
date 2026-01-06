// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokensConfig} from "./TokensConfig.sol";

/// @title RiskConfig
/// @notice Configuration for risk parameters of listed assets
/// @dev Sets up borrow caps, supply caps, liquidation bonus, reserve factor, and isolation mode
contract RiskConfig {
    TokensConfig public immutable tokensConfig;

    /// @notice Risk parameters structure
    struct RiskParams {
        address asset;
        uint256 borrowCap; // Maximum borrow amount
        uint256 supplyCap; // Maximum supply amount
        uint256 liquidationBonus; // Liquidation bonus in basis points (e.g., 500 = 5%)
        uint256 reserveFactor; // Reserve factor in basis points (e.g., 1000 = 10%)
        bool isolationMode; // Whether asset is in isolation mode
    }

    /// @notice Default risk parameters
    /// @dev These are typical values for testnet, adjust as needed
    RiskParams[] public riskParams;

    constructor() {
        tokensConfig = new TokensConfig();

        // Initialize default risk parameters for all tokens
        _initializeDefaultRiskParams();
    }

    /// @notice Initializes default risk parameters
    /// @dev Sets conservative values for testnet
    function _initializeDefaultRiskParams() internal {
        TokensConfig.TokenConfig[] memory tokens = tokensConfig.getAllTokens();

        for (uint256 i = 0; i < tokens.length; i++) {
            address asset = tokens[i].asset;

            // Default parameters (adjust based on token type)
            uint256 borrowCap = 1000000 * 10 ** tokens[i].decimals; // 1M tokens
            uint256 supplyCap = 2000000 * 10 ** tokens[i].decimals; // 2M tokens
            uint256 liquidationBonus = 500; // 5%
            uint256 reserveFactor = 1000; // 10%
            bool isolationMode = false;

            // Special cases
            if (keccak256(bytes(tokens[i].symbol)) == keccak256(bytes("WBTC"))) {
                // WBTC typically has lower caps
                borrowCap = 100 * 10 ** tokens[i].decimals;
                supplyCap = 200 * 10 ** tokens[i].decimals;
            }

            riskParams.push(
                RiskParams({
                    asset: asset,
                    borrowCap: borrowCap,
                    supplyCap: supplyCap,
                    liquidationBonus: liquidationBonus,
                    reserveFactor: reserveFactor,
                    isolationMode: isolationMode
                })
            );
        }
    }

    /// @notice Gets risk parameters for an asset
    /// @param asset Token address
    /// @return RiskParams struct
    function getRiskParams(address asset) external view returns (RiskParams memory) {
        for (uint256 i = 0; i < riskParams.length; i++) {
            if (riskParams[i].asset == asset) {
                return riskParams[i];
            }
        }
        revert("Risk params not found");
    }

    /// @notice Gets all risk parameters
    /// @return Array of RiskParams structs
    function getAllRiskParams() external view returns (RiskParams[] memory) {
        return riskParams;
    }

    /// @notice Updates risk parameters for an asset
    /// @param asset Token address
    /// @param borrowCap New borrow cap
    /// @param supplyCap New supply cap
    /// @param liquidationBonus New liquidation bonus (basis points)
    /// @param reserveFactor New reserve factor (basis points)
    /// @param isolationMode New isolation mode flag
    function updateRiskParams(
        address asset,
        uint256 borrowCap,
        uint256 supplyCap,
        uint256 liquidationBonus,
        uint256 reserveFactor,
        bool isolationMode
    ) external {
        for (uint256 i = 0; i < riskParams.length; i++) {
            if (riskParams[i].asset == asset) {
                riskParams[i].borrowCap = borrowCap;
                riskParams[i].supplyCap = supplyCap;
                riskParams[i].liquidationBonus = liquidationBonus;
                riskParams[i].reserveFactor = reserveFactor;
                riskParams[i].isolationMode = isolationMode;
                return;
            }
        }
        revert("Asset not found");
    }
}

