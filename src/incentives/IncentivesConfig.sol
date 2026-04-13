// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokensConfig} from "../config/TokensConfig.sol";

/// @title IncentivesConfig
/// @notice Emission weights and schedule for xK613 supply incentives
/// @dev Weights are in basis points (total = 10000 = 100%)
contract IncentivesConfig {
    error Unauthorized();
    error InvalidAdmin();
    error InvalidRewardShares();
    error InvalidWeightsSum();
    error InvalidWeightsLength();
    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);
    event RewardSharesUpdated(uint256 supplyRewardShareBps, uint256 borrowRewardShareBps);
    event WeightsUpdated(uint256[] weights);

    uint256 public constant WEIGHT_BPS = 10_000;
    uint256 public supplyRewardShareBps;
    uint256 public borrowRewardShareBps;

    // Year 1: 25,000,000 xK613
    uint256 public constant YEAR1_TOTAL = 25_000_000e18;
    // Year 2: 10,000,000 xK613
    uint256 public constant YEAR2_TOTAL = 10_000_000e18;
    // Year 3: 5,000,000 xK613
    uint256 public constant YEAR3_TOTAL = 5_000_000e18;

    address public admin;
    uint256[11] private weights;

    struct EmissionConfig {
        address asset;
        string symbol;
        uint88 supplyEmissionPerSecond;
        uint88 borrowEmissionPerSecond;
        uint256 weight;
    }

    constructor(address initialAdmin) {
        if (initialAdmin == address(0)) revert InvalidAdmin();
        admin = initialAdmin;
        supplyRewardShareBps = 6500;
        borrowRewardShareBps = 3500;
        weights[0] = 2100;
        weights[1] = 1900;
        weights[2] = 750;
        weights[3] = 850;
        weights[4] = 1500;
        weights[5] = 1300;
        weights[6] = 1050;
        weights[7] = 200;
        weights[8] = 150;
        weights[9] = 100;
        weights[10] = 100;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert Unauthorized();
        _;
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert InvalidAdmin();
        address previousAdmin = admin;
        admin = newAdmin;
        emit AdminUpdated(previousAdmin, newAdmin);
    }

    function setRewardShares(uint256 newSupplyRewardShareBps, uint256 newBorrowRewardShareBps) external onlyAdmin {
        if (newSupplyRewardShareBps + newBorrowRewardShareBps != WEIGHT_BPS) revert InvalidRewardShares();
        supplyRewardShareBps = newSupplyRewardShareBps;
        borrowRewardShareBps = newBorrowRewardShareBps;
        emit RewardSharesUpdated(newSupplyRewardShareBps, newBorrowRewardShareBps);
    }

    function setWeights(uint256[] calldata newWeights) external onlyAdmin {
        if (newWeights.length != 11) revert InvalidWeightsLength();
        uint256 sum = 0;
        for (uint256 i = 0; i < newWeights.length; i++) {
            sum += newWeights[i];
        }
        if (sum != WEIGHT_BPS) revert InvalidWeightsSum();
        weights[0] = newWeights[0];
        weights[1] = newWeights[1];
        weights[2] = newWeights[2];
        weights[3] = newWeights[3];
        weights[4] = newWeights[4];
        weights[5] = newWeights[5];
        weights[6] = newWeights[6];
        weights[7] = newWeights[7];
        weights[8] = newWeights[8];
        weights[9] = newWeights[9];
        weights[10] = newWeights[10];
        emit WeightsUpdated(newWeights);
    }

    function getWeights() external view returns (uint256[] memory) {
        return _getWeights();
    }

    /// @notice Returns emission configs for all Monad mainnet tokens
    /// @param yearlyTotal Total xK613 emission for the year (e.g. YEAR1_TOTAL)
    function getEmissionConfigs(uint256 yearlyTotal) external view returns (EmissionConfig[] memory configs) {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.MonadMainnet);
        uint256[] memory configuredWeights = _getWeights();

        configs = new EmissionConfig[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 assetYearly = (yearlyTotal * configuredWeights[i]) / WEIGHT_BPS;
            uint256 supplyYearly = (assetYearly * supplyRewardShareBps) / WEIGHT_BPS;
            uint256 borrowYearly = (assetYearly * borrowRewardShareBps) / WEIGHT_BPS;
            uint88 supplyPerSecond = uint88(supplyYearly / 365 days);
            uint88 borrowPerSecond = uint88(borrowYearly / 365 days);

            configs[i] = EmissionConfig({
                asset: tokens[i].asset,
                symbol: tokens[i].symbol,
                supplyEmissionPerSecond: supplyPerSecond,
                borrowEmissionPerSecond: borrowPerSecond,
                weight: configuredWeights[i]
            });
        }
    }

    function _getWeights() private view returns (uint256[] memory values) {
        values = new uint256[](11);
        values[0] = weights[0];
        values[1] = weights[1];
        values[2] = weights[2];
        values[3] = weights[3];
        values[4] = weights[4];
        values[5] = weights[5];
        values[6] = weights[6];
        values[7] = weights[7];
        values[8] = weights[8];
        values[9] = weights[9];
        values[10] = weights[10];
    }
}
