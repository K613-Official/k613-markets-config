// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {RiskConfig} from "../src/config/RiskConfig.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";

/// @title RiskConfigTest
/// @notice Tests for RiskConfig library
contract RiskConfigTest is Test {
    function test_GetRiskParamsForArbitrumSepolia() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        assertEq(params.length, tokens.length, "Risk params length should match tokens length");

        for (uint256 i = 0; i < params.length; i++) {
            assertEq(params[i].asset, tokens[i].asset, "Asset address should match");
            assertGt(params[i].ltv, 0, "LTV should be greater than 0");
            assertLe(params[i].ltv, RiskConfig.BASIS_POINTS, "LTV should not exceed 100%");
            assertGt(params[i].liquidationThreshold, params[i].ltv, "Liquidation threshold should be greater than LTV");
            assertGt(
                params[i].liquidationBonus, RiskConfig.BASIS_POINTS, "Liquidation bonus should be greater than 100%"
            );
            assertGt(params[i].reserveFactor, 0, "Reserve factor should be greater than 0");
            assertLe(params[i].reserveFactor, RiskConfig.BASIS_POINTS, "Reserve factor should not exceed 100%");
            assertGt(params[i].borrowCap, 0, "Borrow cap should be greater than 0");
            assertGt(params[i].supplyCap, 0, "Supply cap should be greater than 0");
        }
    }

    function test_WETHHasCorrectRiskParams() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        // Find WETH
        uint256 wethIndex = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (keccak256(bytes(tokens[i].symbol)) == keccak256(bytes("WETH"))) {
                wethIndex = i;
                break;
            }
        }

        assertEq(params[wethIndex].ltv, RiskConfig.WETH_LTV, "WETH LTV should match");
        assertEq(
            params[wethIndex].liquidationThreshold,
            RiskConfig.WETH_LIQUIDATION_THRESHOLD,
            "WETH liquidation threshold should match"
        );
        assertEq(
            params[wethIndex].liquidationBonus, RiskConfig.LIQUIDATION_BONUS, "WETH liquidation bonus should match"
        );
        assertEq(
            params[wethIndex].reserveFactor, RiskConfig.BLUE_CHIP_RESERVE_FACTOR, "WETH reserve factor should match"
        );
    }

    function test_BTCHasCorrectRiskParams() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        // Find BTC
        uint256 btcIndex = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (keccak256(bytes(tokens[i].symbol)) == keccak256(bytes("BTC"))) {
                btcIndex = i;
                break;
            }
        }

        assertEq(params[btcIndex].ltv, RiskConfig.BTC_LTV, "BTC LTV should match");
        assertEq(
            params[btcIndex].liquidationThreshold,
            RiskConfig.BTC_LIQUIDATION_THRESHOLD,
            "BTC liquidation threshold should match"
        );

        // BTC should have lower caps
        uint256 expectedBorrowCap = RiskConfig.BTC_BORROW_CAP * (10 ** tokens[btcIndex].decimals);
        uint256 expectedSupplyCap = RiskConfig.BTC_SUPPLY_CAP * (10 ** tokens[btcIndex].decimals);
        assertEq(params[btcIndex].borrowCap, expectedBorrowCap, "BTC borrow cap should match");
        assertEq(params[btcIndex].supplyCap, expectedSupplyCap, "BTC supply cap should match");
    }

    function test_StablecoinsHaveCorrectRiskParams() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        string[3] memory stablecoins = ["USDC", "USDT", "DAI"];

        for (uint256 s = 0; s < stablecoins.length; s++) {
            for (uint256 i = 0; i < tokens.length; i++) {
                if (keccak256(bytes(tokens[i].symbol)) == keccak256(bytes(stablecoins[s]))) {
                    assertEq(
                        params[i].ltv,
                        RiskConfig.STABLECOIN_LTV,
                        string.concat("Stablecoin LTV should match for ", stablecoins[s])
                    );
                    assertEq(
                        params[i].liquidationThreshold,
                        RiskConfig.STABLECOIN_LIQUIDATION_THRESHOLD,
                        string.concat("Stablecoin liquidation threshold should match for ", stablecoins[s])
                    );
                    break;
                }
            }
        }
    }

    function test_LiquidationThresholdGreaterThanLTV() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < params.length; i++) {
            assertGt(
                params[i].liquidationThreshold,
                params[i].ltv,
                "Liquidation threshold must be greater than LTV for all assets"
            );
        }
    }

    function test_AllAssetsHaveBlueChipReserveFactor() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < params.length; i++) {
            assertEq(
                params[i].reserveFactor,
                RiskConfig.BLUE_CHIP_RESERVE_FACTOR,
                "All assets should have blue-chip reserve factor (25%)"
            );
        }
    }

    function test_CapsAreCalculatedCorrectly() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < params.length; i++) {
            uint8 decimals = tokens[i].decimals;
            bytes32 symbolHash = keccak256(bytes(tokens[i].symbol));
            bytes32 btcHash = keccak256(bytes("BTC"));

            if (symbolHash == btcHash) {
                // BTC has special caps
                uint256 expectedBorrowCap = RiskConfig.BTC_BORROW_CAP * (10 ** decimals);
                uint256 expectedSupplyCap = RiskConfig.BTC_SUPPLY_CAP * (10 ** decimals);
                assertEq(params[i].borrowCap, expectedBorrowCap, "BTC borrow cap calculation should match");
                assertEq(params[i].supplyCap, expectedSupplyCap, "BTC supply cap calculation should match");
            } else {
                // Other tokens use default multipliers
                uint256 expectedBorrowCap = RiskConfig.DEFAULT_BORROW_CAP * (10 ** decimals);
                uint256 expectedSupplyCap = RiskConfig.DEFAULT_SUPPLY_CAP * (10 ** decimals);
                assertEq(params[i].borrowCap, expectedBorrowCap, "Default borrow cap calculation should match");
                assertEq(params[i].supplyCap, expectedSupplyCap, "Default supply cap calculation should match");
            }
        }
    }

    function test_GetRiskParamsForMonadMainnet() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.MonadMainnet);
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.MonadMainnet);

        assertEq(params.length, tokens.length, "Risk params length should match tokens length");
        assertEq(params.length, 5, "Should have 5 tokens");
    }
}
