// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {RiskUpdatePayload} from "../src/payloads/RiskUpdatePayload.sol";
import {RiskParametersConfig} from "../src/config/RiskParametersConfig.sol";
import {IRiskParametersConfig} from "../src/config/interface/IRiskParametersConfig.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {TokensRegistry} from "../src/config/TokensRegistry.sol";
import {ITokensRegistry} from "../src/config/interface/ITokensRegistry.sol";
import {NetworkConfig} from "../src/config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";
import {IPoolAddressesProvider} from "lib/K613-Protocol/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {IACLManager} from "lib/K613-Protocol/src/contracts/interfaces/IACLManager.sol";
import {SimulationPrank} from "./SimulationPrank.sol";

/// @title ConfigureRisk
/// @notice Script for final risk parameter configuration
contract ConfigureRisk is Script, SimulationPrank {
    error ZeroPoolAddressesProvider();
    error ZeroAclManager();
    error ZeroRiskParameters();

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
        console.log("Executing RiskUpdatePayload...");

        address registryAddr;
        bool registryFromEnv;
        try vm.envAddress("TOKENS_REGISTRY_CONFIG") returns (address reg) {
            registryAddr = reg;
            registryFromEnv = true;
        } catch {
            registryFromEnv = false;
        }

        address riskParametersAddr;
        bool riskFromEnv;
        try vm.envAddress("RISK_PARAMETERS_CONFIG") returns (address configured) {
            riskParametersAddr = configured;
            riskFromEnv = true;
        } catch {
            riskFromEnv = false;
        }

        if (!riskFromEnv) {
            if (!registryFromEnv) {
                TokensRegistry deployedRegistry = new TokensRegistry(deployer);
                registryAddr = address(deployedRegistry);
                console.log("Deployed TokensRegistry at:", registryAddr);
            }
            RiskParametersConfig deployed = new RiskParametersConfig(deployer, registryAddr);
            riskParametersAddr = address(deployed);
            console.log("Deployed RiskParametersConfig at:", riskParametersAddr);
        }
        if (riskParametersAddr == address(0)) revert ZeroRiskParameters();

        RiskUpdatePayload riskUpdatePayload = new RiskUpdatePayload(riskParametersAddr);
        console.log("RiskUpdatePayload deployed at:", address(riskUpdatePayload));

        // Get tokens to display what will be configured
        // Note: Using ArbitrumSepolia as default - change NETWORK constant in RiskUpdatePayload to switch
        TokensConfig.Network network = TokensConfig.Network.MonadMainnet;
        NetworkConfig.Addresses memory addrs = _getAddresses(network);

        address provider = addrs.poolAddressesProvider;
        if (provider == address(0)) revert ZeroPoolAddressesProvider();
        address aclManagerAddress = IPoolAddressesProvider(provider).getACLManager();
        if (aclManagerAddress == address(0)) revert ZeroAclManager();

        console.log("ACLManager:", aclManagerAddress);
        IACLManager aclManager = IACLManager(aclManagerAddress);
        bool prank = _beginSimulationPrank();
        if (!aclManager.isRiskAdmin(address(riskUpdatePayload))) {
            console.log("Granting RiskAdmin to payload...");
            aclManager.addRiskAdmin(address(riskUpdatePayload));
        }
        _endSimulationPrank(prank);
        ITokensRegistry reg = IRiskParametersConfig(riskParametersAddr).tokensRegistry();
        TokensConfig.Token[] memory tokens = reg.getTokens(network);
        IRiskParametersConfig.RiskParams[] memory riskParams =
            IRiskParametersConfig(riskParametersAddr).getRiskParams(network);

        console.log("Updating risk parameters for", tokens.length, "tokens...");

        for (uint256 i = 0; i < tokens.length; i++) {
            console.log("Token:", tokens[i].symbol);
            console.log("  Asset:", riskParams[i].asset);
            console.log("  Borrow cap:", riskParams[i].borrowCap);
            console.log("  Supply cap:", riskParams[i].supplyCap);
            console.log("  Reserve factor:", riskParams[i].reserveFactor);
        }

        console.log("Setting borrow/supply caps and reserve factors...");
        prank = _beginSimulationPrank();
        riskUpdatePayload.execute();
        _endSimulationPrank(prank);

        console.log("Risk parameters configured successfully!");

        if (!skipBroadcast) vm.stopBroadcast();

        console.log("RiskUpdatePayload execution complete!");
    }

    function _getAddresses(TokensConfig.Network network) private pure returns (NetworkConfig.Addresses memory) {
        if (network == TokensConfig.Network.ArbitrumSepolia) {
            return ArbitrumSepolia.getAddresses();
        }
        if (network == TokensConfig.Network.MonadMainnet) {
            return MonadMainnet.getAddresses();
        }
        revert("Unsupported network");
    }
}

