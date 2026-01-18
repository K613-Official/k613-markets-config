// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {OraclesConfig} from "../src/config/OraclesConfig.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";

/// @title ConfigureOracles
/// @notice Script to configure Chainlink price feeds via AaveOracle
contract ConfigureOracles is Script {
    // Change this constant to switch networks
    TokensConfig.Network internal constant NETWORK = TokensConfig.Network.ArbitrumSepolia;

    function run() external {
        // Try to get private key from env, fallback to broadcast() if not set
        address deployer;

        try vm.envUint("PRIVATE_KEY") returns (uint256 pk) {
            deployer = vm.addr(pk);
            vm.startBroadcast(pk);
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
        console.log("Configuring oracles...");

        address oracleAddress = _getOracle();

        // Configure oracles directly via deployer
        // Deployer must have Pool Admin or Asset Listing Admin rights
        console.log("Configuring price feeds...");
        OraclesConfig.configureOracles(oracleAddress, NETWORK);
        console.log("Oracles configured successfully!");

        // Verify oracles using OraclesConfig library
        console.log("Verifying oracles...");
        (bool success, address[] memory invalidAssets) = OraclesConfig.verifyOracles(oracleAddress, NETWORK);

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

    function _getOracle() private pure returns (address) {
        if (NETWORK == TokensConfig.Network.ArbitrumSepolia) {
            return ArbitrumSepolia.ORACLE;
        } else {
            revert("Unsupported network");
        }
    }
}

