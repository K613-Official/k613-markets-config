// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {RiskConfig} from "../src/config/RiskConfig.sol";
import {OraclesConfig} from "../src/config/OraclesConfig.sol";
import {NetworkConfig} from "../src/config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";

/// @title IntegrationTest
/// @notice Integration tests for config modules working together
contract IntegrationTest is Test {
    function test_TokensAndRiskParamsMatch() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);
        RiskConfig.RiskParams[] memory riskParams = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        assertEq(tokens.length, riskParams.length, "Tokens and risk params should have same length");

        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(tokens[i].asset, riskParams[i].asset, "Asset addresses should match");
        }
    }

    function test_NetworkConfigConsistency() public view {
        NetworkConfig.Addresses memory arbitrumAddrs = ArbitrumSepolia.getAddresses();
        NetworkConfig.Addresses memory monadAddrs = MonadMainnet.getAddresses();

        // Arbitrum should have all addresses set
        assertNotEq(arbitrumAddrs.pool, address(0), "Arbitrum pool should be set");
        assertNotEq(arbitrumAddrs.oracle, address(0), "Arbitrum oracle should be set");

        // Monad should have placeholder addresses
        assertEq(monadAddrs.pool, address(0), "Monad pool should be placeholder");
        assertEq(monadAddrs.oracle, address(0), "Monad oracle should be placeholder");
    }

    function test_AllNetworksReturnSameTokenCount() public {
        uint256 arbitrumCount = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia).length;
        uint256 monadCount = TokensConfig.getTokens(TokensConfig.Network.MonadMainnet).length;

        assertEq(arbitrumCount, monadCount, "Both networks should have same number of tokens");
        assertEq(arbitrumCount, 5, "Should have 5 tokens");
    }

    function test_RiskParamsForBothNetworks() public {
        RiskConfig.RiskParams[] memory arbitrumParams = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);
        RiskConfig.RiskParams[] memory monadParams = RiskConfig.getRiskParams(TokensConfig.Network.MonadMainnet);

        assertEq(arbitrumParams.length, monadParams.length, "Both networks should have same number of risk params");
        assertEq(arbitrumParams.length, 5, "Should have 5 risk params");
    }

    function test_PoolConfiguratorRetrieval() public view {
        NetworkConfig.Addresses memory addrs = ArbitrumSepolia.getAddresses();
        address configurator = NetworkConfig.getPoolConfigurator(addrs);

        assertNotEq(configurator, address(0), "Configurator should not be zero");
        assertEq(configurator, ArbitrumSepolia.POOL_CONFIGURATOR, "Should return constant value");
    }

    function test_AllTokensHavePriceFeeds() public {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < tokens.length; i++) {
            assertNotEq(tokens[i].priceFeed, address(0), "All tokens should have price feeds");
        }
    }

    function test_RiskParamsHaveValidRanges() public {
        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < params.length; i++) {
            // LTV should be between 0 and 100%
            assertLe(params[i].ltv, RiskConfig.BASIS_POINTS, "LTV should not exceed 100%");

            // Liquidation threshold should be >= LTV
            assertGe(params[i].liquidationThreshold, params[i].ltv, "LT should be >= LTV");

            // Liquidation bonus should be > 100% (for Aave v3)
            assertGt(params[i].liquidationBonus, RiskConfig.BASIS_POINTS, "LB should be > 100%");

            // Reserve factor should be between 0 and 100%
            assertLe(params[i].reserveFactor, RiskConfig.BASIS_POINTS, "RF should not exceed 100%");
        }
    }
}
