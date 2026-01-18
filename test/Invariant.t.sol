// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {RiskConfig} from "../src/config/RiskConfig.sol";

/// @title InvariantTests
/// @notice Invariant tests for configuration consistency
/// @dev These invariants must hold for all networks and all tokens
/// @dev Note: These are property tests for static configuration data, not stateful invariant tests
contract InvariantTest is Test {
    /// @notice Invariant: LTV must always be less than liquidation threshold
    /// @dev This is a fundamental safety requirement in DeFi
    function test_invariant_LTVLessThanLiquidationThreshold() public pure {
        TokensConfig.Network[] memory networks = new TokensConfig.Network[](2);
        networks[0] = TokensConfig.Network.ArbitrumSepolia;
        networks[1] = TokensConfig.Network.MonadMainnet;

        for (uint256 n = 0; n < networks.length; n++) {
            RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(networks[n]);

            for (uint256 i = 0; i < params.length; i++) {
                assertLt(params[i].ltv, params[i].liquidationThreshold, "LTV must be less than liquidation threshold");
            }
        }
    }

    /// @notice Invariant: Supply cap must always be greater than borrow cap
    /// @dev Users can't borrow more than the supply cap allows
    function test_invariant_SupplyCapGreaterThanBorrowCap() public pure {
        TokensConfig.Network[] memory networks = new TokensConfig.Network[](2);
        networks[0] = TokensConfig.Network.ArbitrumSepolia;
        networks[1] = TokensConfig.Network.MonadMainnet;

        for (uint256 n = 0; n < networks.length; n++) {
            RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(networks[n]);

            for (uint256 i = 0; i < params.length; i++) {
                assertGt(params[i].supplyCap, params[i].borrowCap, "Supply cap must be greater than borrow cap");
            }
        }
    }

    /// @notice Invariant: All basis point values must be within valid range [0, 10000]
    /// @dev Basis points represent percentages (10000 = 100%)
    function test_invariant_BasisPointsInValidRange() public pure {
        TokensConfig.Network[] memory networks = new TokensConfig.Network[](2);
        networks[0] = TokensConfig.Network.ArbitrumSepolia;
        networks[1] = TokensConfig.Network.MonadMainnet;

        for (uint256 n = 0; n < networks.length; n++) {
            RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(networks[n]);

            for (uint256 i = 0; i < params.length; i++) {
                assertLe(params[i].ltv, RiskConfig.BASIS_POINTS, "LTV must not exceed 100%");
                assertLe(
                    params[i].liquidationThreshold,
                    RiskConfig.BASIS_POINTS,
                    "Liquidation threshold must not exceed 100%"
                );
                assertLe(params[i].reserveFactor, RiskConfig.BASIS_POINTS, "Reserve factor must not exceed 100%");

                assertGe(params[i].ltv, 0, "LTV must be non-negative");
                assertGe(params[i].liquidationThreshold, 0, "Liquidation threshold must be non-negative");
                assertGe(params[i].reserveFactor, 0, "Reserve factor must be non-negative");
            }
        }
    }

    /// @notice Invariant: All caps must be positive
    /// @dev Zero caps would make the asset unusable
    function test_invariant_CapsArePositive() public pure {
        TokensConfig.Network[] memory networks = new TokensConfig.Network[](2);
        networks[0] = TokensConfig.Network.ArbitrumSepolia;
        networks[1] = TokensConfig.Network.MonadMainnet;

        for (uint256 n = 0; n < networks.length; n++) {
            RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(networks[n]);

            for (uint256 i = 0; i < params.length; i++) {
                assertGt(params[i].borrowCap, 0, "Borrow cap must be positive");
                assertGt(params[i].supplyCap, 0, "Supply cap must be positive");
            }
        }
    }

    /// @notice Invariant: Liquidation bonus must be >= 10000 (1.0x multiplier, no penalty)
    /// @dev Liquidation bonus in Aave is represented as basis points where 10000 = 1.0x
    ///      A value of 10500 means 1.05x multiplier (5% bonus)
    function test_invariant_LiquidationBonusIsValid() public pure {
        TokensConfig.Network[] memory networks = new TokensConfig.Network[](2);
        networks[0] = TokensConfig.Network.ArbitrumSepolia;
        networks[1] = TokensConfig.Network.MonadMainnet;

        for (uint256 n = 0; n < networks.length; n++) {
            RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(networks[n]);

            for (uint256 i = 0; i < params.length; i++) {
                assertGe(
                    params[i].liquidationBonus,
                    RiskConfig.BASIS_POINTS,
                    "Liquidation bonus must be at least 1.0x (10000 basis points)"
                );
                // Reasonable upper bound: 15000 = 1.5x (50% bonus)
                assertLe(
                    params[i].liquidationBonus, 15000, "Liquidation bonus should not exceed 1.5x (15000 basis points)"
                );
            }
        }
    }

    /// @notice Invariant: Number of tokens matches number of risk params
    /// @dev Every token must have corresponding risk parameters
    function test_invariant_TokensMatchRiskParams() public pure {
        TokensConfig.Network[] memory networks = new TokensConfig.Network[](2);
        networks[0] = TokensConfig.Network.ArbitrumSepolia;
        networks[1] = TokensConfig.Network.MonadMainnet;

        for (uint256 n = 0; n < networks.length; n++) {
            TokensConfig.Token[] memory tokens = TokensConfig.getTokens(networks[n]);
            RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(networks[n]);

            assertEq(tokens.length, params.length, "Number of tokens must match number of risk params");

            // Verify each token has a corresponding risk param
            for (uint256 i = 0; i < tokens.length; i++) {
                assertEq(tokens[i].asset, params[i].asset, "Token asset must match risk param asset");
            }
        }
    }

    /// @notice Invariant: Risk parameters are consistent across networks for same token symbols
    /// @dev Same token type (WETH, WBTC, etc.) should have same risk parameters regardless of network
    ///      Note: This invariant may not hold if different networks need different parameters
    ///      Currently it's a check that we intentionally set same params for same tokens
    function test_invariant_RiskParamsConsistentAcrossNetworks() public pure {
        TokensConfig.Token[] memory tokensSepolia = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);
        RiskConfig.RiskParams[] memory paramsSepolia = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        TokensConfig.Token[] memory tokensMonad = TokensConfig.getTokens(TokensConfig.Network.MonadMainnet);
        RiskConfig.RiskParams[] memory paramsMonad = RiskConfig.getRiskParams(TokensConfig.Network.MonadMainnet);

        // Both networks should have same number of tokens
        assertEq(tokensSepolia.length, tokensMonad.length, "Both networks should have same number of tokens");

        // For each token, risk parameters should be the same (except addresses)
        for (uint256 i = 0; i < tokensSepolia.length; i++) {
            assertEq(tokensSepolia[i].symbol, tokensMonad[i].symbol, "Token symbols should match across networks");

            assertEq(paramsSepolia[i].ltv, paramsMonad[i].ltv, "LTV should match across networks");
            assertEq(
                paramsSepolia[i].liquidationThreshold,
                paramsMonad[i].liquidationThreshold,
                "Liquidation threshold should match across networks"
            );
            assertEq(
                paramsSepolia[i].liquidationBonus,
                paramsMonad[i].liquidationBonus,
                "Liquidation bonus should match across networks"
            );
            assertEq(
                paramsSepolia[i].reserveFactor,
                paramsMonad[i].reserveFactor,
                "Reserve factor should match across networks"
            );
        }
    }

    /// @notice Invariant: Decimals are within valid range [1, 18]
    /// @dev Solidity supports up to 18 decimals
    function test_invariant_TokenDecimalsAreValid() public pure {
        TokensConfig.Network[] memory networks = new TokensConfig.Network[](2);
        networks[0] = TokensConfig.Network.ArbitrumSepolia;
        networks[1] = TokensConfig.Network.MonadMainnet;

        for (uint256 n = 0; n < networks.length; n++) {
            TokensConfig.Token[] memory tokens = TokensConfig.getTokens(networks[n]);

            for (uint256 i = 0; i < tokens.length; i++) {
                assertGe(tokens[i].decimals, 1, "Decimals must be at least 1");
                assertLe(tokens[i].decimals, 18, "Decimals must not exceed 18");
            }
        }
    }
}
