// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {RiskParametersFixture} from "./RiskParametersFixture.sol";
import {IRiskParametersConfig} from "../src/config/interface/IRiskParametersConfig.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {NetworkConfig} from "../src/config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";

contract IntegrationTest is RiskParametersFixture {
    function test_TokensAndRiskParamsMatch() public view {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);
        IRiskParametersConfig.RiskParams[] memory riskParams =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        assertEq(tokens.length, riskParams.length, "Tokens and risk params should have same length");

        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(tokens[i].asset, riskParams[i].asset, "Asset addresses should match");
        }
    }

    function test_NetworkConfigConsistency() public view {
        NetworkConfig.Addresses memory arbitrumAddrs = ArbitrumSepolia.getAddresses();
        NetworkConfig.Addresses memory monadAddrs = MonadMainnet.getAddresses();

        assertNotEq(arbitrumAddrs.pool, address(0), "Arbitrum pool should be set");
        assertNotEq(arbitrumAddrs.oracle, address(0), "Arbitrum oracle should be set");

        assertNotEq(monadAddrs.pool, address(0), "Monad pool should be set");
        assertNotEq(monadAddrs.oracle, address(0), "Monad oracle should be set");
    }

    function test_EachNetworkTokenAndRiskCountsMatch() public view {
        TokensConfig.Token[] memory arbitrumTokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);
        TokensConfig.Token[] memory monadTokens = tokensRegistry.getTokens(TokensConfig.Network.MonadMainnet);
        IRiskParametersConfig.RiskParams[] memory arbitrumParams =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.ArbitrumSepolia);
        IRiskParametersConfig.RiskParams[] memory monadParams =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.MonadMainnet);

        assertEq(arbitrumTokens.length, 5);
        assertEq(monadTokens.length, 11);
        assertEq(arbitrumParams.length, arbitrumTokens.length);
        assertEq(monadParams.length, monadTokens.length);
    }

    function test_RiskParamsForBothNetworks() public view {
        IRiskParametersConfig.RiskParams[] memory arbitrumParams =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.ArbitrumSepolia);
        IRiskParametersConfig.RiskParams[] memory monadParams =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.MonadMainnet);

        assertEq(arbitrumParams.length, 5);
        assertEq(monadParams.length, 11);
    }

    function test_PoolConfiguratorRetrieval() public view {
        NetworkConfig.Addresses memory addrs = ArbitrumSepolia.getAddresses();
        address configurator = NetworkConfig.getPoolConfigurator(addrs);

        assertNotEq(configurator, address(0), "Configurator should not be zero");
        assertEq(configurator, ArbitrumSepolia.POOL_CONFIGURATOR, "Should return constant value");
    }

    function test_AllTokensHavePriceFeeds() public {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < tokens.length; i++) {
            assertNotEq(tokens[i].priceFeed, address(0), "All tokens should have price feeds");
        }
    }

    function test_RiskParamsHaveValidRanges() public view {
        IRiskParametersConfig.RiskParams[] memory params =
            IRiskParametersConfig(address(risk)).getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < params.length; i++) {
            assertLe(params[i].ltv, risk.BASIS_POINTS(), "LTV should not exceed 100%");

            assertGe(params[i].liquidationThreshold, params[i].ltv, "LT should be >= LTV");

            assertGt(params[i].liquidationBonus, risk.BASIS_POINTS(), "LB should be > 100%");

            assertLe(params[i].reserveFactor, risk.BASIS_POINTS(), "RF should not exceed 100%");
        }
    }
}
