// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {NetworkConfig} from "./NetworkConfig.sol";

/// @title ArbitrumSepolia
/// @notice Network configuration for Arbitrum Sepolia testnet
library ArbitrumSepolia {
    // Individual address constants
    address internal constant POOL_ADDRESSES_PROVIDER = 0xBDC2803d37359eC35e01C7995A0e219F19d2abFC;
    address internal constant POOL = 0xf371059c30a2e42b08039f0c22b49846954B76aB;
    address internal constant POOL_CONFIGURATOR = 0x3da7599A0E4f0ACF4024F9ABF5209d881CBA3EDa;
    address internal constant ORACLE = 0xB89eC9776F9F16750Dd85A141346924598c4BA4a;
    address internal constant ATOKEN_IMPL = 0x8D72EF4AD3fb97F5649Fdd13CFE979934D9C7AFd;
    address internal constant VARIABLE_DEBT_IMPL = 0xcc54C71aeA32428db93678d3D77671dF3e2dB704;
    address internal constant STABLE_DEBT_IMPL = address(0); // Not deployed - stable borrowing disabled
    address internal constant TREASURY = 0x33f1721f876A3154A31337c2970364d7285e2caA; // Collector
    address internal constant INCENTIVES_CONTROLLER = 0x4782272Eb0ab1a835990Cf58d355d5894EB6ff71; // RewardsController
    address internal constant DEFAULT_INTEREST_RATE_STRATEGY = 0x67E1a57b8fc9A847B4fC442d4fA492Ec3b3c586B;

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
