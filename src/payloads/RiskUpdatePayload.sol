// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPoolConfigurator} from "../interfaces/IAaveExternal.sol";
import {RiskConfig} from "../config/RiskConfig.sol";
import {ArbitrumSepoliaAddresses} from "../config/ArbitrumSepoliaAddresses.sol";

/// @title RiskUpdatePayload
/// @notice Updates borrow/supply caps and reserve factors
/// @dev Aave-style stateless governance payload
contract RiskUpdatePayload {
    function execute() external {
        IPoolConfigurator configurator = IPoolConfigurator(ArbitrumSepoliaAddresses.getPoolConfigurator());

        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams();

        for (uint256 i; i < params.length; i++) {
            configurator.setBorrowCap(params[i].asset, params[i].borrowCap);
            configurator.setSupplyCap(params[i].asset, params[i].supplyCap);
            configurator.setReserveFactor(params[i].asset, params[i].reserveFactor);
        }
    }
}
