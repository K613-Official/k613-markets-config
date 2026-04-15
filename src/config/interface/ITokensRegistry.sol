// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokensConfig} from "../TokensConfig.sol";

/// @title ITokensRegistry
/// @notice Read-only view of listed tokens for oracles, risk, and listing flows.
interface ITokensRegistry {
    /// @notice Returns a memory copy of every listed token.
    /// @return out Token array in registry order.
    function getTokens() external view returns (TokensConfig.Token[] memory out);

    /// @notice Returns how many tokens are listed.
    /// @return count Length of the internal token list.
    function tokenCount() external view returns (uint256 count);
}
