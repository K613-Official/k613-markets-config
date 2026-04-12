// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokensConfig} from "./TokensConfig.sol";

/// @title RiskConfig
/// @notice Derives Aave-compatible risk parameters from `TokensConfig` symbols.
/// @dev LTV, liquidation, caps, and reserve factor use basis points (1e4 = 100%).
library RiskConfig {
    // Basis points constants
    uint256 internal constant BASIS_POINTS = 1e4;

    // Default LTV values
    uint256 internal constant DEFAULT_LTV = 7500; // 75%
    uint256 internal constant WETH_LTV = 8000; // 80%
    uint256 internal constant BTC_LTV = 7000; // 70%
    uint256 internal constant STABLECOIN_LTV = 8000; // 80%

    // MON-derivative LTV values
    uint256 internal constant WMON_LTV = 5500; // 55%
    uint256 internal constant MON_DERIVATIVE_LTV = 4500; // 45% (SHMON, SMON, GMON — less liquid)

    // Default liquidation threshold values
    uint256 internal constant DEFAULT_LIQUIDATION_THRESHOLD = 8000; // 80%
    uint256 internal constant WETH_LIQUIDATION_THRESHOLD = 8250; // 82.5%
    uint256 internal constant BTC_LIQUIDATION_THRESHOLD = 7500; // 75%
    uint256 internal constant STABLECOIN_LIQUIDATION_THRESHOLD = 8500; // 85%
    uint256 internal constant WMON_LIQUIDATION_THRESHOLD = 6500; // 65%
    uint256 internal constant MON_DERIVATIVE_LIQUIDATION_THRESHOLD = 6000; // 60%

    // Liquidation bonus (per asset class)
    uint256 internal constant STABLECOIN_LIQUIDATION_BONUS = 10250; // 2.5% bonus
    uint256 internal constant BLUE_CHIP_LIQUIDATION_BONUS = 10500; // 5% bonus
    uint256 internal constant VOLATILE_LIQUIDATION_BONUS = 10750; // 7.5% bonus

    // Reserve factor
    uint256 internal constant BLUE_CHIP_RESERVE_FACTOR = 2500; // 25% for blue-chip assets
    uint256 internal constant RISK_ASSET_RESERVE_FACTOR = 5000; // 50% for risk assets

    // Per-token caps (whole tokens, not scaled by decimals)
    // supplyCap > borrowCap to ensure withdrawal liquidity
    uint256 internal constant USDC_BORROW_CAP = 200_000;
    uint256 internal constant USDC_SUPPLY_CAP = 250_000;
    uint256 internal constant AUSD_BORROW_CAP = 200_000;
    uint256 internal constant AUSD_SUPPLY_CAP = 250_000;
    uint256 internal constant WSTETH_BORROW_CAP = 150_000;
    uint256 internal constant WSTETH_SUPPLY_CAP = 190_000;
    uint256 internal constant WETH_BORROW_CAP = 120_000;
    uint256 internal constant WETH_SUPPLY_CAP = 150_000;
    uint256 internal constant USDT0_BORROW_CAP = 200_000;
    uint256 internal constant USDT0_SUPPLY_CAP = 250_000;
    uint256 internal constant WSRUSD_BORROW_CAP = 200_000;
    uint256 internal constant WSRUSD_SUPPLY_CAP = 250_000;
    uint256 internal constant WBTC_BORROW_CAP = 70_000;
    uint256 internal constant WBTC_SUPPLY_CAP = 90_000;
    uint256 internal constant WMON_BORROW_CAP = 30_000;
    uint256 internal constant WMON_SUPPLY_CAP = 40_000;
    uint256 internal constant SHMON_BORROW_CAP = 30_000;
    uint256 internal constant SHMON_SUPPLY_CAP = 40_000;
    uint256 internal constant SMON_BORROW_CAP = 5_000;
    uint256 internal constant SMON_SUPPLY_CAP = 7_000;
    uint256 internal constant GMON_BORROW_CAP = 15_000;
    uint256 internal constant GMON_SUPPLY_CAP = 20_000;

    /// @notice Risk fields consumed by `IPoolConfigurator` for a single reserve.
    struct RiskParams {
        /// @notice Underlying asset address.
        address asset;
        /// @notice Loan-to-value ratio in basis points.
        uint256 ltv;
        /// @notice Liquidation threshold in basis points.
        uint256 liquidationThreshold;
        /// @notice Liquidation bonus in basis points (e.g. 10500 = 5% bonus).
        uint256 liquidationBonus;
        /// @notice Reserve factor in basis points.
        uint256 reserveFactor;
        /// @notice Borrow cap in whole tokens (protocol applies decimals internally).
        uint256 borrowCap;
        /// @notice Supply cap in whole tokens (protocol applies decimals internally).
        uint256 supplyCap;
    }

    /// @notice Keccak256 over the UTF-8 bytes of a string without extra allocation.
    /// @param str Input string.
    /// @return hash `keccak256` of the string contents.
    function _hashString(string memory str) private pure returns (bytes32 hash) {
        assembly {
            hash := keccak256(add(str, 0x20), mload(str))
        }
    }

    // Legacy caps for ArbitrumSepolia
    uint256 internal constant LEGACY_DEFAULT_BORROW_CAP = 1_000_000;
    uint256 internal constant LEGACY_DEFAULT_SUPPLY_CAP = 2_000_000;
    uint256 internal constant LEGACY_BTC_BORROW_CAP = 100;
    uint256 internal constant LEGACY_BTC_SUPPLY_CAP = 200;

    /// @notice Maps one token to risk parameters using symbol hashes.
    function _getTokenRiskParams(TokensConfig.Token memory token) private pure returns (RiskParams memory) {
        bytes32 symbolHash = _hashString(token.symbol);

        uint256 ltv = DEFAULT_LTV;
        uint256 liquidationThreshold = DEFAULT_LIQUIDATION_THRESHOLD;
        uint256 liquidationBonus = BLUE_CHIP_LIQUIDATION_BONUS;
        uint256 reserveFactor = RISK_ASSET_RESERVE_FACTOR;
        uint256 supplyCap;
        uint256 borrowCap;

        // Stablecoins
        if (
            symbolHash == _hashString("USDC") || symbolHash == _hashString("AUSD") || symbolHash == _hashString("USDT0")
                || symbolHash == _hashString("WSRUSD") || symbolHash == _hashString("USDT")
                || symbolHash == _hashString("DAI")
        ) {
            ltv = STABLECOIN_LTV;
            liquidationThreshold = STABLECOIN_LIQUIDATION_THRESHOLD;
            liquidationBonus = STABLECOIN_LIQUIDATION_BONUS;
            reserveFactor = BLUE_CHIP_RESERVE_FACTOR;

            if (symbolHash == _hashString("USDC")) {
                supplyCap = USDC_SUPPLY_CAP;
                borrowCap = USDC_BORROW_CAP;
            } else if (symbolHash == _hashString("AUSD")) {
                supplyCap = AUSD_SUPPLY_CAP;
                borrowCap = AUSD_BORROW_CAP;
            } else if (symbolHash == _hashString("USDT0")) {
                supplyCap = USDT0_SUPPLY_CAP;
                borrowCap = USDT0_BORROW_CAP;
            } else if (symbolHash == _hashString("WSRUSD")) {
                supplyCap = WSRUSD_SUPPLY_CAP;
                borrowCap = WSRUSD_BORROW_CAP;
            } else {
                // USDT, DAI (legacy ArbitrumSepolia)
                supplyCap = LEGACY_DEFAULT_SUPPLY_CAP;
                borrowCap = LEGACY_DEFAULT_BORROW_CAP;
            }
        }
        // ETH-like
        else if (symbolHash == _hashString("WETH") || symbolHash == _hashString("wstETH")) {
            ltv = WETH_LTV;
            liquidationThreshold = WETH_LIQUIDATION_THRESHOLD;
            liquidationBonus = BLUE_CHIP_LIQUIDATION_BONUS;
            reserveFactor = BLUE_CHIP_RESERVE_FACTOR;

            if (symbolHash == _hashString("wstETH")) {
                supplyCap = WSTETH_SUPPLY_CAP;
                borrowCap = WSTETH_BORROW_CAP;
            } else {
                supplyCap = WETH_SUPPLY_CAP;
                borrowCap = WETH_BORROW_CAP;
            }
        }
        // BTC
        else if (symbolHash == _hashString("WBTC") || symbolHash == _hashString("BTC")) {
            ltv = BTC_LTV;
            liquidationThreshold = BTC_LIQUIDATION_THRESHOLD;
            liquidationBonus = BLUE_CHIP_LIQUIDATION_BONUS;
            reserveFactor = BLUE_CHIP_RESERVE_FACTOR;

            if (symbolHash == _hashString("WBTC")) {
                supplyCap = WBTC_SUPPLY_CAP;
                borrowCap = WBTC_BORROW_CAP;
            } else {
                // Legacy "BTC" symbol (ArbitrumSepolia)
                supplyCap = LEGACY_BTC_SUPPLY_CAP;
                borrowCap = LEGACY_BTC_BORROW_CAP;
            }
        }
        // MON derivatives — lower LTV/LT due to lower liquidity, higher liquidation bonus
        else if (symbolHash == _hashString("WMON")) {
            ltv = WMON_LTV;
            liquidationThreshold = WMON_LIQUIDATION_THRESHOLD;
            liquidationBonus = VOLATILE_LIQUIDATION_BONUS;
            supplyCap = WMON_SUPPLY_CAP;
            borrowCap = WMON_BORROW_CAP;
        } else if (symbolHash == _hashString("SHMON")) {
            ltv = MON_DERIVATIVE_LTV;
            liquidationThreshold = MON_DERIVATIVE_LIQUIDATION_THRESHOLD;
            liquidationBonus = VOLATILE_LIQUIDATION_BONUS;
            supplyCap = SHMON_SUPPLY_CAP;
            borrowCap = SHMON_BORROW_CAP;
        } else if (symbolHash == _hashString("SMON")) {
            ltv = MON_DERIVATIVE_LTV;
            liquidationThreshold = MON_DERIVATIVE_LIQUIDATION_THRESHOLD;
            liquidationBonus = VOLATILE_LIQUIDATION_BONUS;
            supplyCap = SMON_SUPPLY_CAP;
            borrowCap = SMON_BORROW_CAP;
        } else if (symbolHash == _hashString("GMON")) {
            ltv = MON_DERIVATIVE_LTV;
            liquidationThreshold = MON_DERIVATIVE_LIQUIDATION_THRESHOLD;
            liquidationBonus = VOLATILE_LIQUIDATION_BONUS;
            supplyCap = GMON_SUPPLY_CAP;
            borrowCap = GMON_BORROW_CAP;
        }

        return RiskParams({
            asset: token.asset,
            ltv: ltv,
            liquidationThreshold: liquidationThreshold,
            liquidationBonus: liquidationBonus,
            reserveFactor: reserveFactor,
            borrowCap: borrowCap,
            supplyCap: supplyCap
        });
    }

    /// @notice Builds risk rows for every token on the given network.
    /// @param network Target deployment.
    /// @return Array aligned with `TokensConfig.getTokens(network)` order.
    function getRiskParams(TokensConfig.Network network) internal pure returns (RiskParams[] memory) {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(network);
        RiskParams[] memory params = new RiskParams[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            params[i] = _getTokenRiskParams(tokens[i]);
        }

        return params;
    }
}
