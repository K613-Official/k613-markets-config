// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {OracleUpdatePayload} from "../src/payloads/OracleUpdatePayload.sol";
import {OraclesConfig} from "../src/config/OraclesConfig.sol";
import {ArbitrumSepoliaAddresses} from "../src/config/ArbitrumSepoliaAddresses.sol";

/// @title ConfigureOracles
/// @notice Script to configure Chainlink price feeds via AaveOracle
contract ConfigureOracles is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployer);
        console.log("Configuring oracles...");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy OracleUpdatePayload
        OracleUpdatePayload oraclePayload = new OracleUpdatePayload();
        console.log("OracleUpdatePayload deployed at:", address(oraclePayload));

        // Configure all oracles
        console.log("Configuring price feeds...");
        oraclePayload.execute();

        // Verify oracles using OraclesConfig library
        console.log("Verifying oracles...");
        (bool success, address[] memory invalidAssets) = OraclesConfig.verifyOracles(ArbitrumSepoliaAddresses.ORACLE);

        if (success) {
            console.log("All oracles configured successfully!");
        } else {
            console.log("Some oracles have invalid prices:");
            for (uint256 i = 0; i < invalidAssets.length; i++) {
                console.log("  Invalid asset:", invalidAssets[i]);
            }
        }

        vm.stopBroadcast();

        console.log("Oracle configuration complete!");
    }

    /// @notice Verifies a single asset price
    /// @param asset Asset address
    function verifyAssetPrice(address asset) external view {
        address source = OraclesConfig.getPriceFeedSource(ArbitrumSepoliaAddresses.ORACLE, asset);
        require(source != address(0), "Price feed not set");
        console.log("Asset", asset, "price feed source:", source);
    }
}

