// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "lib/forge-std/src/Script.sol";

import {IPoolConfigurator} from "lib/K613-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {IPoolAddressesProvider} from "lib/K613-Protocol/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {IRiskParametersConfig} from "../src/config/interface/IRiskParametersConfig.sol";
import {ITokensRegistry} from "../src/config/interface/ITokensRegistry.sol";
import {NetworkConfig} from "../src/config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";
import {SimulationPrank} from "./SimulationPrank.sol";

/// @title ConfigureCollateral
/// @notice Configure collateral parameters (LTV, LT, LB) and enable borrowing
/// @dev Aave v3 compatible script (configureReserveAsCollateral ONLY)
contract ConfigureCollateral is Script, SimulationPrank {
    error ZeroPoolAddressesProvider();
    error ZeroPool();
    error ZeroPoolConfigurator();
    error PoolMismatch();
    error ConfiguratorMismatch();
    error TokensRiskLengthMismatch();
    error ZeroRiskParameters();
    error TargetHasNoCode(string label);

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

        console.log("Deployer:", deployer);
        console.log("Configuring collateral parameters via Aave v3 API...");

        // --- load config ---
        NetworkConfig.Addresses memory addrs = _getAddresses();
        address provider = addrs.poolAddressesProvider;
        if (provider == address(0)) revert ZeroPoolAddressesProvider();
        _requireHasCode(provider, "POOL_ADDRESSES_PROVIDER");

        address pool = IPoolAddressesProvider(provider).getPool();
        address configuratorFromProvider = IPoolAddressesProvider(provider).getPoolConfigurator();
        address configuratorAddress = NetworkConfig.getPoolConfigurator(addrs);

        if (pool == address(0)) revert ZeroPool();
        if (configuratorFromProvider == address(0)) revert ZeroPoolConfigurator();
        if (addrs.pool != address(0) && addrs.pool != pool) revert PoolMismatch();
        if (configuratorAddress != configuratorFromProvider) revert ConfiguratorMismatch();

        _requireHasCode(pool, "POOL");
        _requireHasCode(configuratorAddress, "POOL_CONFIGURATOR");

        console.log("PoolAddressesProvider:", provider);
        console.log("Pool:", pool);
        console.log("PoolConfigurator:", configuratorAddress);

        IPoolConfigurator configurator = IPoolConfigurator(configuratorAddress);

        address riskParametersAddr = vm.envAddress("RISK_PARAMETERS_CONFIG");
        if (riskParametersAddr == address(0)) revert ZeroRiskParameters();
        IRiskParametersConfig riskParameters = IRiskParametersConfig(riskParametersAddr);
        ITokensRegistry tokensRegistry = riskParameters.tokensRegistry();

        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(NETWORK);
        IRiskParametersConfig.RiskParams[] memory risks = riskParameters.getRiskParams(NETWORK);

        if (tokens.length != risks.length) revert TokensRiskLengthMismatch();

        uint256 success;
        uint256 failed;

        for (uint256 i = 0; i < tokens.length; i++) {
            IRiskParametersConfig.RiskParams memory r = risks[i];

            console.log("--------------------------------------------------");
            console.log("Asset:", r.asset);
            console.log("LTV:", r.ltv);
            console.log("LT :", r.liquidationThreshold);
            console.log("LB :", r.liquidationBonus);

            bool prank = _beginSimulationPrank();
            try configurator.configureReserveAsCollateral(r.asset, r.ltv, r.liquidationThreshold, r.liquidationBonus) {
                configurator.setReserveBorrowing(r.asset, true);
                console.log(" collateral configured & borrowing enabled");
                success++;
            } catch (bytes memory reason) {
                console.log("FAILED (likely missing ACL permissions)");
                console.logBytes(reason);
                failed++;
            }
            _endSimulationPrank(prank);
        }

        console.log("--------------------------------------------------");
        console.log("SUCCESS:", success);
        console.log("FAILED :", failed);
        console.log("ConfigureCollateral finished");

        if (!skipBroadcast) vm.stopBroadcast();
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

    function _requireHasCode(address target, string memory label) private view {
        if (target.code.length == 0) revert TargetHasNoCode(label);
    }
}
