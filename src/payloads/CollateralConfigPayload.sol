// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPoolConfigurator} from "../interfaces/IAaveExternal.sol";
import {TokensConfig} from "../config/TokensConfig.sol";
import {RiskConfig} from "../config/RiskConfig.sol";
import {ArbitrumSepoliaAddresses} from "../config/ArbitrumSepoliaAddresses.sol";

/// @title CollateralConfigPayload
/// @notice Aave-style payload to configure collateral parameters (LTV, LT, LB) and enable borrowing
/// @dev Stateless, execute-only governance payload
/// @dev This payload configures collateral settings and enables borrowing. Must be executed after ListingPayload.
contract CollateralConfigPayload {
    function execute() external {
        IPoolConfigurator configurator = IPoolConfigurator(ArbitrumSepoliaAddresses.getPoolConfigurator());

        TokensConfig.Token[] memory tokens = TokensConfig.getTokens();
        RiskConfig.RiskParams[] memory riskParams = RiskConfig.getRiskParams();
        require(riskParams.length == tokens.length, "Risk params length mismatch");

        for (uint256 i; i < tokens.length; i++) {
            RiskConfig.RiskParams memory risk = riskParams[i];

            // Configure as collateral (LTV, liquidation threshold, liquidation bonus)
            configurator.configureReserveAsCollateral(
                risk.asset, risk.ltv, risk.liquidationThreshold, risk.liquidationBonus
            );

            // Enable variable rate borrowing
            configurator.setReserveBorrowing(risk.asset, true);
        }
    }
}
