# Markets Config

Configuration and deployment scripts for lending markets on top of an **Aave v3–compatible protocol** (e.g. K613-Protocol in `lib/`). This repo does not deploy the core protocol—it configures **which assets are listed**, **oracle price feeds**, **collateral parameters** (LTV, liquidation threshold, bonus), and **risk parameters** (borrow/supply caps, reserve factor) for an already-deployed pool.

<p align="center">
  <img src="image/image.png" alt="Overview" />
</p>

## What This Repo Does

- **Network config** — Protocol addresses (Pool, PoolConfigurator, Oracle, Treasury, aToken/VariableDebt implementations, default interest rate strategy, `AaveV3ConfigEngine`) per chain.
- **Tokens registry** — Off-chain catalog of listed assets and price feeds (used by adapter deploys and external tooling); not a source of truth for payloads.
- **Payloads** — Stateless, execute-once contracts inheriting `AaveV3Payload`. Each payload declares its intent as `Listing[]` / `CapsUpdate[]` / `CollateralUpdate[]` / etc., and `delegatecall`s the deployed `AaveV3ConfigEngine` to apply it in one transaction (listing, oracles, collateral, caps, IR strategy — all at once).
- **Scripts** — Forge scripts to deploy and `execute()` payloads.
- **Incentives** — `IncentivesConfig` stores per-asset `(supplyBps, borrowBps)` weights keyed by underlying asset address; the supply/borrow ratio is set **per asset**, not globally, and the sum across all assets must equal `10_000` bps. `ConfigureSupplyIncentives` registers xK613 emissions on **aToken** and **variableDebtToken** for every configured asset in one transaction.
- **Admin ops** — [`AdminOps.s.sol`](script/AdminOps.s.sol) for single-call `PoolConfigurator` tweaks (caps, reserve factor, liq protocol fee) without deploying a payload; [`ExecuteEmergencyPayload.s.sol`](script/ExecuteEmergencyPayload.s.sol) for freeze/pause a reserve.

## Supported Networks

| Network        | Status                             |
|----------------|------------------------------------|
| Monad Mainnet  | Primary target (scripts/payloads)  |

## Project Structure

```
src/
├── config/
│   ├── TokensConfig.sol          # `Token` struct used by the off-chain registry
│   ├── TokensRegistry.sol        # Admin-managed catalog seeded with Monad reserves
│   ├── OraclesConfig.sol         # Helpers for pool-oracle writes from a token list
│   ├── interface/ITokensRegistry.sol
│   └── networks/
│       ├── NetworkConfig.sol     # Shared `Addresses` struct + resolvers
│       └── MonadMainnet.sol      # Canonical deployed addresses, incl. `CONFIG_ENGINE`
├── incentives/                   # IncentivesConfig (weights, yearly totals); StaticRewardPriceFeed
├── adapters/
│   └── ExchangeRateAdapter.sol   # token/MON × MON/USD → USD aggregator for the pool oracle
└── payloads/
    ├── K613PayloadMonad.sol             # Abstract base wired to MonadMainnet.CONFIG_ENGINE
    ├── K613Monad_InitialListing.sol     # One-shot payload listing the 11 Monad reserves
    ├── K613Monad_ConfigureEModes.sol    # Blue-chip eMode categories (ETH-correlated, stables)
    └── emergency/
        ├── K613Monad_EmergencyFreeze.sol  # setReserveFreeze(asset, flag)
        └── K613Monad_EmergencyPause.sol   # setReservePause(asset, flag)

script/
├── DeployAdapters.s.sol             # ExchangeRateAdapter for SHMON / SMON / GMON
├── ExecuteListingPayload.s.sol      # Deploys and executes a K613PayloadMonad subclass
├── ConfigureSupplyIncentives.s.sol
├── AdminOps.s.sol                   # Single-call PoolConfigurator tweaks (caps / RF / fees)
└── ExecuteEmergencyPayload.s.sol    # Freeze / unfreeze / pause / unpause a single reserve
```

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Deployed L2-Protocol (Aave fork) with your Pool, PoolConfigurator, Oracle, etc.
- `.env` with at least:
  - RPC URL for your chain (e.g. `MONAD_RPC_URL`)
  - `PRIVATE_KEY` — deployer key (hex, with or without `0x`)

Optional: `ETHERSCAN_API_KEY` for contract verification.

## Deployment Order

All configuration goes through one transaction per payload: the payload is deployed, then its `execute()` is called, which `delegatecall`s the already-deployed [`AaveV3ConfigEngine`](src/config/networks/MonadMainnet.sol) to write oracles, initialize reserves, set LTV/LT/LB/RF, and set caps — in one shot.

Caller must hold `POOL_ADMIN` / `RISK_ADMIN` on the Monad `ACLManager` (address in [`MonadMainnet.sol`](src/config/networks/MonadMainnet.sol)).

**Oracle adapters (SHMON / SMON / GMON)** — MON-derivative assets need a combined `asset/MON × MON/USD → USD` aggregator. Run [`DeployAdapters`](script/DeployAdapters.s.sol) **once** before authoring any payload that lists those assets, and paste the printed addresses into the `priceFeed` slot of the relevant `Listing` struct (see [`K613Monad_InitialListing.sol`](src/payloads/K613Monad_InitialListing.sol) for the layout).

### Running a listing payload (Monad)

Scripts target **Monad Mainnet** by default. Set `MONAD_RPC_URL` in `.env`.

