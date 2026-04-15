// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPoolConfigurator} from "lib/K613-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {MonadMainnet} from "../../config/networks/MonadMainnet.sol";

/// @title K613Monad_EmergencyFreeze
/// @notice Parameterized one-shot payload that freezes or unfreezes a single reserve.
/// @dev Frozen reserves block new supply/borrow/repay but keep existing positions liquidatable.
///      Calls `PoolConfigurator` directly — not routed through `AaveV3ConfigEngine` because
///      the engine does not expose freeze/pause. Caller must hold `RISK_ADMIN` or `POOL_ADMIN`.
contract K613Monad_EmergencyFreeze {
    address public immutable asset;
    bool public immutable freeze;

    /// @notice Captures the reserve and desired freeze flag for `execute`.
    /// @param asset_ Underlying reserve to freeze or unfreeze.
    /// @param freeze_ When true, freezes the reserve; when false, unfreezes.
    constructor(address asset_, bool freeze_) {
        asset = asset_;
        freeze = freeze_;
    }

    /// @notice Calls `PoolConfigurator.setReserveFreeze` on Monad mainnet for `asset`.
    function execute() external {
        IPoolConfigurator(MonadMainnet.POOL_CONFIGURATOR).setReserveFreeze(asset, freeze);
    }
}
