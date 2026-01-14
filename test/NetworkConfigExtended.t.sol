// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {NetworkConfig} from "../src/config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";
import {IPoolAddressesProvider} from "../src/interfaces/IAaveExternal.sol";

/// @title MockPoolAddressesProvider
/// @notice Mock for testing NetworkConfig.getPoolConfigurator fallback
contract MockPoolAddressesProvider is IPoolAddressesProvider {
    address public poolConfigurator;

    constructor(address _poolConfigurator) {
        poolConfigurator = _poolConfigurator;
    }

    function getPoolConfigurator() external view override returns (address) {
        return poolConfigurator;
    }

    function getPool() external pure override returns (address) {
        return address(0);
    }

    function getPriceOracle() external pure override returns (address) {
        return address(0);
    }
}

/// @title NetworkConfigExtendedTest
/// @notice Extended tests for NetworkConfig to improve coverage
contract NetworkConfigExtendedTest is Test {
    function test_NetworkConfigGetPoolConfiguratorWithProvider() public {
        address mockConfigurator = address(0x1234);
        MockPoolAddressesProvider provider = new MockPoolAddressesProvider(mockConfigurator);

        NetworkConfig.Addresses memory addrs = NetworkConfig.Addresses({
            poolAddressesProvider: address(provider),
            pool: address(0),
            poolConfigurator: address(0), // Zero - should use fallback
            oracle: address(0),
            aTokenImpl: address(0),
            variableDebtImpl: address(0),
            stableDebtImpl: address(0),
            treasury: address(0),
            incentivesController: address(0),
            defaultInterestRateStrategy: address(0)
        });

        address result = NetworkConfig.getPoolConfigurator(addrs);
        assertEq(result, mockConfigurator, "Should return configurator from provider");
    }

    function test_MonadMainnetGetAddresses() public view {
        NetworkConfig.Addresses memory addrs = MonadMainnet.getAddresses();
        
        // All should be placeholders
        assertEq(addrs.poolAddressesProvider, address(0), "Should be placeholder");
        assertEq(addrs.pool, address(0), "Should be placeholder");
        assertEq(addrs.poolConfigurator, address(0), "Should be placeholder");
        assertEq(addrs.oracle, address(0), "Should be placeholder");
        assertEq(addrs.aTokenImpl, address(0), "Should be placeholder");
        assertEq(addrs.variableDebtImpl, address(0), "Should be placeholder");
        assertEq(addrs.stableDebtImpl, address(0), "Should be placeholder");
        assertEq(addrs.treasury, address(0), "Should be placeholder");
        assertEq(addrs.incentivesController, address(0), "Should be placeholder");
        assertEq(addrs.defaultInterestRateStrategy, address(0), "Should be placeholder");
    }

    function test_NetworkConfigAddressesStructure() public view {
        NetworkConfig.Addresses memory addrs = ArbitrumSepolia.getAddresses();
        
        // Verify all fields are accessible
        assertNotEq(addrs.poolAddressesProvider, address(0), "PoolAddressesProvider should be set");
        assertNotEq(addrs.pool, address(0), "Pool should be set");
        assertNotEq(addrs.oracle, address(0), "Oracle should be set");
    }
}
