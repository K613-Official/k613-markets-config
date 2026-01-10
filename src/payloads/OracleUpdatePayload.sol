// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {OraclesConfig} from "../config/OraclesConfig.sol";
import {ArbitrumSepoliaAddresses} from "../config/ArbitrumSepoliaAddresses.sol";

/// @title OracleUpdatePayload
/// @notice Aave-style payload to update oracle price feeds
/// @dev Stateless, execute-only governance payload
contract OracleUpdatePayload {
    function execute() external {
        OraclesConfig.configureOracles(ArbitrumSepoliaAddresses.ORACLE);
    }
}
