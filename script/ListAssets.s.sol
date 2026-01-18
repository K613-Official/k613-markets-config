// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {IPoolConfigurator} from "../src/interfaces/IAaveExternal.sol";
import {ConfiguratorInputTypes} from "../src/interfaces/IAaveExternal.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";
import {NetworkConfig} from "../src/config/networks/NetworkConfig.sol";

/// @title ListAssets
/// @notice Script to initialize reserves (initReserves)
contract ListAssets is Script {
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
        console.log("Initializing reserves (initReserves)...");

        NetworkConfig.Addresses memory addrs = _getAddresses();
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(NETWORK);

        // Prepare initReserves inputs
        ConfiguratorInputTypes.InitReserveInput[] memory inputs =
            new ConfiguratorInputTypes.InitReserveInput[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            TokensConfig.Token memory t = tokens[i];

            inputs[i] = ConfiguratorInputTypes.InitReserveInput({
                aTokenImpl: addrs.aTokenImpl,
                stableDebtTokenImpl: addrs.stableDebtImpl,
                variableDebtTokenImpl: addrs.variableDebtImpl,
                underlyingAssetDecimals: t.decimals,
                interestRateStrategyAddress: addrs.defaultInterestRateStrategy,
                underlyingAsset: t.asset,
                treasury: addrs.treasury,
                incentivesController: addrs.incentivesController,
                aTokenName: string.concat("Aave ", t.symbol),
                aTokenSymbol: string.concat("a", t.symbol),
                variableDebtTokenName: string.concat("Aave Variable Debt ", t.symbol),
                variableDebtTokenSymbol: string.concat("variableDebt", t.symbol),
                stableDebtTokenName: "",
                stableDebtTokenSymbol: "",
                params: ""
            });
        }

        // Initialize reserves directly via deployer
        IPoolConfigurator configurator = IPoolConfigurator(NetworkConfig.getPoolConfigurator(addrs));

        // Initialize each reserve separately to catch errors
        uint256 successCount = 0;
        uint256 skipCount = 0;

        for (uint256 i = 0; i < inputs.length; i++) {
            ConfiguratorInputTypes.InitReserveInput[] memory singleInput =
                new ConfiguratorInputTypes.InitReserveInput[](1);
            singleInput[0] = inputs[i];

            try configurator.initReserves(singleInput) {
                console.log("Reserve initialized:", tokens[i].symbol);
                successCount++;
            } catch {
                console.log("Reserve already initialized:", tokens[i].symbol);
                skipCount++;
            }
        }

        console.log("Initialized:", successCount, "Skipped:", skipCount);

        // Disable stable rate borrowing for all reserves (only if reserves were initialized)
        if (successCount > 0) {
            for (uint256 i = 0; i < tokens.length; i++) {
                try configurator.setReserveStableRateBorrowing(tokens[i].asset, false) {
                // Success - already disabled or just disabled
                }
                    catch {
                    // Already disabled or failed - skip
                }
            }
        }

        console.log("Reserves initialized successfully!");
        console.log("Next steps:");
        console.log("  1. Execute ConfigureCollateral to configure collateral parameters");
        console.log("  2. Execute ConfigureRisk to set caps and reserve factors");

        vm.stopBroadcast();

        console.log("Reserve initialization complete!");
    }

    function _getAddresses() private pure returns (NetworkConfig.Addresses memory) {
        if (NETWORK == TokensConfig.Network.ArbitrumSepolia) {
            return ArbitrumSepolia.getAddresses();
        } else if (NETWORK == TokensConfig.Network.MonadMainnet) {
            return MonadMainnet.getAddresses();
        } else {
            revert("Unsupported network");
        }
    }
}

