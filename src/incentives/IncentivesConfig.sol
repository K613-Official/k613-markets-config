// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokensConfig} from "../config/TokensConfig.sol";

/// @title IncentivesConfig
/// @notice Emission weights and schedule for xK613 supply incentives
/// @dev Weights are in basis points (total = 10000 = 100%)
///      Emission per second = (yearlyEmission × weight) / (365 days × 10000)
library IncentivesConfig {
    uint256 internal constant WEIGHT_BPS = 10_000;

    // Year 1: 25,000,000 xK613
    uint256 internal constant YEAR1_TOTAL = 25_000_000e18;
    // Year 2: 10,000,000 xK613
    uint256 internal constant YEAR2_TOTAL = 10_000_000e18;
    // Year 3: 5,000,000 xK613
    uint256 internal constant YEAR3_TOTAL = 5_000_000e18;

    // Per-asset weights (basis points, sum = 10000)
    uint256 internal constant USDC_WEIGHT = 2100;    // 21%
    uint256 internal constant AUSD_WEIGHT = 1900;    // 19%
    uint256 internal constant WSTETH_WEIGHT = 750;   // 7.5%
    uint256 internal constant WETH_WEIGHT = 850;     // 8.5%
    uint256 internal constant USDT0_WEIGHT = 1500;   // 15%
    uint256 internal constant WSRUSD_WEIGHT = 1300;  // 13%
    uint256 internal constant WBTC_WEIGHT = 1050;    // 10.5%
    uint256 internal constant WMON_WEIGHT = 200;     // 2%
    uint256 internal constant SHMON_WEIGHT = 150;    // 1.5%
    uint256 internal constant SMON_WEIGHT = 100;     // 1%
    uint256 internal constant GMON_WEIGHT = 100;     // 1%

    struct EmissionConfig {
        address asset;
        string symbol;
        uint88 emissionPerSecond;
        uint256 weight;
    }

    /// @notice Returns emission configs for all Monad mainnet tokens
    /// @param yearlyTotal Total xK613 emission for the year (e.g. YEAR1_TOTAL)
    function getEmissionConfigs(uint256 yearlyTotal)
        internal
        pure
        returns (EmissionConfig[] memory configs)
    {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.MonadMainnet);
        uint256[] memory weights = _getWeights();

        configs = new EmissionConfig[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 assetYearly = (yearlyTotal * weights[i]) / WEIGHT_BPS;
            uint88 perSecond = uint88(assetYearly / 365 days);

            configs[i] = EmissionConfig({
                asset: tokens[i].asset,
                symbol: tokens[i].symbol,
                emissionPerSecond: perSecond,
                weight: weights[i]
            });
        }
    }

    function _getWeights() private pure returns (uint256[] memory w) {
        w = new uint256[](11);
        w[0] = USDC_WEIGHT;
        w[1] = AUSD_WEIGHT;
        w[2] = WSTETH_WEIGHT;
        w[3] = WETH_WEIGHT;
        w[4] = USDT0_WEIGHT;
        w[5] = WSRUSD_WEIGHT;
        w[6] = WBTC_WEIGHT;
        w[7] = WMON_WEIGHT;
        w[8] = SHMON_WEIGHT;
        w[9] = SMON_WEIGHT;
        w[10] = GMON_WEIGHT;
    }
}
