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
import {SimulationPrank} from "./SimulationPrank.sol";

/// @title FullMarketSetup
/// @notice Complete market setup script executing all payloads in correct order
/// @dev Executes payloads in the correct Aave v3 order:
///      1. ConfigureOracles (OracleUpdatePayload)
///      2. ListAssets (ListingPayload - initReserves)
///      3. ConfigureCollateral (CollateralConfigPayload - LTV/LT/LB + borrowing)
///      4. ConfigureRisk (RiskUpdatePayload - caps + reserve factor)
contract FullMarketSetup is Script, SimulationPrank {
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
        console.log("Starting full market setup...\n");

        // Resolve ACLManager
        NetworkConfig.Addresses memory addrs = _getAddresses();
        IACLManager aclManager = IACLManager(IPoolAddressesProvider(addrs.poolAddressesProvider).getACLManager());

        console.log("=== Step 1: Configuring Oracles ===");
        OracleUpdatePayload oraclePayload = new OracleUpdatePayload();
        console.log("OracleUpdatePayload deployed at:", address(oraclePayload));
        bool prank = _beginSimulationPrank();
        aclManager.addAssetListingAdmin(address(oraclePayload));
        oraclePayload.execute();
        aclManager.removeAssetListingAdmin(address(oraclePayload));
        _endSimulationPrank(prank);
        console.log("Oracles configured successfully!\n");

        console.log("=== Step 2: Initializing Reserves (Listing) ===");
        ListingPayload listingPayload = new ListingPayload();
        console.log("ListingPayload deployed at:", address(listingPayload));
        prank = _beginSimulationPrank();
        aclManager.addAssetListingAdmin(address(listingPayload));
        listingPayload.execute();
        aclManager.removeAssetListingAdmin(address(listingPayload));
        _endSimulationPrank(prank);
        console.log("Reserves initialized successfully!\n");

        console.log("=== Step 3: Configuring Collateral Parameters ===");
        CollateralConfigPayload collateralPayload = new CollateralConfigPayload();
        console.log("CollateralConfigPayload deployed at:", address(collateralPayload));
        prank = _beginSimulationPrank();
        aclManager.addRiskAdmin(address(collateralPayload));
        collateralPayload.execute();
        aclManager.removeRiskAdmin(address(collateralPayload));
        _endSimulationPrank(prank);
        console.log("Collateral parameters configured successfully!\n");

        console.log("=== Step 4: Configuring Risk Parameters ===");
        RiskUpdatePayload riskPayload = new RiskUpdatePayload();
        console.log("RiskUpdatePayload deployed at:", address(riskPayload));
        prank = _beginSimulationPrank();
        aclManager.addRiskAdmin(address(riskPayload));
        riskPayload.execute();
        aclManager.removeRiskAdmin(address(riskPayload));
        _endSimulationPrank(prank);
        console.log("Risk parameters configured successfully!\n");

        if (!skipBroadcast) vm.stopBroadcast();

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
