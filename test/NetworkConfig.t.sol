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
            0x20f1827195Bbff32942C43681841d6b2B82651b7,
            "POOL_ADDRESSES_PROVIDER should match"
        );
        assertEq(ArbitrumSepolia.POOL, 0x82879580a7757D08730a3Ad3860a0F7F08895D92, "POOL should match");
        assertEq(ArbitrumSepolia.ORACLE, 0x4D82d72AF7ee91b5c16cA3A4C85585e9791f9Cc0, "ORACLE should match");
    }
}
