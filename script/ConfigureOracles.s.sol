// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {SimulationPrank} from "./SimulationPrank.sol";
import {OraclesConfig} from "../src/config/OraclesConfig.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";

/// @title ConfigureOracles
/// @notice Script to configure Chainlink price feeds via AaveOracle
contract ConfigureOracles is Script, SimulationPrank {
    // Change this constant to switch networks
    TokensConfig.Network internal constant NETWORK = TokensConfig.Network.MonadMainnet;

    function run() external {
        address deployer;
        uint256 pk;
        bool pkResolved;

        try vm.envUint("PRIVATE_KEY") returns (uint256 pk_) {
            pk = pk_;
            pkResolved = true;
            deployer = vm.addr(pk_);
        } catch {
            address[] memory wallets = vm.getWallets();
            deployer = wallets.length > 0 ? wallets[0] : tx.origin;
        }

        bool skipBroadcast = _simulationPrankActive();
        if (!skipBroadcast) {
            if (pkResolved) vm.startBroadcast(pk);
            else vm.startBroadcast();
        }

        console.log("Deployer address:", deployer);
        console.log("Configuring oracles...");

        address oracleAddress = _getOracle();

        // Configure oracles directly via deployer
        // Deployer must have Pool Admin or Asset Listing Admin rights
        console.log("Configuring price feeds...");
        bool prank = _beginSimulationPrank();
        OraclesConfig.configureOracles(oracleAddress, NETWORK);
        _endSimulationPrank(prank);
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

        if (!skipBroadcast) vm.stopBroadcast();

        console.log("Oracle configuration complete!");
    }

    function _getOracle() private pure returns (address) {
        if (NETWORK == TokensConfig.Network.ArbitrumSepolia) {
            return ArbitrumSepolia.ORACLE;
        } else if (NETWORK == TokensConfig.Network.MonadMainnet) {
            return MonadMainnet.ORACLE;
        } else {
            revert("Unsupported network");
        }
    }
}

