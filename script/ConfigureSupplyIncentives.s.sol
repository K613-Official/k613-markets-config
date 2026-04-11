// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "lib/K613-Protocol/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {IPool} from "lib/K613-Protocol/src/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "lib/K613-Protocol/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {IEmissionManager} from "lib/K613-Protocol/src/contracts/rewards/interfaces/IEmissionManager.sol";
import {ITransferStrategyBase} from "lib/K613-Protocol/src/contracts/rewards/interfaces/ITransferStrategyBase.sol";
import {PullRewardsTransferStrategy} from "lib/K613-Protocol/src/contracts/rewards/transfer-strategies/PullRewardsTransferStrategy.sol";
import {RewardsDataTypes} from "lib/K613-Protocol/src/contracts/rewards/libraries/RewardsDataTypes.sol";
import {AggregatorInterface} from "lib/K613-Protocol/src/contracts/dependencies/chainlink/AggregatorInterface.sol";
import {IRewardsDistributor} from "lib/K613-Protocol/src/contracts/rewards/interfaces/IRewardsDistributor.sol";
import {StaticRewardPriceFeed} from "../src/incentives/StaticRewardPriceFeed.sol";
import {IncentivesConfig} from "../src/incentives/IncentivesConfig.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {NetworkConfig} from "../src/config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";

interface IOwnable {
    function owner() external view returns (address);
}

/// @title ConfigureSupplyIncentives
/// @notice Configures xK613 supply incentives for all Monad mainnet markets in one tx
/// @dev Env vars:
///   INCENTIVES_REWARD_TOKEN     — xK613 token address
///   INCENTIVES_REWARDS_VAULT    — vault holding xK613
///   INCENTIVES_DISTRIBUTION_END — unix timestamp (end of Year 1)
///   INCENTIVES_REWARD_ORACLE_ANSWER  — xK613 price in USD (default: 800000 = $0.008, 8 decimals)
///   INCENTIVES_REWARD_ORACLE_DECIMALS — oracle decimals (default: 8)
contract ConfigureSupplyIncentives is Script {
    error DistributionEndOverflow();
    error DistributionEndInPast();
    error InvalidOracleAnswer();
    error ZeroIncentivesController();
    error ZeroPool();
    error ZeroEmissionManager();
    error SetEmissionAdminFirst();
    error NotEmissionAdmin();
    error ReserveNotListed(string symbol);

    TokensConfig.Network internal constant NETWORK = TokensConfig.Network.MonadMainnet;

    function run() external {
        address deployer;
        try vm.envUint("PRIVATE_KEY") returns (uint256 pk) {
            deployer = vm.addr(pk);
            vm.startBroadcast(pk);
        } catch {
            vm.startBroadcast();
            address[] memory wallets = vm.getWallets();
            deployer = wallets.length > 0 ? wallets[0] : tx.origin;
        }

        address rewardToken = vm.envAddress("INCENTIVES_REWARD_TOKEN");
        address rewardsVault = vm.envAddress("INCENTIVES_REWARDS_VAULT");
        uint256 distributionEndU = vm.envUint("INCENTIVES_DISTRIBUTION_END");
        if (distributionEndU > uint256(type(uint32).max)) revert DistributionEndOverflow();
        uint32 distributionEnd = uint32(distributionEndU);
        if (distributionEnd <= block.timestamp) revert DistributionEndInPast();

        int256 oracleAnswer = vm.envOr("INCENTIVES_REWARD_ORACLE_ANSWER", int256(800_000));
        if (oracleAnswer <= 0) revert InvalidOracleAnswer();
        uint8 oracleDecimals = uint8(vm.envOr("INCENTIVES_REWARD_ORACLE_DECIMALS", uint256(8)));

        NetworkConfig.Addresses memory addrs = _getAddresses();
        if (addrs.incentivesController == address(0)) revert ZeroIncentivesController();

        address poolAddr = addrs.pool;
        if (poolAddr == address(0)) {
            poolAddr = IPoolAddressesProvider(addrs.poolAddressesProvider).getPool();
        }
        if (poolAddr == address(0)) revert ZeroPool();
        IPool pool = IPool(poolAddr);

        address emissionManagerAddr = IRewardsDistributor(addrs.incentivesController).EMISSION_MANAGER();
        if (emissionManagerAddr == address(0)) revert ZeroEmissionManager();
        IEmissionManager emissionManager = IEmissionManager(emissionManagerAddr);

        // Set emission admin if needed
        address emissionAdmin = emissionManager.getEmissionAdmin(rewardToken);
        if (emissionAdmin == address(0)) {
            address emOwner = IOwnable(emissionManagerAddr).owner();
            if (emOwner != deployer) revert SetEmissionAdminFirst();
            emissionManager.setEmissionAdmin(rewardToken, deployer);
        }
        if (emissionManager.getEmissionAdmin(rewardToken) != deployer) revert NotEmissionAdmin();

        // Deploy shared price feed and transfer strategy
        StaticRewardPriceFeed priceFeed = new StaticRewardPriceFeed(
            oracleAnswer,
            oracleDecimals,
            "xK613 / USD"
        );
        PullRewardsTransferStrategy strategy = new PullRewardsTransferStrategy(
            addrs.incentivesController,
            deployer,
            rewardsVault
        );

        // Build configs for all markets
        IncentivesConfig.EmissionConfig[] memory emissions =
            IncentivesConfig.getEmissionConfigs(IncentivesConfig.YEAR1_TOTAL);

        RewardsDataTypes.RewardsConfigInput[] memory cfg =
            new RewardsDataTypes.RewardsConfigInput[](emissions.length);

        for (uint256 i = 0; i < emissions.length; i++) {
            address aToken = pool.getReserveData(emissions[i].asset).aTokenAddress;
            if (aToken == address(0)) revert ReserveNotListed(emissions[i].symbol);

            cfg[i] = RewardsDataTypes.RewardsConfigInput({
                emissionPerSecond: emissions[i].emissionPerSecond,
                totalSupply: 0,
                distributionEnd: distributionEnd,
                asset: aToken,
                reward: rewardToken,
                transferStrategy: ITransferStrategyBase(strategy),
                rewardOracle: AggregatorInterface(address(priceFeed))
            });

            console.log(emissions[i].symbol);
            console.log("  aToken:", aToken);
            console.log("  weight:", emissions[i].weight, "bps");
            console.log("  emission/sec:", uint256(emissions[i].emissionPerSecond));
        }

        // Configure all markets in one call
        emissionManager.configureAssets(cfg);

        console.log("\n=== Deployment Summary ===");
        console.log("Reward token (xK613):", rewardToken);
        console.log("Rewards vault:", rewardsVault);
        console.log("PriceFeed:", address(priceFeed));
        console.log("TransferStrategy:", address(strategy));
        console.log("Markets configured:", emissions.length);
        console.log("Distribution end:", uint256(distributionEnd));

        uint256 allowance = IERC20(rewardToken).allowance(rewardsVault, address(strategy));
        if (allowance < type(uint256).max / 2) {
            console.log("\nACTION REQUIRED: from REWARDS_VAULT call:");
            console.log("  IERC20(xK613).approve(strategy, type(uint256).max)");
        }

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
}
