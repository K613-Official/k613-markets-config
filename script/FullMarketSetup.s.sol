// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {ListingPayload} from "../src/payloads/ListingPayload.sol";
import {CollateralConfigPayload} from "../src/payloads/CollateralConfigPayload.sol";
import {RiskUpdatePayload} from "../src/payloads/RiskUpdatePayload.sol";
import {OracleUpdatePayload} from "../src/payloads/OracleUpdatePayload.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {NetworkConfig} from "../src/config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";
import {IPoolAddressesProvider} from "lib/K613-Protocol/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {IACLManager} from "lib/K613-Protocol/src/contracts/interfaces/IACLManager.sol";

/// @title FullMarketSetup
/// @notice Complete market setup script executing all payloads in correct order
/// @dev Executes payloads in the correct Aave v3 order:
///      1. ConfigureOracles (OracleUpdatePayload)
///      2. ListAssets (ListingPayload - initReserves)
///      3. ConfigureCollateral (CollateralConfigPayload - LTV/LT/LB + borrowing)
///      4. ConfigureRisk (RiskUpdatePayload - caps + reserve factor)
contract FullMarketSetup is Script {
    TokensConfig.Network internal constant NETWORK = TokensConfig.Network.MonadMainnet;

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
        console.log("Starting full market setup...\n");

        // Resolve ACLManager
        NetworkConfig.Addresses memory addrs = _getAddresses();
        IACLManager aclManager = IACLManager(
            IPoolAddressesProvider(addrs.poolAddressesProvider).getACLManager()
        );

        // Step 1: Configure Oracles (requires AssetListingAdmin or PoolAdmin)
        console.log("=== Step 1: Configuring Oracles ===");
        OracleUpdatePayload oraclePayload = new OracleUpdatePayload();
        console.log("OracleUpdatePayload deployed at:", address(oraclePayload));
        aclManager.addAssetListingAdmin(address(oraclePayload));
        oraclePayload.execute();
        aclManager.removeAssetListingAdmin(address(oraclePayload));
        console.log("Oracles configured successfully!\n");

        // Step 2: Initialize Reserves (requires AssetListingAdmin or PoolAdmin)
        console.log("=== Step 2: Initializing Reserves (Listing) ===");
        ListingPayload listingPayload = new ListingPayload();
        console.log("ListingPayload deployed at:", address(listingPayload));
        aclManager.addAssetListingAdmin(address(listingPayload));
        listingPayload.execute();
        aclManager.removeAssetListingAdmin(address(listingPayload));
        console.log("Reserves initialized successfully!\n");

        // Step 3: Configure Collateral Parameters (requires RiskAdmin or PoolAdmin)
        console.log("=== Step 3: Configuring Collateral Parameters ===");
        CollateralConfigPayload collateralPayload = new CollateralConfigPayload();
        console.log("CollateralConfigPayload deployed at:", address(collateralPayload));
        aclManager.addRiskAdmin(address(collateralPayload));
        collateralPayload.execute();
        aclManager.removeRiskAdmin(address(collateralPayload));
        console.log("Collateral parameters configured successfully!\n");

        // Step 4: Configure Risk Parameters (requires RiskAdmin or PoolAdmin)
        console.log("=== Step 4: Configuring Risk Parameters ===");
        RiskUpdatePayload riskPayload = new RiskUpdatePayload();
        console.log("RiskUpdatePayload deployed at:", address(riskPayload));
        aclManager.addRiskAdmin(address(riskPayload));
        riskPayload.execute();
        aclManager.removeRiskAdmin(address(riskPayload));
        console.log("Risk parameters configured successfully!\n");

        vm.stopBroadcast();

        console.log("==========================================");
        console.log("Full market setup completed successfully!");
        console.log("==========================================");
    }

    function _getAddresses() private pure returns (NetworkConfig.Addresses memory) {
        if (NETWORK == TokensConfig.Network.ArbitrumSepolia) {
            return ArbitrumSepolia.getAddresses();
        }
        if (NETWORK == TokensConfig.Network.MonadMainnet) {
            return MonadMainnet.getAddresses();
        }
        revert("Unsupported network");
    }
}
