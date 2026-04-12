# Markets Config

Configuration and deployment scripts for lending markets on top of an **Aave v3–compatible protocol** (e.g. K613-Protocol in `lib/`). This repo does not deploy the core protocol—it configures **which assets are listed**, **oracle price feeds**, **collateral parameters** (LTV, liquidation threshold, bonus), and **risk parameters** (borrow/supply caps, reserve factor) for an already-deployed pool.

<p align="center">
  <img src="image/image.png" alt="Overview" />
</p>

## What This Repo Does

- **Token config** — Asset addresses and Chainlink (or other) price feeds per network.
- **Risk config** — LTV, liquidation threshold, liquidation bonus, reserve factor, borrow/supply caps by asset type (WETH, BTC, stablecoins, etc.).
- **Network config** — Protocol addresses (Pool, PoolConfigurator, Oracle, Treasury, aToken/VariableDebt implementations, interest rate strategy) per chain.
- **Payloads** — Stateless, execute-once contracts (Aave-style governance payloads) that apply config to the protocol.
- **Scripts** — Forge scripts to run payloads or configure step-by-step (oracles → init reserves → collateral → risk → optional incentives).
- **Incentives** — `IncentivesConfig` defines per-asset reward weights and a **65% supply / 35% borrow** split of each asset’s share; `ConfigureSupplyIncentives` registers xK613 emissions on **aToken** and **variableDebtToken** for all Monad mainnet reserves in one transaction.

## Supported Networks

| Network           | Status        |
|------------------|---------------|
| Arbitrum Sepolia | Configured    |
| Monad Mainnet    | Primary target (scripts/payloads) |

## Project Structure

```
src/
├── config/           # Static config (tokens, risk, oracles, network addresses)
│   ├── TokensConfig.sol
│   ├── RiskConfig.sol
│   ├── OraclesConfig.sol
│   └── networks/     # ArbitrumSepolia.sol, MonadMainnet.sol, NetworkConfig.sol
├── incentives/       # IncentivesConfig (weights, yearly totals); StaticRewardPriceFeed for reward oracle
└── payloads/        # Governance-style payloads (execute once)
    ├── OracleUpdatePayload.sol
    ├── ListingPayload.sol       # initReserves
    ├── CollateralConfigPayload.sol
    └── RiskUpdatePayload.sol

script/              # Forge deploy/run scripts
├── DeployAdapters.s.sol          # ExchangeRateAdapter for SHMON / SMON / GMON (Monad)
├── ConfigureOracles.s.sol
├── InitReserves.s.sol
├── ConfigureCollateral.s.sol
├── ConfigureRisk.s.sol
├── ConfigureSupplyIncentives.s.sol
└── FullMarketSetup.s.sol

src/adapters/
└── ExchangeRateAdapter.sol      # Chainlink token/MON × MON/USD → USD aggregator for the pool oracle
```

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Deployed L2-Protocol (Aave fork) with your Pool, PoolConfigurator, Oracle, etc.
- `.env` with at least:
  - RPC URL for your chain (e.g. `MONAD_RPC_URL` or `ARBITRUM_SEPOLIA_RPC_URL`)
  - `PRIVATE_KEY` — deployer key (hex, with or without `0x`)

Optional: `ETHERSCAN_API_KEY` for contract verification.

## Deployment Order

Apply in this order (Aave v3 semantics). On **Monad**, use `$MONAD_RPC_URL` in `forge script` examples below.

**Oracle adapters (Monad, SHMON / SMON / GMON)** — `TokensConfig` lists Chainlink feeds per asset. For MON-derivative assets, `DeployAdapters` deploys **`ExchangeRateAdapter`**: it combines the asset/MON feed with the MON/USD feed so the pool oracle sees a single USD aggregator. Run **`DeployAdapters`** first, paste the printed addresses into `TokensConfig` for SHMON, SMON, and GMON `priceFeed` fields, then run **ConfigureOracles**.

1. **ConfigureOracles** — Set price feed sources on the protocol oracle.
2. **InitReserves** — Initialize reserves (list assets) in the pool.
3. **ConfigureCollateral** — Set LTV, liquidation threshold, liquidation bonus; enable borrowing.
4. **ConfigureRisk** — Set borrow/supply caps and reserve factors.
5. **ConfigureSupplyIncentives** (optional, **Monad Mainnet**) — Deploy `StaticRewardPriceFeed` and `PullRewardsTransferStrategy`, then call `EmissionManager.configureAssets` for **every** listed reserve: emissions on **aToken** (suppliers) and **variableDebtToken** (borrowers), with rates derived from `IncentivesConfig` (per-asset weights and 65/35 supply/borrow split).

### Step-by-step (recommended, Monad)

Scripts default to **`TokensConfig.Network.MonadMainnet`** in code (not Arbitrum). Set `MONAD_RPC_URL` in `.env`.

```bash
source .env   # loads MONAD_RPC_URL, PRIVATE_KEY, etc.

# 0. ExchangeRateAdapter for SHMON, SMON, GMON — then update TokensConfig price feeds from script output
forge script script/DeployAdapters.s.sol \
  --rpc-url $MONAD_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --slow -vv

# 1. Oracles
forge script script/ConfigureOracles.s.sol \
  --rpc-url $MONAD_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --slow -vv

# 2. Init reserves (list assets)
forge script script/InitReserves.s.sol \
  --rpc-url $MONAD_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --slow -vv

# 3. Collateral (LTV, LT, LB, borrowing)
forge script script/ConfigureCollateral.s.sol \
  --rpc-url $MONAD_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --slow -vv

# 4. Risk (caps, reserve factor)
forge script script/ConfigureRisk.s.sol \
  --rpc-url $MONAD_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --slow -vv
```

For **Arbitrum Sepolia**, change the `NETWORK` constant in each script to `ArbitrumSepolia` and use `$ARBITRUM_SEPOLIA_RPC_URL` (or your RPC env name). Adapter deployment is Monad-specific in `DeployAdapters`; Sepolia flows may skip step 0 if feeds are already direct Chainlink USD feeds in `TokensConfig`.

### Supply and borrow incentives (reward token, Monad)

Prerequisites: steps 1–4 completed on **Monad** so every reserve has aToken and variableDebtToken. The **`INCENTIVES_REWARDS_VAULT`** must hold enough reward tokens and **`approve`** the deployed `PullRewardsTransferStrategy` (the script prints its address). The caller must be **`EmissionManager` emission admin** for the reward token (owner can `setEmissionAdmin(rewardToken, deployer)` once).

Weights and yearly budget are in `src/incentives/IncentivesConfig.sol` (e.g. `YEAR1_TOTAL`); emissions are **not** configured per env — change the library and redeploy if you need different rates.

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

### Switching networks

Payloads and scripts use a `NETWORK` constant (e.g. `TokensConfig.Network.ArbitrumSepolia`). To target another chain, set the protocol addresses in `src/config/networks/` and change `NETWORK` in the relevant script/payload.

## Commands

| Command            | Description        |
|--------------------|--------------------|
| `forge build`      | Compile contracts  |
| `forge test`       | Run tests          |
| `forge fmt`        | Format Solidity    |
| `forge snapshot`   | Gas snapshots      |

## License

MIT
