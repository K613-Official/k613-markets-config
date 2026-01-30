// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "lib/forge-std/src/Script.sol";

import {IPoolConfigurator} from "lib/L2-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {IPoolAddressesProvider} from "lib/L2-Protocol/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {RiskConfig} from "../src/config/RiskConfig.sol";
import {NetworkConfig} from "../src/config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";

/// @title ConfigureCollateral
/// @notice Configure collateral parameters (LTV, LT, LB) and enable borrowing
/// @dev Aave v3 compatible script (configureReserveAsCollateral ONLY)
contract ConfigureCollateral is Script {
    TokensConfig.Network internal constant NETWORK = TokensConfig.Network.ArbitrumSepolia;

    function run() external {
        address deployer;

        // --- broadcast setup ---
        try vm.envUint("PRIVATE_KEY") returns (uint256 pk) {
            deployer = vm.addr(pk);
            vm.startBroadcast(pk);
        } catch {
            vm.startBroadcast();
            address[] memory wallets = vm.getWallets();
            deployer = wallets.length > 0 ? wallets[0] : tx.origin;
        }

        console.log("Deployer:", deployer);
        console.log("Configuring collateral parameters via Aave v3 API...");

        // --- load config ---
        NetworkConfig.Addresses memory addrs = _getAddresses();
        address provider = addrs.poolAddressesProvider;
        require(provider != address(0), "POOL_ADDRESSES_PROVIDER=0");
        _requireHasCode(provider, "POOL_ADDRESSES_PROVIDER");

        address pool = IPoolAddressesProvider(provider).getPool();
        address configuratorFromProvider = IPoolAddressesProvider(provider).getPoolConfigurator();
        address configuratorAddress = NetworkConfig.getPoolConfigurator(addrs);

        require(pool != address(0), "POOL=0");
        require(configuratorFromProvider != address(0), "POOL_CONFIGURATOR=0");
        require(addrs.pool == address(0) || addrs.pool == pool, "POOL_MISMATCH");
        require(configuratorAddress == configuratorFromProvider, "CONFIGURATOR_MISMATCH");

        _requireHasCode(pool, "POOL");
        _requireHasCode(configuratorAddress, "POOL_CONFIGURATOR");

        console.log("PoolAddressesProvider:", provider);
        console.log("Pool:", pool);
        console.log("PoolConfigurator:", configuratorAddress);

        IPoolConfigurator configurator = IPoolConfigurator(configuratorAddress);

        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(NETWORK);
        RiskConfig.RiskParams[] memory risks = RiskConfig.getRiskParams(NETWORK);

        require(tokens.length == risks.length, "length mismatch");

        uint256 success;
        uint256 failed;

        for (uint256 i = 0; i < tokens.length; i++) {
            RiskConfig.RiskParams memory r = risks[i];

            console.log("--------------------------------------------------");
            console.log("Asset:", r.asset);
            console.log("LTV:", r.ltv);
            console.log("LT :", r.liquidationThreshold);
            console.log("LB :", r.liquidationBonus);

            try configurator.configureReserveAsCollateral(r.asset, r.ltv, r.liquidationThreshold, r.liquidationBonus) {
                configurator.setReserveBorrowing(r.asset, true);
                console.log(" collateral configured & borrowing enabled");
                success++;
            } catch (bytes memory reason) {
                console.log("FAILED (likely missing ACL permissions)");
                console.logBytes(reason);
                failed++;
            }
        }

        console.log("--------------------------------------------------");
        console.log("SUCCESS:", success);
        console.log("FAILED :", failed);
        console.log("ConfigureCollateral finished");

        vm.stopBroadcast();
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
        require(target.code.length > 0, string.concat(label, " has no code"));
    }
}
