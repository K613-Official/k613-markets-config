// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {NetworkConfig} from "../src/networks/NetworkConfig.sol";
import {MonadMainnet} from "../src/networks/MonadMainnet.sol";

/// @title NetworkConfigTest
/// @notice Tests for network configuration libraries
contract NetworkConfigTest is Test {
    function test_MonadMainnetAddresses() public pure {
        NetworkConfig.Addresses memory addrs = MonadMainnet.getAddresses();

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

    function test_MonadMainnetGetPoolConfigurator() public view {
        address configurator = MonadMainnet.getPoolConfigurator();
        assertNotEq(configurator, address(0), "PoolConfigurator should not be zero");
        assertEq(configurator, MonadMainnet.POOL_CONFIGURATOR, "Should return POOL_CONFIGURATOR constant");
    }

    function test_NetworkConfigGetPoolConfigurator() public view {
        NetworkConfig.Addresses memory addrs = MonadMainnet.getAddresses();
        address configurator = NetworkConfig.getPoolConfigurator(addrs);
        assertEq(configurator, MonadMainnet.POOL_CONFIGURATOR, "Should return POOL_CONFIGURATOR when set");
    }

    function test_MonadMainnetConstants() public pure {
        assertEq(
            MonadMainnet.POOL_ADDRESSES_PROVIDER,
            0x1f6E754C6F7A49e2d69e5341d65EcB8f8506C69c,
            "POOL_ADDRESSES_PROVIDER should match"
        );
        assertEq(MonadMainnet.POOL, 0x4Ba3856a4d851d39C27e2E866daB7A95eF6e0113, "POOL should match");
        assertEq(MonadMainnet.ORACLE, 0x0dFfb00A751a74ac8CF8B022Bf86b1ECd9D7ae6F, "ORACLE should match");
    }
}
