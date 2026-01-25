// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPoolAddressesProvider} from "lib/L2-Protocol/src/contracts/interfaces/IPoolAddressesProvider.sol";

/// @title NetworkConfig
/// @notice Interface for network-specific configurations
/// @dev Each network (Arbitrum Sepolia, Arbitrum Mainnet, etc.) implements this interface
library NetworkConfig {
    struct Addresses {
        address poolAddressesProvider;
        address pool;
        address poolConfigurator;
        address oracle;
        address aTokenImpl;
        address variableDebtImpl;
        address stableDebtImpl;
        address treasury;
        address incentivesController;
        address defaultInterestRateStrategy;
    }

    /// @notice Gets PoolConfigurator address from Addresses struct
    /// @param addrs The network addresses
    function getPoolConfigurator(Addresses memory addrs) internal view returns (address) {
        if (addrs.poolConfigurator != address(0)) {
            return addrs.poolConfigurator;
        }
        return IPoolAddressesProvider(addrs.poolAddressesProvider).getPoolConfigurator();
    }
}
