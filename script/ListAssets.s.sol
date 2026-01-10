// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {ListingPayload} from "../src/payloads/ListingPayload.sol";

/// @title ListAssets
/// @notice Script to execute ListingPayload
contract ListAssets is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployer);
        console.log("Executing ListingPayload (initReserves)...");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy ListingPayload
        ListingPayload listingPayload = new ListingPayload();
        console.log("ListingPayload deployed at:", address(listingPayload));

        // Execute payload to initialize reserves
        console.log("Initializing reserves (initReserves)...");
        listingPayload.execute();

        console.log("Reserves initialized successfully!");
        console.log("Next steps:");
        console.log("  1. Execute CollateralConfigPayload to configure collateral parameters");
        console.log("  2. Execute RiskUpdatePayload to set caps and reserve factors");

        vm.stopBroadcast();

        console.log("ListingPayload execution complete!");
    }

    /// @notice Executes ListingPayload from a deployed address
    /// @param listingPayload ListingPayload contract address
    function executeListingPayload(address listingPayload) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        ListingPayload(listingPayload).execute();
        console.log("ListingPayload executed successfully!");

        vm.stopBroadcast();
    }
}

