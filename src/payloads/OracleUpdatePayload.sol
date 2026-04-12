// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {OraclesConfig} from "../config/OraclesConfig.sol";
import {TokensConfig} from "../config/TokensConfig.sol";
import {NetworkConfig} from "../config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../config/networks/MonadMainnet.sol";

/// @title OracleUpdatePayload
/// @notice Registers asset price sources on the Aave oracle for the configured network.
/// @dev Stateless, execute-only; switch `NETWORK` for other deployments.
contract OracleUpdatePayload {
    /// @notice Active deployment for this payload bytecode.
    TokensConfig.Network internal constant NETWORK = TokensConfig.Network.MonadMainnet;

    /// @notice Calls `OraclesConfig.configureOracles` with deployment addresses.
    function execute() external {
        NetworkConfig.Addresses memory addrs = _getAddresses();
        OraclesConfig.configureOracles(addrs.oracle, NETWORK);
    }

    /// @notice Resolves `NetworkConfig.Addresses` for `NETWORK`.
    /// @return addrs Addresses used for oracle configuration.
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
