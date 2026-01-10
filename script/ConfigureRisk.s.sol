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
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployer);
        console.log("Executing RiskUpdatePayload...");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy RiskUpdatePayload (stateless, execute-only payload)
        RiskUpdatePayload riskUpdatePayload = new RiskUpdatePayload();
        console.log("RiskUpdatePayload deployed at:", address(riskUpdatePayload));

        // Get tokens to display what will be configured
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens();
        RiskConfig.RiskParams[] memory riskParams = RiskConfig.getRiskParams();

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

    /// @notice Executes RiskUpdatePayload from a deployed address
    /// @param riskUpdatePayload RiskUpdatePayload contract address
    function executeRiskUpdatePayload(address riskUpdatePayload) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        RiskUpdatePayload(riskUpdatePayload).execute();

        console.log("RiskUpdatePayload executed successfully!");

        vm.stopBroadcast();
    }
}

