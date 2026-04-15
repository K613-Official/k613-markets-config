// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";

/// @title SimulationPrank
/// @notice Optional broadcast prank for dry-runs when `SIMULATION_PRANK` env is a non-zero address.
abstract contract SimulationPrank is Script {
    /// @notice Returns whether a simulation prank address is configured.
    /// @return True when `SIMULATION_PRANK` is set to a non-zero address.
    function _simulationPrankActive() internal view returns (bool) {
        return vm.envOr("SIMULATION_PRANK", address(0)) != address(0);
    }

    /// @notice Starts `vm.startPrank` when `SIMULATION_PRANK` is non-zero.
    /// @return True if a prank session was started and must be closed with `_endSimulationPrank`.
    function _beginSimulationPrank() internal returns (bool) {
        address a = vm.envOr("SIMULATION_PRANK", address(0));
        if (a != address(0)) {
            vm.startPrank(a);
            return true;
        }
        return false;
    }

    /// @notice Stops an active prank started by `_beginSimulationPrank`.
    /// @param active Return value from `_beginSimulationPrank`.
    function _endSimulationPrank(bool active) internal {
        if (active) vm.stopPrank();
    }
}
