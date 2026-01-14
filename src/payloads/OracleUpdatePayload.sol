// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {OraclesConfig} from "../config/OraclesConfig.sol";
import {TokensConfig} from "../config/TokensConfig.sol";
import {NetworkConfig} from "../config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../config/networks/MonadMainnet.sol";

/// @title OracleUpdatePayload
/// @notice Aave-style payload to update oracle price feeds
/// @dev Stateless, execute-only governance payload
/// @dev Set NETWORK constant to switch between networks
contract OracleUpdatePayload {
    // Change this constant to switch networks
    TokensConfig.Network internal constant NETWORK = TokensConfig.Network.ArbitrumSepolia;

    function execute() external {
        NetworkConfig.Addresses memory addrs = _getAddresses();
        OraclesConfig.configureOracles(addrs.oracle, NETWORK);
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
