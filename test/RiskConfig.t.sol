// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
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

        uint256 wethIndex = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (keccak256(bytes(tokens[i].symbol)) == keccak256(bytes("WETH"))) {
                wethIndex = i;
                break;
            }
        }

        assertEq(params[wethIndex].ltv, RiskConfig.WETH_LTV);
        assertEq(params[wethIndex].liquidationThreshold, RiskConfig.WETH_LIQUIDATION_THRESHOLD);
        assertEq(params[wethIndex].liquidationBonus, RiskConfig.BLUE_CHIP_LIQUIDATION_BONUS);
        assertEq(params[wethIndex].reserveFactor, RiskConfig.BLUE_CHIP_RESERVE_FACTOR);
    }

    function test_BTCHasCorrectRiskParams() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        uint256 btcIndex = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (keccak256(bytes(tokens[i].symbol)) == keccak256(bytes("BTC"))) {
                btcIndex = i;
                break;
            }
        }

        assertEq(params[btcIndex].ltv, RiskConfig.BTC_LTV);
        assertEq(params[btcIndex].liquidationThreshold, RiskConfig.BTC_LIQUIDATION_THRESHOLD);
        assertEq(params[btcIndex].borrowCap, RiskConfig.LEGACY_BTC_BORROW_CAP);
        assertEq(params[btcIndex].supplyCap, RiskConfig.LEGACY_BTC_SUPPLY_CAP);
    }

    function test_StablecoinsHaveCorrectRiskParams() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        string[3] memory stablecoins = ["USDC", "USDT", "DAI"];

        for (uint256 s = 0; s < stablecoins.length; s++) {
            for (uint256 i = 0; i < tokens.length; i++) {
                if (keccak256(bytes(tokens[i].symbol)) == keccak256(bytes(stablecoins[s]))) {
                    assertEq(params[i].ltv, RiskConfig.STABLECOIN_LTV);
                    assertEq(params[i].liquidationThreshold, RiskConfig.STABLECOIN_LIQUIDATION_THRESHOLD);
                    break;
                }
            }
        }
    }

    function test_LiquidationThresholdGreaterThanLTV() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < params.length; i++) {
            assertGt(params[i].liquidationThreshold, params[i].ltv);
        }
    }

    function test_GetRiskParamsForMonadMainnet() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.MonadMainnet);
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.MonadMainnet);

        assertEq(params.length, tokens.length);
        assertEq(params.length, 11, "Should have 11 tokens");

        for (uint256 i = 0; i < params.length; i++) {
            assertGt(params[i].ltv, 0);
            assertGt(params[i].liquidationThreshold, params[i].ltv);
            assertGt(params[i].supplyCap, 0);
            assertGt(params[i].borrowCap, 0);
        }
    }

    function test_MonadMainnetCaps() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.MonadMainnet);

        // USDC
        assertEq(params[0].supplyCap, RiskConfig.USDC_SUPPLY_CAP);
        assertEq(params[0].borrowCap, RiskConfig.USDC_BORROW_CAP);
        // AUSD
        assertEq(params[1].supplyCap, RiskConfig.AUSD_SUPPLY_CAP);
        assertEq(params[1].borrowCap, RiskConfig.AUSD_BORROW_CAP);
        // wstETH
        assertEq(params[2].supplyCap, RiskConfig.WSTETH_SUPPLY_CAP);
        assertEq(params[2].borrowCap, RiskConfig.WSTETH_BORROW_CAP);
        // WETH
        assertEq(params[3].supplyCap, RiskConfig.WETH_SUPPLY_CAP);
        assertEq(params[3].borrowCap, RiskConfig.WETH_BORROW_CAP);
        // USDT0
        assertEq(params[4].supplyCap, RiskConfig.USDT0_SUPPLY_CAP);
        assertEq(params[4].borrowCap, RiskConfig.USDT0_BORROW_CAP);
        // WSRUSD
        assertEq(params[5].supplyCap, RiskConfig.WSRUSD_SUPPLY_CAP);
        assertEq(params[5].borrowCap, RiskConfig.WSRUSD_BORROW_CAP);
        // WBTC
        assertEq(params[6].supplyCap, RiskConfig.WBTC_SUPPLY_CAP);
        assertEq(params[6].borrowCap, RiskConfig.WBTC_BORROW_CAP);
        assertEq(params[6].ltv, RiskConfig.BTC_LTV);
        // WMON
        assertEq(params[7].supplyCap, RiskConfig.WMON_SUPPLY_CAP);
        assertEq(params[7].borrowCap, RiskConfig.WMON_BORROW_CAP);
        // SHMON
        assertEq(params[8].supplyCap, RiskConfig.SHMON_SUPPLY_CAP);
        assertEq(params[8].borrowCap, RiskConfig.SHMON_BORROW_CAP);
        // SMON
        assertEq(params[9].supplyCap, RiskConfig.SMON_SUPPLY_CAP);
        assertEq(params[9].borrowCap, RiskConfig.SMON_BORROW_CAP);
        // GMON
        assertEq(params[10].supplyCap, RiskConfig.GMON_SUPPLY_CAP);
        assertEq(params[10].borrowCap, RiskConfig.GMON_BORROW_CAP);
    }
}
