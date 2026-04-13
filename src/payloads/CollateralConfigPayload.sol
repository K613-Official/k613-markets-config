// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPoolConfigurator} from "lib/K613-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {TokensConfig} from "../config/TokensConfig.sol";
import {IRiskParametersConfig} from "../config/interface/IRiskParametersConfig.sol";
import {ITokensRegistry} from "../config/interface/ITokensRegistry.sol";
import {NetworkConfig} from "../config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../config/networks/MonadMainnet.sol";

/// @title CollateralConfigPayload
/// @notice Configures collateral parameters (LTV, liquidation threshold, bonus) and enables borrowing.
/// @dev Stateless, execute-only. Run after `ListingPayload` has initialized reserves.
/// @dev Switch `NETWORK` to target another deployment.
contract CollateralConfigPayload {
    error RiskParamsLengthMismatch();
    error ZeroRiskParameters();
    error ZeroTokensRegistry();

    IRiskParametersConfig public immutable riskParameters;
    ITokensRegistry public immutable tokensRegistry;

    TokensConfig.Network internal constant NETWORK = TokensConfig.Network.MonadMainnet;

    constructor(address riskParameters_, address tokensRegistry_) {
        if (riskParameters_ == address(0)) revert ZeroRiskParameters();
        if (tokensRegistry_ == address(0)) revert ZeroTokensRegistry();
        riskParameters = IRiskParametersConfig(riskParameters_);
        tokensRegistry = ITokensRegistry(tokensRegistry_);
    }

    function execute() external {
        NetworkConfig.Addresses memory addrs = _getAddresses();
        IPoolConfigurator configurator = IPoolConfigurator(NetworkConfig.getPoolConfigurator(addrs));

        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(NETWORK);
        IRiskParametersConfig.RiskParams[] memory riskParams = riskParameters.getRiskParams(NETWORK);
        if (riskParams.length != tokens.length) revert RiskParamsLengthMismatch();

        for (uint256 i = 0; i < tokens.length; i++) {
            IRiskParametersConfig.RiskParams memory risk = riskParams[i];

            // Configure as collateral (LTV, liquidation threshold, liquidation bonus)
            configurator.configureReserveAsCollateral(
                risk.asset, risk.ltv, risk.liquidationThreshold, risk.liquidationBonus
            );

            // Enable variable rate borrowing
            configurator.setReserveBorrowing(risk.asset, true);
        }
    }

    /// @notice Resolves `NetworkConfig.Addresses` for `NETWORK`.
    /// @return addrs Addresses used for configuration calls.
    function _getAddresses() private pure returns (NetworkConfig.Addresses memory addrs) {
        if (NETWORK == TokensConfig.Network.ArbitrumSepolia) {
            return ArbitrumSepolia.getAddresses();
        } else if (NETWORK == TokensConfig.Network.MonadMainnet) {
            return MonadMainnet.getAddresses();
        } else {
            revert("Unsupported network");
        }
    }
}