```bash
source .env   # loads MONAD_RPC_URL, PRIVATE_KEY, etc.

# 0. ExchangeRateAdapter for SHMON, SMON, GMON — only if the payload lists them
forge script script/DeployAdapters.s.sol \
  --rpc-url $MONAD_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --slow -vv

# 1. Deploy + execute the initial listing payload (oracles, reserves, collateral, caps)
forge script script/ExecuteListingPayload.s.sol \
  --rpc-url $MONAD_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --slow -vv

# 2. Incentives (optional)
forge script script/ConfigureSupplyIncentives.s.sol \
  --rpc-url $MONAD_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --slow -vv
```

### Adding a new asset

Create a short payload (~30 lines) inheriting [`K613PayloadMonad`](src/payloads/K613PayloadMonad.sol) and overriding `newListings()` with a single `IAaveV3ConfigEngine.Listing` literal — asset, price feed, rate curve, LTV/LT/LB/RF, caps. Point [`ExecuteListingPayload`](script/ExecuteListingPayload.s.sol) at the new payload (or duplicate the script), deploy, `execute()`. No config contract needs redeploying, and the engine instance is reused forever.

For maintenance tasks (cap bumps, rate curve tweaks, collateral changes), override `capsUpdates()` / `collateralsUpdates()` / `rateStrategiesUpdates()` / `borrowsUpdates()` / `priceFeedsUpdates()` instead of `newListings()`.

### Supply and borrow incentives (reward token, Monad)

Prerequisites: steps 1–4 completed on **Monad** so every reserve has aToken and variableDebtToken. The **`INCENTIVES_REWARDS_VAULT`** must hold enough reward tokens and **`approve`** the deployed `PullRewardsTransferStrategy` (the script prints its address). The caller must be **`EmissionManager` emission admin** for the reward token (owner can `setEmissionAdmin(rewardToken, deployer)` once).

Yearly budget constants live in [`IncentivesConfig.sol`](src/incentives/IncentivesConfig.sol) (`YEAR1_TOTAL` / `YEAR2_TOTAL` / `YEAR3_TOTAL`). Weights are stored **on-chain**, keyed by asset address, and updated via `setWeights(AssetWeight[])` — no redeploy needed to retune.

```bash
export INCENTIVES_REWARD_TOKEN=              # ERC20 (e.g. xK613)
export INCENTIVES_REWARDS_VAULT=             # holds reward tokens; approve strategy after run
export INCENTIVES_DISTRIBUTION_END=          # unix timestamp (uint32), must be in the future
# optional:
# export INCENTIVES_REWARD_ORACLE_ANSWER=    # default 800000 (8 decimals → $0.008)
# export INCENTIVES_REWARD_ORACLE_DECIMALS=  # default 8

forge script script/ConfigureSupplyIncentives.s.sol \
  --rpc-url $MONAD_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --slow -vv
```

Omit `--verify` if you are not verifying on a block explorer.

## Admin operations

All admin actions below require the caller to already hold the relevant role (`POOL_ADMIN`, `RISK_ADMIN`, or `EMERGENCY_ADMIN`) on the Monad `ACLManager`. Scripts broadcast from `PRIVATE_KEY`.

### Retune a single parameter (caps / reserve factor / liq fee)

One call to `PoolConfigurator`, no payload deploy:

```bash
# supplyCap | borrowCap in whole units, factors in bps (e.g. 2500 = 25%)
export ADMIN_OP=supplyCap
export ADMIN_ASSET=0x...
export ADMIN_VALUE=300000

forge script script/AdminOps.s.sol \
  --rpc-url $MONAD_RPC_URL --private-key $PRIVATE_KEY --broadcast -vv
```

Supported `ADMIN_OP` values: `supplyCap`, `borrowCap`, `reserveFactor`, `liqProtocolFee`.

### Emergency: freeze or pause a reserve

Freeze blocks new supply/borrow/repay but keeps liquidations live. Pause blocks **everything** including liquidations — reserve it for critical incidents.

```bash
export EMERGENCY_ACTION=freeze     # freeze | unfreeze | pause | unpause
export EMERGENCY_ASSET=0x...

forge script script/ExecuteEmergencyPayload.s.sol \
  --rpc-url $MONAD_RPC_URL --private-key $PRIVATE_KEY --broadcast -vv
```

### Larger changes (multi-param, multi-asset, or new listing)

Write a short payload inheriting [`K613PayloadMonad`](src/payloads/K613PayloadMonad.sol) and override the relevant hooks (`newListings` / `capsUpdates` / `collateralsUpdates` / `rateStrategiesUpdates` / `priceFeedsUpdates` / `borrowsUpdates` / `eModeCategoriesUpdates` / `assetsEModeUpdates`), then deploy and `execute()` it via [`ExecuteListingPayload.s.sol`](script/ExecuteListingPayload.s.sol). The engine is reused forever — no redeploy needed.

[`K613Monad_ConfigureEModes.sol`](src/payloads/K613Monad_ConfigureEModes.sol) is a reference payload that creates two blue-chip eMode categories (ETH-correlated, stablecoins) and assigns the 6 relevant reserves.

### Retuning incentive weights

Weights are stored on-chain in the deployed `IncentivesConfig`. Call `setWeights(AssetWeight[])` as `admin` with an updated array — sum of all `supplyBps + borrowBps` must equal `10_000`. After updating, re-run `ConfigureSupplyIncentives` to push the new per-second rates into `EmissionManager`.

### Targeting another chain

Scripts and payloads read addresses from `MonadMainnet` in `src/config/networks/`. To target another chain, add a new library alongside `MonadMainnet.sol` and update the scripts/payloads to import it.

## Commands

| Command            | Description        |
|--------------------|--------------------|
| `forge build`      | Compile contracts  |
| `forge test`       | Run tests          |
| `forge fmt`        | Format Solidity    |
| `forge snapshot`   | Gas snapshots      |

## License

MIT
