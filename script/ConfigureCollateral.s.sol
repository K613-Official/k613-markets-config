// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {CollateralConfigPayload} from "../src/payloads/CollateralConfigPayload.sol";

/// @title ConfigureCollateral
/// @notice Script to execute CollateralConfigPayload
/// @dev Configures collateral parameters (LTV, LT, LB) and enables borrowing
contract ConfigureCollateral is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployer);
        console.log("Executing CollateralConfigPayload...");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy CollateralConfigPayload (stateless, execute-only payload)
        CollateralConfigPayload collateralPayload = new CollateralConfigPayload();
        console.log("CollateralConfigPayload deployed at:", address(collateralPayload));

        // Execute payload to configure collateral parameters
        console.log("Configuring collateral parameters (LTV, LT, LB)...");
        console.log("Enabling variable rate borrowing...");
        collateralPayload.execute();

        console.log("Collateral configuration complete!");

        vm.stopBroadcast();

        console.log("CollateralConfigPayload execution complete!");
    }

    /// @notice Executes CollateralConfigPayload from a deployed address
    /// @param collateralPayload CollateralConfigPayload contract address
    function executeCollateralPayload(address collateralPayload) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        CollateralConfigPayload(collateralPayload).execute();
        console.log("CollateralConfigPayload executed successfully!");

        vm.stopBroadcast();
    }
}
