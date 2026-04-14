// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {K613Monad_EmergencyFreeze} from "../src/payloads/emergency/K613Monad_EmergencyFreeze.sol";
import {K613Monad_EmergencyPause} from "../src/payloads/emergency/K613Monad_EmergencyPause.sol";

/// @title ExecuteEmergencyPayload
/// @notice Deploys and executes a freeze or pause payload for a single reserve.
/// @dev Env vars:
///   EMERGENCY_ACTION — "freeze" | "unfreeze" | "pause" | "unpause"
///   EMERGENCY_ASSET  — underlying asset address
contract ExecuteEmergencyPayload is Script {
    /// @notice `EMERGENCY_ACTION` was not one of freeze, unfreeze, pause, unpause.
    error UnknownAction(string action);

    /// @notice Deploys the matching emergency payload and calls `execute` in one broadcast.
    function run() external {
        string memory action = vm.envString("EMERGENCY_ACTION");
        address asset = vm.envAddress("EMERGENCY_ASSET");

        vm.startBroadcast();

        bytes32 h = keccak256(bytes(action));
        if (h == keccak256("freeze")) {
            K613Monad_EmergencyFreeze p = new K613Monad_EmergencyFreeze(asset, true);
            p.execute();
            console.log("Frozen", asset);
        } else if (h == keccak256("unfreeze")) {
            K613Monad_EmergencyFreeze p = new K613Monad_EmergencyFreeze(asset, false);
            p.execute();
            console.log("Unfrozen", asset);
        } else if (h == keccak256("pause")) {
            K613Monad_EmergencyPause p = new K613Monad_EmergencyPause(asset, true);
            p.execute();
            console.log("Paused", asset);
        } else if (h == keccak256("unpause")) {
            K613Monad_EmergencyPause p = new K613Monad_EmergencyPause(asset, false);
            p.execute();
            console.log("Unpaused", asset);
        } else {
            revert UnknownAction(action);
        }

        vm.stopBroadcast();
    }
}
