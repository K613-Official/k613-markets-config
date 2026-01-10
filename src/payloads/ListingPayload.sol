// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPoolConfigurator} from "../interfaces/IAaveExternal.sol";
import {ConfiguratorInputTypes} from "../interfaces/IAaveExternal.sol";
import {TokensConfig} from "../config/TokensConfig.sol";
import {ArbitrumSepoliaAddresses} from "../config/ArbitrumSepoliaAddresses.sol";

/// @title ListingPayload
/// @notice Aave-style payload to list assets
/// @dev Stateless, execute-only governance payload
contract ListingPayload {
    function execute() external {
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens();

        ConfiguratorInputTypes.InitReserveInput[] memory inputs =
            new ConfiguratorInputTypes.InitReserveInput[](tokens.length);

        for (uint256 i; i < tokens.length; i++) {
            TokensConfig.Token memory t = tokens[i];

            inputs[i] = ConfiguratorInputTypes.InitReserveInput({
                aTokenImpl: ArbitrumSepoliaAddresses.ATOKEN_IMPL,
                stableDebtTokenImpl: address(0),
                variableDebtTokenImpl: ArbitrumSepoliaAddresses.VARIABLE_DEBT_IMPL,
                underlyingAssetDecimals: t.decimals,
                interestRateStrategyAddress: ArbitrumSepoliaAddresses.DEFAULT_INTEREST_RATE_STRATEGY,
                underlyingAsset: t.asset,
                treasury: ArbitrumSepoliaAddresses.TREASURY,
                incentivesController: ArbitrumSepoliaAddresses.INCENTIVES_CONTROLLER,
                aTokenName: string.concat("Aave ", t.symbol),
                aTokenSymbol: string.concat("a", t.symbol),
                variableDebtTokenName: string.concat("Aave Variable Debt ", t.symbol),
                variableDebtTokenSymbol: string.concat("variableDebt", t.symbol),
                stableDebtTokenName: "",
                stableDebtTokenSymbol: "",
                params: ""
            });
        }

        IPoolConfigurator configurator = IPoolConfigurator(ArbitrumSepoliaAddresses.getPoolConfigurator());
        configurator.initReserves(inputs);

        // Disable stable rate borrowing for all reserves
        for (uint256 i; i < tokens.length; i++) {
            configurator.setReserveStableRateBorrowing(tokens[i].asset, false);
        }
    }
}
