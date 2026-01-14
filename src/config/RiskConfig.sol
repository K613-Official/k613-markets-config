// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokensConfig} from "./TokensConfig.sol";

/// @title RiskConfig
/// @notice Risk parameters configuration for assets
library RiskConfig {
    // Basis points constants
    uint256 internal constant BASIS_POINTS = 1e4;

    // Default LTV values
    uint256 internal constant DEFAULT_LTV = 7500; // 75%
    uint256 internal constant WETH_LTV = 8000; // 80%
    uint256 internal constant WBTC_LTV = 7000; // 70%
    uint256 internal constant STABLECOIN_LTV = 8000; // 80%

    // Default liquidation threshold values
    uint256 internal constant DEFAULT_LIQUIDATION_THRESHOLD = 8000; // 80%
    uint256 internal constant WETH_LIQUIDATION_THRESHOLD = 8250; // 82.5%
    uint256 internal constant WBTC_LIQUIDATION_THRESHOLD = 7500; // 75%
    uint256 internal constant STABLECOIN_LIQUIDATION_THRESHOLD = 8500; // 85%

    // Liquidation bonus
    uint256 internal constant LIQUIDATION_BONUS = 10500; // 5% bonus

    // Reserve factor
    uint256 internal constant BLUE_CHIP_RESERVE_FACTOR = 2500; // 25% for blue-chip assets
    uint256 internal constant RISK_ASSET_RESERVE_FACTOR = 5000; // 50% for risk assets

    // Default caps
    uint256 internal constant DEFAULT_BORROW_CAP_MULTIPLIER = 1e6;
    uint256 internal constant DEFAULT_SUPPLY_CAP_MULTIPLIER = 2e6;

    // WBTC specific caps
    uint256 internal constant WBTC_BORROW_CAP_MULTIPLIER = 1e2;
    uint256 internal constant WBTC_SUPPLY_CAP_MULTIPLIER = 2e2;

    struct RiskParams {
        address asset;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 reserveFactor;
        uint256 borrowCap;
        uint256 supplyCap;
    }

    /// @notice Computes keccak256 hash of a string using inline assembly for efficiency
    function _hashString(string memory str) private pure returns (bytes32 hash) {
        assembly {
            hash := keccak256(add(str, 0x20), mload(str))
        }
    }

    /// @notice Gets risk parameters for a single token
    /// @param token The token configuration
    /// @param wethHash Pre-computed WETH symbol hash
    /// @param wbtcHash Pre-computed WBTC symbol hash
    /// @param usdcHash Pre-computed USDC symbol hash
    /// @param usdtHash Pre-computed USDT symbol hash
    /// @param daiHash Pre-computed DAI symbol hash
    function _getTokenRiskParams(
        TokensConfig.Token memory token,
        bytes32 wethHash,
        bytes32 wbtcHash,
        bytes32 usdcHash,
        bytes32 usdtHash,
        bytes32 daiHash
    ) private pure returns (RiskParams memory) {
        bytes32 symbolHash = _hashString(token.symbol);
        uint256 decimalsMultiplier = 10 ** token.decimals;

        // Default parameters
        uint256 ltv = DEFAULT_LTV;
        uint256 liquidationThreshold = DEFAULT_LIQUIDATION_THRESHOLD;
        uint256 borrowCap = DEFAULT_BORROW_CAP_MULTIPLIER * decimalsMultiplier;
        uint256 supplyCap = DEFAULT_SUPPLY_CAP_MULTIPLIER * decimalsMultiplier;

        // Adjust parameters based on token type
        if (symbolHash == wethHash) {
            ltv = WETH_LTV;
            liquidationThreshold = WETH_LIQUIDATION_THRESHOLD;
        } else if (symbolHash == wbtcHash) {
            ltv = WBTC_LTV;
            liquidationThreshold = WBTC_LIQUIDATION_THRESHOLD;
            borrowCap = WBTC_BORROW_CAP_MULTIPLIER * decimalsMultiplier;
            supplyCap = WBTC_SUPPLY_CAP_MULTIPLIER * decimalsMultiplier;
        } else if (symbolHash == usdcHash || symbolHash == usdtHash || symbolHash == daiHash) {
            // Stablecoins (blue-chip)
            ltv = STABLECOIN_LTV;
            liquidationThreshold = STABLECOIN_LIQUIDATION_THRESHOLD;
        }

        return RiskParams({
            asset: token.asset,
            ltv: ltv,
            liquidationThreshold: liquidationThreshold,
            liquidationBonus: LIQUIDATION_BONUS,
            reserveFactor: BLUE_CHIP_RESERVE_FACTOR,
            borrowCap: borrowCap,
            supplyCap: supplyCap
        });
    }

    /// @notice Gets all risk parameters for configured tokens
    /// @param network The network to get risk parameters for
    function getRiskParams(TokensConfig.Network network) internal pure returns (RiskParams[] memory) {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(network);
        RiskParams[] memory params = new RiskParams[](tokens.length);

        // Pre-compute symbol hashes for efficiency
        bytes32 wethHash = _hashString("WETH");
        bytes32 wbtcHash = _hashString("WBTC");
        bytes32 usdcHash = _hashString("USDC");
        bytes32 usdtHash = _hashString("USDT");
        bytes32 daiHash = _hashString("DAI");

        for (uint256 i; i < tokens.length; i++) {
            params[i] = _getTokenRiskParams(tokens[i], wethHash, wbtcHash, usdcHash, usdtHash, daiHash);
        }

        return params;
    }
}
