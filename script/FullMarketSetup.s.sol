// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {ListingPayload} from "../src/payloads/ListingPayload.sol";
import {CollateralConfigPayload} from "../src/payloads/CollateralConfigPayload.sol";
import {RiskUpdatePayload} from "../src/payloads/RiskUpdatePayload.sol";
import {OracleUpdatePayload} from "../src/payloads/OracleUpdatePayload.sol";

/// @title FullMarketSetup
/// @notice Complete market setup script executing all payloads in correct order
/// @dev Executes payloads in the correct Aave v3 order:
///      1. ConfigureOracles (OracleUpdatePayload)
///      2. ListAssets (ListingPayload - initReserves)
///      3. ConfigureCollateral (CollateralConfigPayload - LTV/LT/LB + borrowing)
///      4. ConfigureRisk (RiskUpdatePayload - caps + reserve factor)
contract FullMarketSetup is Script {
    function run() external {
        // Try to get private key from env, fallback to broadcast() if not set
        address deployer;
        bool useEnvKey = false;

        try vm.envUint("PRIVATE_KEY") returns (uint256 pk) {
            deployer = vm.addr(pk);
            vm.startBroadcast(pk);
            useEnvKey = true;
        } catch {
            // Use --private-key from command line
            vm.startBroadcast();
            // Get deployer from wallets
            address[] memory wallets = vm.getWallets();
            if (wallets.length > 0) {
                deployer = wallets[0];
            } else {
                deployer = tx.origin;
            }
        }

        console.log("Deployer address:", deployer);
        console.log("Starting full market setup...\n");

        // Step 1: Configure Oracles
        console.log("=== Step 1: Configuring Oracles ===");
        OracleUpdatePayload oraclePayload = new OracleUpdatePayload();
        console.log("OracleUpdatePayload deployed at:", address(oraclePayload));
        oraclePayload.execute();
        console.log("Oracles configured successfully!\n");

        // Step 2: Initialize Reserves (Listing)
        console.log("=== Step 2: Initializing Reserves (Listing) ===");
        ListingPayload listingPayload = new ListingPayload();
        console.log("ListingPayload deployed at:", address(listingPayload));
        listingPayload.execute();
        console.log("Reserves initialized successfully!\n");

        // Step 3: Configure Collateral Parameters
        console.log("=== Step 3: Configuring Collateral Parameters ===");
        CollateralConfigPayload collateralPayload = new CollateralConfigPayload();
        console.log("CollateralConfigPayload deployed at:", address(collateralPayload));
        collateralPayload.execute();
        console.log("Collateral parameters configured successfully!\n");

        // Step 4: Configure Risk Parameters
        console.log("=== Step 4: Configuring Risk Parameters ===");
        RiskUpdatePayload riskPayload = new RiskUpdatePayload();
        console.log("RiskUpdatePayload deployed at:", address(riskPayload));
        riskPayload.execute();
        console.log("Risk parameters configured successfully!\n");

        vm.stopBroadcast();

        console.log("==========================================");
        console.log("Full market setup completed successfully!");
        console.log("==========================================");
    }
}
