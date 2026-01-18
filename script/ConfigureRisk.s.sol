// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {RiskUpdatePayload} from "../src/payloads/RiskUpdatePayload.sol";
import {RiskConfig} from "../src/config/RiskConfig.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";

/// @title ConfigureRisk
/// @notice Script for final risk parameter configuration
contract ConfigureRisk is Script {
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
        console.log("Executing RiskUpdatePayload...");

        // Deploy RiskUpdatePayload (stateless, execute-only payload)
        RiskUpdatePayload riskUpdatePayload = new RiskUpdatePayload();
        console.log("RiskUpdatePayload deployed at:", address(riskUpdatePayload));

        // Get tokens to display what will be configured
        // Note: Using ArbitrumSepolia as default - change NETWORK constant in RiskUpdatePayload to switch
        TokensConfig.Network network = TokensConfig.Network.ArbitrumSepolia;
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(network);
        RiskConfig.RiskParams[] memory riskParams = RiskConfig.getRiskParams(network);

        console.log("Updating risk parameters for", tokens.length, "tokens...");

        for (uint256 i = 0; i < tokens.length; i++) {
            console.log("Token:", tokens[i].symbol);
            console.log("  Asset:", riskParams[i].asset);
            console.log("  Borrow cap:", riskParams[i].borrowCap);
            console.log("  Supply cap:", riskParams[i].supplyCap);
            console.log("  Reserve factor:", riskParams[i].reserveFactor);
        }

        // Execute payload to set risk parameters (caps and reserve factor)
        console.log("Setting borrow/supply caps and reserve factors...");
        riskUpdatePayload.execute();

        console.log("Risk parameters configured successfully!");

        vm.stopBroadcast();

        console.log("RiskUpdatePayload execution complete!");
    }
}

