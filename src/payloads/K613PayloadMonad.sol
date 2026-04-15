// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AaveV3Payload} from "lib/K613-Protocol/src/contracts/extensions/v3-config-engine/AaveV3Payload.sol";
import {IAaveV3ConfigEngine} from "lib/K613-Protocol/src/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol";
import {MonadMainnet} from "../networks/MonadMainnet.sol";

/// @title K613PayloadMonad
/// @notice Base `AaveV3Payload` wired to the Monad mainnet `AaveV3ConfigEngine` instance.
/// @dev Concrete payloads inherit this and override only the hooks they need.
abstract contract K613PayloadMonad is AaveV3Payload {
    /// @notice Wires the payload base to `MonadMainnet.CONFIG_ENGINE`.
    constructor() AaveV3Payload(IAaveV3ConfigEngine(MonadMainnet.CONFIG_ENGINE)) {}

    /// @notice Returns display strings used by the config engine for this deployment.
    /// @return Pool context with network name `Monad` and abbreviation `Mon`.
    function getPoolContext() public pure override returns (IAaveV3ConfigEngine.PoolContext memory) {
        return IAaveV3ConfigEngine.PoolContext({networkName: "Monad", networkAbbreviation: "Mon"});
    }
}
