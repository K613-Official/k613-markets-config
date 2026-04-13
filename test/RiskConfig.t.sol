// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {RiskParametersFixture} from "./RiskParametersFixture.sol";
import {IRiskParametersConfig} from "../src/config/interface/IRiskParametersConfig.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";

contract RiskConfigTest is RiskParametersFixture {
    function test_GetRiskParamsForArbitrumSepolia() public view {
        IRiskParametersConfig.RiskParams[] memory params =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.ArbitrumSepolia);
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        assertEq(params.length, tokens.length, "Risk params length should match tokens length");

        for (uint256 i = 0; i < params.length; i++) {
            assertEq(params[i].asset, tokens[i].asset, "Asset address should match");
            assertGt(params[i].ltv, 0, "LTV should be greater than 0");
            assertLe(params[i].ltv, risk.BASIS_POINTS(), "LTV should not exceed 100%");
            assertGt(params[i].liquidationThreshold, params[i].ltv, "Liquidation threshold should be greater than LTV");
            assertGt(params[i].liquidationBonus, risk.BASIS_POINTS(), "Liquidation bonus should be greater than 100%");
            assertGt(params[i].reserveFactor, 0, "Reserve factor should be greater than 0");
            assertLe(params[i].reserveFactor, risk.BASIS_POINTS(), "Reserve factor should not exceed 100%");
            assertGt(params[i].borrowCap, 0, "Borrow cap should be greater than 0");
            assertGt(params[i].supplyCap, 0, "Supply cap should be greater than 0");
        }
    }

    function test_WETHHasCorrectRiskParams() public view {
        IRiskParametersConfig.RiskParams[] memory params =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.ArbitrumSepolia);
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        uint256 wethIndex = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (keccak256(bytes(tokens[i].symbol)) == keccak256(bytes("WETH"))) {
                wethIndex = i;
                break;
            }
        }

        (uint256 ltv, uint256 lt, uint256 lb, uint256 rf) = risk.wethLikeRisk();
        assertEq(params[wethIndex].ltv, ltv);
        assertEq(params[wethIndex].liquidationThreshold, lt);
        assertEq(params[wethIndex].liquidationBonus, lb);
        assertEq(params[wethIndex].reserveFactor, rf);
    }

    function test_BTCHasCorrectRiskParams() public view {
        IRiskParametersConfig.RiskParams[] memory params =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.ArbitrumSepolia);
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        uint256 btcIndex = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (keccak256(bytes(tokens[i].symbol)) == keccak256(bytes("BTC"))) {
                btcIndex = i;
                break;
            }
        }

        (uint256 ltv, uint256 lt, uint256 lb, uint256 rf) = risk.btcRisk();
        assertEq(params[btcIndex].ltv, ltv);
        assertEq(params[btcIndex].liquidationThreshold, lt);
        assertEq(params[btcIndex].borrowCap, risk.legacyBtcBorrowCap());
        assertEq(params[btcIndex].supplyCap, risk.legacyBtcSupplyCap());
        assertEq(params[btcIndex].liquidationBonus, lb);
        assertEq(params[btcIndex].reserveFactor, rf);
    }

    function test_StablecoinsHaveCorrectRiskParams() public view {
        IRiskParametersConfig.RiskParams[] memory params =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.ArbitrumSepolia);
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        string[3] memory stablecoins = ["USDC", "USDT", "DAI"];

        (uint256 ltv, uint256 lt,,) = risk.stablecoinRisk();

        for (uint256 s = 0; s < stablecoins.length; s++) {
            for (uint256 i = 0; i < tokens.length; i++) {
                if (keccak256(bytes(tokens[i].symbol)) == keccak256(bytes(stablecoins[s]))) {
                    assertEq(params[i].ltv, ltv);
                    assertEq(params[i].liquidationThreshold, lt);
                    break;
                }
            }
        }
    }

    function test_LiquidationThresholdGreaterThanLTV() public view {
        IRiskParametersConfig.RiskParams[] memory params =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < params.length; i++) {
            assertGt(params[i].liquidationThreshold, params[i].ltv);
        }
    }

    function test_GetRiskParamsForMonadMainnet() public view {
        IRiskParametersConfig.RiskParams[] memory params =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.MonadMainnet);
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.MonadMainnet);

        assertEq(params.length, tokens.length);
        assertEq(params.length, 11, "Should have 11 tokens");

        for (uint256 i = 0; i < params.length; i++) {
            assertGt(params[i].ltv, 0);
            assertGt(params[i].liquidationThreshold, params[i].ltv);
            assertGt(params[i].supplyCap, 0);
            assertGt(params[i].borrowCap, 0);
        }
    }

    function test_MonadMainnetCaps() public view {
        IRiskParametersConfig.RiskParams[] memory params =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.MonadMainnet);

        (uint256 usdcB, uint256 usdcS) = risk.getCaps("USDC");
        (uint256 ausdB, uint256 ausdS) = risk.getCaps("AUSD");
        (uint256 wstB, uint256 wstS) = risk.getCaps("wstETH");
        (uint256 wethB, uint256 wethS) = risk.getCaps("WETH");
        (uint256 usdt0B, uint256 usdt0S) = risk.getCaps("USDT0");
        (uint256 wsB, uint256 wsS) = risk.getCaps("WSRUSD");
        (uint256 wbtcB, uint256 wbtcS) = risk.getCaps("WBTC");
        (uint256 wmonB, uint256 wmonS) = risk.getCaps("WMON");
        (uint256 shB, uint256 shS) = risk.getCaps("SHMON");
        (uint256 smB, uint256 smS) = risk.getCaps("SMON");
        (uint256 gmB, uint256 gmS) = risk.getCaps("GMON");

        assertEq(params[0].supplyCap, usdcS);
        assertEq(params[0].borrowCap, usdcB);
        assertEq(params[1].supplyCap, ausdS);
        assertEq(params[1].borrowCap, ausdB);
        assertEq(params[2].supplyCap, wstS);
        assertEq(params[2].borrowCap, wstB);
        assertEq(params[3].supplyCap, wethS);
        assertEq(params[3].borrowCap, wethB);
        assertEq(params[4].supplyCap, usdt0S);
        assertEq(params[4].borrowCap, usdt0B);
        assertEq(params[5].supplyCap, wsS);
        assertEq(params[5].borrowCap, wsB);
        assertEq(params[6].supplyCap, wbtcS);
        assertEq(params[6].borrowCap, wbtcB);
        (uint256 btcLtv,,,) = risk.btcRisk();
        assertEq(params[6].ltv, btcLtv);
        assertEq(params[7].supplyCap, wmonS);
        assertEq(params[7].borrowCap, wmonB);
        assertEq(params[8].supplyCap, shS);
        assertEq(params[8].borrowCap, shB);
        assertEq(params[9].supplyCap, smS);
        assertEq(params[9].borrowCap, smB);
        assertEq(params[10].supplyCap, gmS);
        assertEq(params[10].borrowCap, gmB);
    }
}
