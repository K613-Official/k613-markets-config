// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {RiskParametersFixture} from "./RiskParametersFixture.sol";
import {IRiskParametersConfig} from "../src/config/interface/IRiskParametersConfig.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";

contract InvariantTest is RiskParametersFixture {
    function test_invariant_LTVLessThanLiquidationThreshold() public view {
        TokensConfig.Network[] memory networks = new TokensConfig.Network[](2);
        networks[0] = TokensConfig.Network.ArbitrumSepolia;
        networks[1] = TokensConfig.Network.MonadMainnet;

        for (uint256 n = 0; n < networks.length; n++) {
            IRiskParametersConfig.RiskParams[] memory params =
                IRiskParametersConfig(address(risk)).getRiskParams(networks[n]);

            for (uint256 i = 0; i < params.length; i++) {
                assertLt(params[i].ltv, params[i].liquidationThreshold, "LTV must be less than liquidation threshold");
            }
        }
    }

    function test_invariant_SupplyCapGreaterThanBorrowCap() public view {
        TokensConfig.Network[] memory networks = new TokensConfig.Network[](2);
        networks[0] = TokensConfig.Network.ArbitrumSepolia;
        networks[1] = TokensConfig.Network.MonadMainnet;

        for (uint256 n = 0; n < networks.length; n++) {
            IRiskParametersConfig.RiskParams[] memory params =
                IRiskParametersConfig(address(risk)).getRiskParams(networks[n]);

            for (uint256 i = 0; i < params.length; i++) {
                assertGt(params[i].supplyCap, params[i].borrowCap, "Supply cap must be greater than borrow cap");
            }
        }
    }

    function test_invariant_BasisPointsInValidRange() public view {
        TokensConfig.Network[] memory networks = new TokensConfig.Network[](2);
        networks[0] = TokensConfig.Network.ArbitrumSepolia;
        networks[1] = TokensConfig.Network.MonadMainnet;

        for (uint256 n = 0; n < networks.length; n++) {
            IRiskParametersConfig.RiskParams[] memory params =
                IRiskParametersConfig(address(risk)).getRiskParams(networks[n]);

            for (uint256 i = 0; i < params.length; i++) {
                assertLe(params[i].ltv, risk.BASIS_POINTS(), "LTV must not exceed 100%");
                assertLe(
                    params[i].liquidationThreshold, risk.BASIS_POINTS(), "Liquidation threshold must not exceed 100%"
                );
                assertLe(params[i].reserveFactor, risk.BASIS_POINTS(), "Reserve factor must not exceed 100%");

                assertGe(params[i].ltv, 0, "LTV must be non-negative");
                assertGe(params[i].liquidationThreshold, 0, "Liquidation threshold must be non-negative");
                assertGe(params[i].reserveFactor, 0, "Reserve factor must be non-negative");
            }
        }
    }

    function test_invariant_CapsArePositive() public view {
        TokensConfig.Network[] memory networks = new TokensConfig.Network[](2);
        networks[0] = TokensConfig.Network.ArbitrumSepolia;
        networks[1] = TokensConfig.Network.MonadMainnet;

        for (uint256 n = 0; n < networks.length; n++) {
            IRiskParametersConfig.RiskParams[] memory params =
                IRiskParametersConfig(address(risk)).getRiskParams(networks[n]);

            for (uint256 i = 0; i < params.length; i++) {
                assertGt(params[i].borrowCap, 0, "Borrow cap must be positive");
                assertGt(params[i].supplyCap, 0, "Supply cap must be positive");
            }
        }
    }

    function test_invariant_LiquidationBonusIsValid() public view {
        TokensConfig.Network[] memory networks = new TokensConfig.Network[](2);
        networks[0] = TokensConfig.Network.ArbitrumSepolia;
        networks[1] = TokensConfig.Network.MonadMainnet;

        for (uint256 n = 0; n < networks.length; n++) {
            IRiskParametersConfig.RiskParams[] memory params =
                IRiskParametersConfig(address(risk)).getRiskParams(networks[n]);

            for (uint256 i = 0; i < params.length; i++) {
                assertGe(
                    params[i].liquidationBonus,
                    risk.BASIS_POINTS(),
                    "Liquidation bonus must be at least 1.0x (10000 basis points)"
                );
                assertLe(
                    params[i].liquidationBonus, 15000, "Liquidation bonus should not exceed 1.5x (15000 basis points)"
                );
            }
        }
    }

    function test_invariant_TokensMatchRiskParams() public view {
        TokensConfig.Network[] memory networks = new TokensConfig.Network[](2);
        networks[0] = TokensConfig.Network.ArbitrumSepolia;
        networks[1] = TokensConfig.Network.MonadMainnet;

        for (uint256 n = 0; n < networks.length; n++) {
            TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(networks[n]);
            IRiskParametersConfig.RiskParams[] memory params =
                IRiskParametersConfig(address(risk)).getRiskParams(networks[n]);

            assertEq(tokens.length, params.length, "Number of tokens must match number of risk params");

            for (uint256 i = 0; i < tokens.length; i++) {
                assertEq(tokens[i].asset, params[i].asset, "Token asset must match risk param asset");
            }
        }
    }

    function test_invariant_RiskParamsConsistentAcrossNetworks() public view {
        TokensConfig.Token[] memory tokensSepolia = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);
        IRiskParametersConfig.RiskParams[] memory paramsSepolia =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        TokensConfig.Token[] memory tokensMonad = tokensRegistry.getTokens(TokensConfig.Network.MonadMainnet);
        IRiskParametersConfig.RiskParams[] memory paramsMonad =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.MonadMainnet);

        assertEq(tokensSepolia.length, 5);
        assertEq(tokensMonad.length, 11);

        for (uint256 i = 0; i < tokensSepolia.length; i++) {
            bytes32 sym = keccak256(bytes(tokensSepolia[i].symbol));
            for (uint256 j = 0; j < tokensMonad.length; j++) {
                if (keccak256(bytes(tokensMonad[j].symbol)) != sym) {
                    continue;
                }
                assertEq(paramsSepolia[i].ltv, paramsMonad[j].ltv);
                assertEq(paramsSepolia[i].liquidationThreshold, paramsMonad[j].liquidationThreshold);
                assertEq(paramsSepolia[i].liquidationBonus, paramsMonad[j].liquidationBonus);
                assertEq(paramsSepolia[i].reserveFactor, paramsMonad[j].reserveFactor);
                break;
            }
        }
    }

    function test_invariant_TokenDecimalsAreValid() public view {
        TokensConfig.Network[] memory networks = new TokensConfig.Network[](2);
        networks[0] = TokensConfig.Network.ArbitrumSepolia;
        networks[1] = TokensConfig.Network.MonadMainnet;

        for (uint256 n = 0; n < networks.length; n++) {
            TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(networks[n]);

            for (uint256 i = 0; i < tokens.length; i++) {
                assertGe(tokens[i].decimals, 1, "Decimals must be at least 1");
                assertLe(tokens[i].decimals, 18, "Decimals must not exceed 18");
            }
        }
    }
}
