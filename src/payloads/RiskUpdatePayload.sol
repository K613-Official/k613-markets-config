// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPoolConfigurator} from "lib/L2-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {RiskConfig} from "../config/RiskConfig.sol";
import {TokensConfig} from "../config/TokensConfig.sol";
import {NetworkConfig} from "../config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../config/networks/MonadMainnet.sol";

/// @title RiskUpdatePayload
/// @notice Updates borrow/supply caps and reserve factors
/// @dev Aave-style stateless governance payload
/// @dev Set NETWORK constant to switch between networks
contract RiskUpdatePayload {
    // Change this constant to switch networks
    TokensConfig.Network internal constant NETWORK = TokensConfig.Network.ArbitrumSepolia;

    function execute() external {
        NetworkConfig.Addresses memory addrs = _getAddresses();
        IPoolConfigurator configurator = IPoolConfigurator(NetworkConfig.getPoolConfigurator(addrs));

        RiskConfig.RiskParams[] memory params = RiskConfig.getRiskParams(NETWORK);

        for (uint256 i = 0; i < params.length; i++) {
            configurator.setBorrowCap(params[i].asset, params[i].borrowCap);
            configurator.setSupplyCap(params[i].asset, params[i].supplyCap);
            configurator.setReserveFactor(params[i].asset, params[i].reserveFactor);
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
