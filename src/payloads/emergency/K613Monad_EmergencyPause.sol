// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPoolConfigurator} from "lib/K613-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {MonadMainnet} from "../../networks/MonadMainnet.sol";

/// @title K613Monad_EmergencyPause
/// @notice Parameterized one-shot payload that pauses or unpauses a single reserve.
/// @dev Paused reserves block **all** interactions including liquidations. Reserved for critical
///      incidents only. Caller must hold `EMERGENCY_ADMIN` or `POOL_ADMIN`.
contract K613Monad_EmergencyPause {
    address public immutable asset;
    bool public immutable paused;

    /// @notice Captures the reserve and desired pause flag for `execute`.
    /// @param asset_ Underlying reserve to pause or unpause.
    /// @param paused_ When true, pauses the reserve; when false, unpauses.
    constructor(address asset_, bool paused_) {
        asset = asset_;
        paused = paused_;
    }

    /// @notice Calls `PoolConfigurator.setReservePause` on Monad mainnet for `asset`.
    function execute() external {
        IPoolConfigurator(MonadMainnet.POOL_CONFIGURATOR).setReservePause(asset, paused);
    }
}
