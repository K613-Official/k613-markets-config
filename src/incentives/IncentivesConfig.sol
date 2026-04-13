// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokensConfig} from "../config/TokensConfig.sol";
import {ITokensRegistry} from "../config/interface/ITokensRegistry.sol";

/// @title IncentivesConfig
/// @notice Emission weights and schedule for xK613 supply incentives
/// @dev Weights are in basis points (total = 10000 = 100%)
contract IncentivesConfig {
    error Unauthorized();
    error InvalidAdmin();
    error InvalidRewardShares();
    error InvalidWeightsSum();
    error InvalidWeightsLength();
    error InvalidTokensRegistry();
    error WeightsLengthMismatch();

    /// @notice Emitted when admin rights are transferred.
    /// @param previousAdmin Previous admin address.
    /// @param newAdmin New admin address.
    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);

    /// @notice Emitted when supply/borrow reward shares are updated.
    /// @param supplyRewardShareBps New supply reward share in basis points.
    /// @param borrowRewardShareBps New borrow reward share in basis points.
    event RewardSharesUpdated(uint256 supplyRewardShareBps, uint256 borrowRewardShareBps);

    /// @notice Emitted when per-asset weights are updated.
    /// @param weights New per-asset weights in basis points.
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
    ITokensRegistry public immutable tokensRegistry;
    uint256[] private weights;

    struct EmissionConfig {
        address asset;
        string symbol;
        uint88 supplyEmissionPerSecond;
        uint88 borrowEmissionPerSecond;
        uint256 weight;
    }

    /// @notice Deploys incentives config with default weights and reward split.
    /// @param initialAdmin Address allowed to update config values.
    constructor(address initialAdmin, address tokensRegistry_) {
        if (initialAdmin == address(0)) revert InvalidAdmin();
        if (tokensRegistry_ == address(0)) revert InvalidTokensRegistry();
        admin = initialAdmin;
        tokensRegistry = ITokensRegistry(tokensRegistry_);
        supplyRewardShareBps = 6500;
        borrowRewardShareBps = 3500;
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.MonadMainnet);
        uint256[11] memory seed = [uint256(2100), 1900, 750, 850, 1500, 1300, 1050, 200, 150, 100, 100];
        if (tokens.length != seed.length) revert WeightsLengthMismatch();
        for (uint256 i = 0; i < seed.length; i++) {
            weights.push(seed[i]);
        }
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert Unauthorized();
        _;
    }

    /// @notice Updates config admin.
    /// @param newAdmin Address that receives admin permissions.
    function setAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert InvalidAdmin();
        address previousAdmin = admin;
        admin = newAdmin;
        emit AdminUpdated(previousAdmin, newAdmin);
    }

    /// @notice Updates supply and borrow reward shares in basis points.
    /// @param newSupplyRewardShareBps Share allocated to suppliers.
    /// @param newBorrowRewardShareBps Share allocated to borrowers.
    function setRewardShares(uint256 newSupplyRewardShareBps, uint256 newBorrowRewardShareBps) external onlyAdmin {
        if (newSupplyRewardShareBps + newBorrowRewardShareBps != WEIGHT_BPS) revert InvalidRewardShares();
        supplyRewardShareBps = newSupplyRewardShareBps;
        borrowRewardShareBps = newBorrowRewardShareBps;
        emit RewardSharesUpdated(newSupplyRewardShareBps, newBorrowRewardShareBps);
    }

    /// @notice Updates per-asset emission weights.
    /// @param newWeights Asset weights in basis points, length must be 11 and sum must be 10000.
    function setWeights(uint256[] calldata newWeights) external onlyAdmin {
        uint256 n = tokensRegistry.tokenCount(TokensConfig.Network.MonadMainnet);
        if (newWeights.length != n) revert InvalidWeightsLength();
        uint256 sum = 0;
        for (uint256 i = 0; i < newWeights.length; i++) {
            sum += newWeights[i];
        }
        if (sum != WEIGHT_BPS) revert InvalidWeightsSum();
        delete weights;
        for (uint256 i = 0; i < newWeights.length; i++) {
            weights.push(newWeights[i]);
        }
        emit WeightsUpdated(newWeights);
    }

    /// @notice Returns current per-asset emission weights.
    /// @return Current weights array.
    function getWeights() external view returns (uint256[] memory) {
        return _getWeights();
    }

    /// @notice Returns emission configs for all Monad mainnet tokens
    /// @param yearlyTotal Total xK613 emission for the year (e.g. YEAR1_TOTAL)
    function getEmissionConfigs(uint256 yearlyTotal) external view returns (EmissionConfig[] memory configs) {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.MonadMainnet);
        uint256[] memory configuredWeights = _getWeights();
        if (configuredWeights.length != tokens.length) revert WeightsLengthMismatch();

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
        values = new uint256[](weights.length);
        for (uint256 i = 0; i < weights.length; i++) {
            values[i] = weights[i];
        }
    }
}
