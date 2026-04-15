// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {NetworkConfig} from "./NetworkConfig.sol";

/// @title MonadMainnet
/// @notice Canonical addresses for the Monad mainnet deployment.
/// @dev Constants below are fixed mainnet deployment addresses for the live pool stack.
library MonadMainnet {
    address internal constant POOL_ADDRESSES_PROVIDER = 0x1f6E754C6F7A49e2d69e5341d65EcB8f8506C69c;
    address internal constant POOL = 0x4Ba3856a4d851d39C27e2E866daB7A95eF6e0113;
    address internal constant POOL_CONFIGURATOR = 0x3F16A467c3fC589fB96864196047F2f417CAc28F;
    address internal constant ORACLE = 0x0dFfb00A751a74ac8CF8B022Bf86b1ECd9D7ae6F;
    address internal constant ATOKEN_IMPL = 0xDe57e04622877525482BefC9301728e0ED57f677;
    address internal constant VARIABLE_DEBT_IMPL = 0xF8C5a1F25a6e1910E443edC2fC71b7B6cC4248Fb;
    address internal constant TREASURY = 0x628CddC70789c4Ea843dc9dc2f84C16e2580D2e6;
    address internal constant INCENTIVES_CONTROLLER = 0x4daF0EfC0E149B13b6c115916d643524E279DDEa;
    address internal constant DEFAULT_INTEREST_RATE_STRATEGY = 0xDA36b4904Ed53f19a7E1995c718f7149580D0f65;
    address internal constant CONFIG_ENGINE = 0x53De8e2AFe1C424158ebb3AE44dbCf0734EE3816;
    address internal constant ACL_MANAGER = 0x115840CF79eb27713E0Bd3B66076651f8C081B0B;
    address internal constant EMISSION_MANAGER = 0x7eEdb2D4D4b89b8B854c734e8fAABfB24E0537A6;
    address internal constant AAVE_PROTOCOL_DATA_PROVIDER = 0xfc87bE7f3657AAD69baDb6247A88E924D1F8bc53;

    /// @notice Returns the full address bundle for this network.
    /// @return Structured addresses for scripts and payloads.
    function getAddresses() internal pure returns (NetworkConfig.Addresses memory) {
        return NetworkConfig.Addresses({
            poolAddressesProvider: POOL_ADDRESSES_PROVIDER,
            pool: POOL,
            poolConfigurator: POOL_CONFIGURATOR,
            oracle: ORACLE,
            aTokenImpl: ATOKEN_IMPL,
            variableDebtImpl: VARIABLE_DEBT_IMPL,
            treasury: TREASURY,
            incentivesController: INCENTIVES_CONTROLLER,
            defaultInterestRateStrategy: DEFAULT_INTEREST_RATE_STRATEGY,
            configEngine: CONFIG_ENGINE
        });
    }

    /// @notice Convenience accessor for the pool configurator on this chain.
    /// @return Configurator address (explicit or from provider).
    function getPoolConfigurator() internal view returns (address) {
        return NetworkConfig.getPoolConfigurator(getAddresses());
    }
}
