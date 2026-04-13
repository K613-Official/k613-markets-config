// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokensConfig} from "../TokensConfig.sol";

/// @title ITokensRegistry
/// @notice Read-only view of listed tokens per network for oracles, risk, and listing flows.
interface ITokensRegistry {
    /// @notice Returns a memory copy of every token configured for `network`.
    /// @param network Target chain deployment.
    /// @return out Token array in registry order.
    function getTokens(TokensConfig.Network network) external view returns (TokensConfig.Token[] memory out);

    /// @notice Returns how many tokens are listed for `network`.
    /// @param network Target chain deployment.
    /// @return count Length of the internal token list.
    function tokenCount(TokensConfig.Network network) external view returns (uint256 count);
}
