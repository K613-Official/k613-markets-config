// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPoolConfigurator} from "lib/L2-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {
    IDefaultInterestRateStrategyV2
} from "lib/L2-Protocol/src/contracts/interfaces/IDefaultInterestRateStrategyV2.sol";
import {
    ConfiguratorInputTypes
} from "lib/L2-Protocol/src/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol";
import {TokensConfig} from "../config/TokensConfig.sol";
import {NetworkConfig} from "../config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../config/networks/MonadMainnet.sol";

/// @title ListingPayload
/// @notice Aave-style payload to list assets (initReserves ONLY)
/// @dev Stateless, execute-only governance payload
/// @dev This payload ONLY initializes reserves. Use CollateralConfigPayload and RiskUpdatePayload for other configurations.
/// @dev Set NETWORK constant to switch between networks
contract ListingPayload {
    // Change this constant to switch networks
    TokensConfig.Network internal constant NETWORK = TokensConfig.Network.ArbitrumSepolia;

    function execute() external {
        NetworkConfig.Addresses memory addrs = _getAddresses();
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(NETWORK);

        ConfiguratorInputTypes.InitReserveInput[] memory inputs =
            new ConfiguratorInputTypes.InitReserveInput[](tokens.length);
        bytes memory interestRateData = _defaultInterestRateData();

        for (uint256 i = 0; i < tokens.length; i++) {
            TokensConfig.Token memory t = tokens[i];

            inputs[i] = ConfiguratorInputTypes.InitReserveInput({
                aTokenImpl: addrs.aTokenImpl,
                variableDebtTokenImpl: addrs.variableDebtImpl,
                useVirtualBalance: true,
                interestRateStrategyAddress: addrs.defaultInterestRateStrategy,
                underlyingAsset: t.asset,
                treasury: addrs.treasury,
                incentivesController: addrs.incentivesController,
                aTokenName: string.concat("Aave ", t.symbol),
                aTokenSymbol: string.concat("a", t.symbol),
                variableDebtTokenName: string.concat("Aave Variable Debt ", t.symbol),
                variableDebtTokenSymbol: string.concat("variableDebt", t.symbol),
                params: "",
                interestRateData: interestRateData
            });
        }

        IPoolConfigurator configurator = IPoolConfigurator(NetworkConfig.getPoolConfigurator(addrs));
        configurator.initReserves(inputs);
    }

    function _getAddresses() private pure returns (NetworkConfig.Addresses memory) {
        if (NETWORK == TokensConfig.Network.ArbitrumSepolia) {
            return ArbitrumSepolia.getAddresses();
        } else if (NETWORK == TokensConfig.Network.MonadMainnet) {
            return MonadMainnet.getAddresses();
        } else {
            revert("Unsupported network");
        }
    }

    function _defaultInterestRateData() private pure returns (bytes memory) {
        return abi.encode(
            IDefaultInterestRateStrategyV2.InterestRateData({
                optimalUsageRatio: 80_00,
                baseVariableBorrowRate: 10_00,
                variableRateSlope1: 4_00,
                variableRateSlope2: 60_00
            })
        );
    }
}
