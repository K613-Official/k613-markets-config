// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPoolConfigurator} from "lib/L2-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {TokensConfig} from "../config/TokensConfig.sol";
import {RiskConfig} from "../config/RiskConfig.sol";
import {NetworkConfig} from "../config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../config/networks/MonadMainnet.sol";

/// @title CollateralConfigPayload
/// @notice Aave-style payload to configure collateral parameters (LTV, LT, LB) and enable borrowing
/// @dev Stateless, execute-only governance payload
/// @dev This payload configures collateral settings and enables borrowing. Must be executed after ListingPayload.
/// @dev Set NETWORK constant to switch between networks
contract CollateralConfigPayload {
    // Change this constant to switch networks
    TokensConfig.Network internal constant NETWORK = TokensConfig.Network.ArbitrumSepolia;

    function execute() external {
        NetworkConfig.Addresses memory addrs = _getAddresses();
        IPoolConfigurator configurator = IPoolConfigurator(NetworkConfig.getPoolConfigurator(addrs));

        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(NETWORK);
        RiskConfig.RiskParams[] memory riskParams = RiskConfig.getRiskParams(NETWORK);
        require(riskParams.length == tokens.length, "Risk params length mismatch");

        for (uint256 i = 0; i < tokens.length; i++) {
            RiskConfig.RiskParams memory risk = riskParams[i];

            // Configure as collateral (LTV, liquidation threshold, liquidation bonus)
            configurator.configureReserveAsCollateral(
                risk.asset, risk.ltv, risk.liquidationThreshold, risk.liquidationBonus
            );

            // Enable variable rate borrowing
            configurator.setReserveBorrowing(risk.asset, true);
        }
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
}
