// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {IPool} from "lib/K613-Protocol/src/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "lib/K613-Protocol/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPoolConfigurator} from "lib/K613-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {
    IDefaultInterestRateStrategyV2
} from "lib/K613-Protocol/src/contracts/interfaces/IDefaultInterestRateStrategyV2.sol";
import {
    ConfiguratorInputTypes
} from "lib/K613-Protocol/src/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {TokensRegistry} from "../src/config/TokensRegistry.sol";
import {ITokensRegistry} from "../src/config/interface/ITokensRegistry.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";
import {NetworkConfig} from "../src/config/networks/NetworkConfig.sol";
import {SimulationPrank} from "./SimulationPrank.sol";

/// @title ListAssets
/// @notice Script to initialize reserves (initReserves)
contract InitReserves is Script, SimulationPrank {
    error PoolUnresolved();

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
        console.log("Initializing reserves (initReserves)...");

        NetworkConfig.Addresses memory addrs = _getAddresses();

        address registryAddr;
        try vm.envAddress("TOKENS_REGISTRY_CONFIG") returns (address reg) {
            registryAddr = reg;
        } catch {
            TokensRegistry deployedRegistry = new TokensRegistry(deployer);
            registryAddr = address(deployedRegistry);
            console.log("Deployed TokensRegistry at:", registryAddr);
        }
        ITokensRegistry tokensRegistry = ITokensRegistry(registryAddr);
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(NETWORK);

        address poolAddr = addrs.pool;
        if (poolAddr == address(0)) {
            if (addrs.poolAddressesProvider == address(0)) revert PoolUnresolved();
            poolAddr = IPoolAddressesProvider(addrs.poolAddressesProvider).getPool();
        }
        if (poolAddr == address(0)) revert PoolUnresolved();
        IPool pool = IPool(poolAddr);

        // Prepare initReserves inputs
        ConfiguratorInputTypes.InitReserveInput[] memory inputs =
            new ConfiguratorInputTypes.InitReserveInput[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            TokensConfig.Token memory t = tokens[i];

            inputs[i] = ConfiguratorInputTypes.InitReserveInput({
                aTokenImpl: addrs.aTokenImpl,
                variableDebtTokenImpl: addrs.variableDebtImpl,
                useVirtualBalance: true,
                interestRateStrategyAddress: addrs.defaultInterestRateStrategy,
                underlyingAsset: t.asset,
                treasury: addrs.treasury,
                incentivesController: addrs.incentivesController,
                aTokenName: string.concat("Aave ", t.symbol),
                aTokenSymbol: string.concat("a", t.symbol),
                variableDebtTokenName: string.concat("Aave Variable Debt ", t.symbol),
                variableDebtTokenSymbol: string.concat("variableDebt", t.symbol),
                params: "",
                interestRateData: _getInterestRateData(t.symbol)
            });
        }

        // Initialize reserves directly via deployer
        IPoolConfigurator configurator = IPoolConfigurator(NetworkConfig.getPoolConfigurator(addrs));

        // Initialize each reserve separately to catch errors
        uint256 successCount = 0;
        uint256 skipCount = 0;

        for (uint256 i = 0; i < inputs.length; i++) {
            if (pool.getReserveData(tokens[i].asset).aTokenAddress != address(0)) {
                console.log("Reserve already initialized:", tokens[i].symbol);
                skipCount++;
                continue;
            }

            ConfiguratorInputTypes.InitReserveInput[] memory singleInput =
                new ConfiguratorInputTypes.InitReserveInput[](1);
            singleInput[0] = inputs[i];

            bool prank = _beginSimulationPrank();
            try configurator.initReserves(singleInput) {
                console.log("Reserve initialized:", tokens[i].symbol);
                successCount++;
            } catch {
                console.log("Reserve init reverted (skipped):", tokens[i].symbol);
                skipCount++;
            }
            _endSimulationPrank(prank);
        }

        console.log("Initialized:", successCount, "Skipped:", skipCount);

        console.log("Reserves initialized successfully!");
        console.log("Next steps:");
        console.log("  1. Execute ConfigureCollateral to configure collateral parameters");
        console.log("  2. Execute ConfigureRisk to set caps and reserve factors");

        if (!skipBroadcast) vm.stopBroadcast();

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

    /// @notice Keccak256 over the UTF-8 bytes of a string.
    function _hashString(string memory str) private pure returns (bytes32 hash) {
        assembly {
            hash := keccak256(add(str, 0x20), mload(str))
        }
    }

    /// @notice Returns per-asset interest rate data based on asset class.
    function _getInterestRateData(string memory symbol) private pure returns (bytes memory) {
        bytes32 h = _hashString(symbol);

        // Stablecoins
        if (
            h == _hashString("USDC") || h == _hashString("AUSD") || h == _hashString("USDT0")
                || h == _hashString("WSRUSD") || h == _hashString("USDT") || h == _hashString("DAI")
        ) {
            return abi.encode(
                IDefaultInterestRateStrategyV2.InterestRateData({
                    optimalUsageRatio: 90_00,
                    baseVariableBorrowRate: 0,
                    variableRateSlope1: 5_00,
                    variableRateSlope2: 60_00
                })
            );
        }

        // Blue-chip volatile (ETH, BTC)
        if (
            h == _hashString("WETH") || h == _hashString("wstETH") || h == _hashString("WBTC")
                || h == _hashString("BTC")
        ) {
            return abi.encode(
                IDefaultInterestRateStrategyV2.InterestRateData({
                    optimalUsageRatio: 80_00,
                    baseVariableBorrowRate: 0,
                    variableRateSlope1: 3_50,
                    variableRateSlope2: 80_00
                })
            );
        }

        // MON derivatives — lower optimal usage, steeper slope2
        return abi.encode(
            IDefaultInterestRateStrategyV2.InterestRateData({
                optimalUsageRatio: 45_00,
                baseVariableBorrowRate: 0,
                variableRateSlope1: 7_00,
                variableRateSlope2: 300_00
            })
        );
    }
}

