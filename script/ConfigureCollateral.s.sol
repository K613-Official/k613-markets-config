// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {IPoolConfigurator, IPoolAddressesProvider} from "../src/interfaces/IAaveExternal.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {RiskConfig} from "../src/config/RiskConfig.sol";
import {NetworkConfig} from "../src/config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";

/// @title ConfigureCollateral
/// @notice Script to configure collateral parameters (LTV, LT, LB) and enable borrowing
/// @dev Configures collateral parameters directly via deployer
contract ConfigureCollateral is Script {
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
        console.log("Configuring collateral parameters (LTV, LT, LB)...");
        console.log("Enabling variable rate borrowing...");

        NetworkConfig.Addresses memory addrs = _getAddresses();
        IPoolConfigurator configurator = IPoolConfigurator(NetworkConfig.getPoolConfigurator(addrs));
        IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(addrs.poolAddressesProvider);

        // Проверяем PoolDataProvider через PoolAddressesProvider
        address poolDataProvider = addressesProvider.getPoolDataProvider();
        console.log("PoolDataProvider address:", poolDataProvider);

        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(NETWORK);
        RiskConfig.RiskParams[] memory riskParams = RiskConfig.getRiskParams(NETWORK);
        require(riskParams.length == tokens.length, "Risk params length mismatch");

        // Configure collateral parameters directly via deployer using separate methods
        // Deployer must have Pool Admin or Risk Admin rights
        // Using separate methods (setLtv, setLiquidationThreshold, setLiquidationBonus)
        // instead of configureReserveAsCollateral to avoid PoolDataProvider internal issues
        // PoolDataProvider exists but PoolConfigurator.configureReserveAsCollateral
        // cannot access it correctly, so we use direct methods
        uint256 successCount = 0;
        uint256 skipCount = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            RiskConfig.RiskParams memory risk = riskParams[i];
            bool assetSuccess = true;

            // Set LTV
            try configurator.setLtv(risk.asset, risk.ltv) {
                console.log("Set LTV for:", risk.asset);
            } catch (bytes memory reason) {
                console.log("Failed to set LTV for:", risk.asset);
                console.logBytes(reason);
                assetSuccess = false;
            }

            // Set Liquidation Threshold
            if (assetSuccess) {
                try configurator.setLiquidationThreshold(risk.asset, risk.liquidationThreshold) {
                    console.log("Set Liquidation Threshold for:", risk.asset);
                } catch (bytes memory reason) {
                    console.log("Failed to set Liquidation Threshold for:", risk.asset);
                    console.logBytes(reason);
                    assetSuccess = false;
                }
            }

            // Set Liquidation Bonus
            if (assetSuccess) {
                try configurator.setLiquidationBonus(risk.asset, risk.liquidationBonus) {
                    console.log("Set Liquidation Bonus for:", risk.asset);
                } catch (bytes memory reason) {
                    console.log("Failed to set Liquidation Bonus for:", risk.asset);
                    console.logBytes(reason);
                    assetSuccess = false;
                }
            }

            // Enable variable rate borrowing
            if (assetSuccess) {
                try configurator.setReserveBorrowing(risk.asset, true) {
                    console.log("Configured:", risk.asset);
                    successCount++;
                } catch {
                    console.log("Failed to enable borrowing for:", risk.asset);
                    assetSuccess = false;
                    skipCount++;
                }
            } else {
                skipCount++;
            }
        }

        console.log("Configured:", successCount, "Skipped:", skipCount);

        console.log("Collateral configuration complete!");

        vm.stopBroadcast();

        console.log("Collateral configuration execution complete!");
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
