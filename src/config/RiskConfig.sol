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

    // WETH asset address
    address internal constant WETH_ASSET = 0x980B62Da83eFf3D4576C647993b0c1D7faf17c73;

    struct RiskParams {
        address asset;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 reserveFactor;
        uint256 borrowCap;
        uint256 supplyCap;
    }

    /// @notice Gets risk parameters for WETH
    function weth() internal pure returns (RiskParams memory) {
        return RiskParams({
            asset: WETH_ASSET,
            ltv: WETH_LTV,
            liquidationThreshold: WETH_LIQUIDATION_THRESHOLD,
            liquidationBonus: LIQUIDATION_BONUS,
            reserveFactor: BLUE_CHIP_RESERVE_FACTOR,
            borrowCap: DEFAULT_BORROW_CAP_MULTIPLIER * 1e18,
            supplyCap: DEFAULT_SUPPLY_CAP_MULTIPLIER * 1e18
        });
    }

    /// @notice Computes keccak256 hash of a string using inline assembly for efficiency
    function _hashString(string memory str) private pure returns (bytes32 hash) {
        assembly {
            hash := keccak256(add(str, 0x20), mload(str))
        }
    }

    /// @notice Gets all risk parameters for configured tokens
    function getRiskParams() internal pure returns (RiskParams[] memory) {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens();
        RiskParams[] memory params = new RiskParams[](tokens.length);

        // Pre-compute symbol hashes for efficiency
        bytes32 wethHash = _hashString("WETH");
        bytes32 wbtcHash = _hashString("WBTC");
        bytes32 usdcHash = _hashString("USDC");
        bytes32 usdtHash = _hashString("USDT");
        bytes32 daiHash = _hashString("DAI");

        for (uint256 i; i < tokens.length; i++) {
            bytes32 symbolHash = _hashString(tokens[i].symbol);
            address asset = tokens[i].asset;
            uint8 decimals = tokens[i].decimals;

            // Default parameters
            uint256 ltv = DEFAULT_LTV;
            uint256 liquidationThreshold = DEFAULT_LIQUIDATION_THRESHOLD;
            uint256 liquidationBonus = LIQUIDATION_BONUS;
            uint256 reserveFactor = BLUE_CHIP_RESERVE_FACTOR;
            uint256 borrowCap = DEFAULT_BORROW_CAP_MULTIPLIER * 10 ** decimals;
            uint256 supplyCap = DEFAULT_SUPPLY_CAP_MULTIPLIER * 10 ** decimals;

            // Adjust parameters based on token type
            if (symbolHash == wethHash) {
                ltv = WETH_LTV;
                liquidationThreshold = WETH_LIQUIDATION_THRESHOLD;
            } else if (symbolHash == wbtcHash) {
                ltv = WBTC_LTV;
                liquidationThreshold = WBTC_LIQUIDATION_THRESHOLD;
                borrowCap = WBTC_BORROW_CAP_MULTIPLIER * 10 ** decimals;
                supplyCap = WBTC_SUPPLY_CAP_MULTIPLIER * 10 ** decimals;
            } else if (symbolHash == usdcHash || symbolHash == usdtHash || symbolHash == daiHash) {
                // Stablecoins (blue-chip)
                ltv = STABLECOIN_LTV;
                liquidationThreshold = STABLECOIN_LIQUIDATION_THRESHOLD;
            }

            params[i] = RiskParams({
                asset: asset,
                ltv: ltv,
                liquidationThreshold: liquidationThreshold,
                liquidationBonus: liquidationBonus,
                reserveFactor: reserveFactor,
                borrowCap: borrowCap,
                supplyCap: supplyCap
            });
        }

        return params;
    }
}
