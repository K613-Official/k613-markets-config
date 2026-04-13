// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPoolConfigurator} from "lib/K613-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {IRiskParametersConfig} from "../config/interface/IRiskParametersConfig.sol";
import {TokensConfig} from "../config/TokensConfig.sol";
import {NetworkConfig} from "../config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../config/networks/MonadMainnet.sol";

/// @title RiskUpdatePayload
/// @notice Updates borrow caps, supply caps, and reserve factors from `IRiskParametersConfig`.
/// @dev Governance payload; switch `NETWORK` for other deployments.
contract RiskUpdatePayload {
    error ZeroRiskParameters();

    IRiskParametersConfig public immutable riskParameters;

    TokensConfig.Network internal constant NETWORK = TokensConfig.Network.MonadMainnet;

    constructor(address riskParameters_) {
        if (riskParameters_ == address(0)) revert ZeroRiskParameters();
        riskParameters = IRiskParametersConfig(riskParameters_);
    }

    function execute() external {
        NetworkConfig.Addresses memory addrs = _getAddresses();
        IPoolConfigurator configurator = IPoolConfigurator(NetworkConfig.getPoolConfigurator(addrs));

        IRiskParametersConfig.RiskParams[] memory params = riskParameters.getRiskParams(NETWORK);

        for (uint256 i = 0; i < params.length; i++) {
            configurator.setBorrowCap(params[i].asset, params[i].borrowCap);
            configurator.setSupplyCap(params[i].asset, params[i].supplyCap);
            configurator.setReserveFactor(params[i].asset, params[i].reserveFactor);
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
