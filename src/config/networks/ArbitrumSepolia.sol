// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {NetworkConfig} from "./NetworkConfig.sol";

/// @title ArbitrumSepolia
/// @notice Network configuration for Arbitrum Sepolia testnet
library ArbitrumSepolia {
    // Individual address constants
    address internal constant POOL_ADDRESSES_PROVIDER = 0x20f1827195Bbff32942C43681841d6b2B82651b7;
    address internal constant POOL = 0x82879580a7757D08730a3Ad3860a0F7F08895D92;
    address internal constant POOL_CONFIGURATOR = 0x6e844B6F5345f1eB17129b48323cE426aeB5fdFF; // PoolConfigurator proxy (confirmed)
    address internal constant ORACLE = 0x4D82d72AF7ee91b5c16cA3A4C85585e9791f9Cc0;
    address internal constant ATOKEN_IMPL = 0x38A04b3EA118B2458B14a14573897181bb6F99Eb;
    address internal constant VARIABLE_DEBT_IMPL = 0x388b4F87fD03c3AD76D94e8EddFa96e1631bF2c2;
    address internal constant TREASURY = 0x4594D2a86Ad17F38AdC26B7E3576dB64485b4469;
    address internal constant INCENTIVES_CONTROLLER = 0x68884bc5ca880c72C6D7b17b90763e5cA5726f2E;
    address internal constant DEFAULT_INTEREST_RATE_STRATEGY = 0x6589929D18ee9a072e83e60963DCF32F1621F157;

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
            defaultInterestRateStrategy: DEFAULT_INTEREST_RATE_STRATEGY
        });
    }

    function getPoolConfigurator() internal view returns (address) {
        return NetworkConfig.getPoolConfigurator(getAddresses());
    }
}
