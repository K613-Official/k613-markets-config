// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";

abstract contract SimulationPrank is Script {
    function _simulationPrankActive() internal view returns (bool) {
        return vm.envOr("SIMULATION_PRANK", address(0)) != address(0);
    }

    function _beginSimulationPrank() internal returns (bool) {
        address a = vm.envOr("SIMULATION_PRANK", address(0));
        if (a != address(0)) {
            vm.startPrank(a);
            return true;
        }
        return false;
    }

    function _endSimulationPrank(bool active) internal {
        if (active) vm.stopPrank();
    }
}
