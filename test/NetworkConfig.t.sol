// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {NetworkConfig} from "../src/config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";

/// @title NetworkConfigTest
/// @notice Tests for network configuration libraries
contract NetworkConfigTest is Test {
    function test_ArbitrumSepoliaAddresses() public {
        NetworkConfig.Addresses memory addrs = ArbitrumSepolia.getAddresses();

        assertNotEq(addrs.poolAddressesProvider, address(0), "PoolAddressesProvider should be set");
        assertNotEq(addrs.pool, address(0), "Pool should be set");
        assertNotEq(addrs.poolConfigurator, address(0), "PoolConfigurator should be set");
        assertNotEq(addrs.oracle, address(0), "Oracle should be set");
        assertNotEq(addrs.aTokenImpl, address(0), "ATokenImpl should be set");
        assertNotEq(addrs.variableDebtImpl, address(0), "VariableDebtImpl should be set");
        assertNotEq(addrs.treasury, address(0), "Treasury should be set");
        assertNotEq(addrs.incentivesController, address(0), "IncentivesController should be set");
        assertNotEq(addrs.defaultInterestRateStrategy, address(0), "DefaultInterestRateStrategy should be set");
    }

    function test_ArbitrumSepoliaGetPoolConfigurator() public view {
        address configurator = ArbitrumSepolia.getPoolConfigurator();
        assertNotEq(configurator, address(0), "PoolConfigurator should not be zero");
        assertEq(configurator, ArbitrumSepolia.POOL_CONFIGURATOR, "Should return POOL_CONFIGURATOR constant");
    }

    function test_MonadMainnetAddresses() public {
        NetworkConfig.Addresses memory addrs = MonadMainnet.getAddresses();

        // All addresses should be placeholders (address(0)) for now
        assertEq(addrs.poolAddressesProvider, address(0), "PoolAddressesProvider should be placeholder");
        assertEq(addrs.pool, address(0), "Pool should be placeholder");
        assertEq(addrs.poolConfigurator, address(0), "PoolConfigurator should be placeholder");
        assertEq(addrs.oracle, address(0), "Oracle should be placeholder");
        assertEq(addrs.aTokenImpl, address(0), "ATokenImpl should be placeholder");
        assertEq(addrs.variableDebtImpl, address(0), "VariableDebtImpl should be placeholder");
        assertEq(addrs.treasury, address(0), "Treasury should be placeholder");
        assertEq(addrs.incentivesController, address(0), "IncentivesController should be placeholder");
        assertEq(addrs.defaultInterestRateStrategy, address(0), "DefaultInterestRateStrategy should be placeholder");
    }

    function test_NetworkConfigGetPoolConfigurator() public view {
        NetworkConfig.Addresses memory addrs = ArbitrumSepolia.getAddresses();
        address configurator = NetworkConfig.getPoolConfigurator(addrs);
        assertEq(configurator, ArbitrumSepolia.POOL_CONFIGURATOR, "Should return POOL_CONFIGURATOR when set");
    }

    function test_ArbitrumSepoliaConstants() public view {
        assertEq(
            ArbitrumSepolia.POOL_ADDRESSES_PROVIDER,
            0xBDC2803d37359eC35e01C7995A0e219F19d2abFC,
            "POOL_ADDRESSES_PROVIDER should match"
        );
        assertEq(ArbitrumSepolia.POOL, 0xf371059c30a2e42b08039f0c22b49846954B76aB, "POOL should match");
        assertEq(ArbitrumSepolia.ORACLE, 0xB89eC9776F9F16750Dd85A141346924598c4BA4a, "ORACLE should match");
    }
}
