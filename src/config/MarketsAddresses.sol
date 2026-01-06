// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPoolAddressesProvider} from "../interfaces/IAaveExternal.sol";

/// @title MarketsAddresses
/// @notice Library containing Aave v3 contract addresses for Arbitrum testnet
library MarketsAddresses {
    // Aave v3 PoolAddressesProvider - provides addresses of other contracts
    address public constant POOL_ADDRESSES_PROVIDER = 0xBA25de9a7DC623B30799F33B770d31B44c2C3b77;

    // Aave v3 Pool - main entry point for lending/borrowing
    address public constant POOL = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;

    // Aave v3 Oracle - price oracle for assets
    address public constant ORACLE = 0x2da88497588bf89281816106C7259e31AF45a663;

    // Aave v3 PoolConfigurator - for listing assets and configuring parameters
    address public constant POOL_CONFIGURATOR = address(0); // Will be set or obtained via provider

    /// @notice Gets PoolConfigurator address from PoolAddressesProvider
    /// @return The PoolConfigurator address
    function getPoolConfigurator() internal view returns (address) {
        // If POOL_CONFIGURATOR is set, use it; otherwise get from provider
        address configurator = POOL_CONFIGURATOR;
        if (configurator != address(0)) {
            return configurator;
        }
        return IPoolAddressesProvider(POOL_ADDRESSES_PROVIDER).getPoolConfigurator();
    }
}

