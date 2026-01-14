// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {NetworkConfig} from "./NetworkConfig.sol";

/// @title MonadMainnet
/// @notice Network configuration for Monad Mainnet
/// @dev TODO: Fill in mainnet addresses when deploying to mainnet
library MonadMainnet {
    // Individual address constants
    address internal constant POOL_ADDRESSES_PROVIDER = address(0); // TODO: Set Monad mainnet address
    address internal constant POOL = address(0); // TODO: Set Monad mainnet address
    address internal constant POOL_CONFIGURATOR = address(0); // TODO: Set Monad mainnet address
    address internal constant ORACLE = address(0); // TODO: Set Monad mainnet address
    address internal constant ATOKEN_IMPL = address(0); // TODO: Set Monad mainnet address
    address internal constant VARIABLE_DEBT_IMPL = address(0); // TODO: Set Monad mainnet address
    address internal constant STABLE_DEBT_IMPL = address(0); // TODO: Set Monad mainnet address if needed
    address internal constant TREASURY = address(0); // TODO: Set Monad mainnet address
    address internal constant INCENTIVES_CONTROLLER = address(0); // TODO: Set Monad mainnet address
    address internal constant DEFAULT_INTEREST_RATE_STRATEGY = address(0); // TODO: Set Monad mainnet address

    function getAddresses() internal pure returns (NetworkConfig.Addresses memory) {
        return NetworkConfig.Addresses({
            poolAddressesProvider: POOL_ADDRESSES_PROVIDER,
            pool: POOL,
            poolConfigurator: POOL_CONFIGURATOR,
            oracle: ORACLE,
            aTokenImpl: ATOKEN_IMPL,
            variableDebtImpl: VARIABLE_DEBT_IMPL,
            stableDebtImpl: STABLE_DEBT_IMPL,
            treasury: TREASURY,
            incentivesController: INCENTIVES_CONTROLLER,
            defaultInterestRateStrategy: DEFAULT_INTEREST_RATE_STRATEGY
        });
    }

    function getPoolConfigurator() internal view returns (address) {
        return NetworkConfig.getPoolConfigurator(getAddresses());
    }
}
