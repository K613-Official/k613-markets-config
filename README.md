# K613 Markets Config — Monad Mainnet

Configuration for the **K613 lending market** — an Aave v3–compatible money market deployed on top of [K613-Protocol](lib/K613-Protocol/). This repo does not deploy the core protocol. It declares **which assets are listed**, **what price feeds are used**, **how collateral and interest behave**, and **how xK613 incentives are distributed** — all as one-shot payloads that `delegatecall` the deployed `AaveV3ConfigEngine`.

<p align="center">
  <img src="image/image.png" alt="Overview" />
</p>

For operational runbooks (deploy / freeze / role rotation), see [DEPLOYMENT.md](DEPLOYMENT.md).

---

## Supported network

| Network        | Chain ID | Status                     |
|----------------|----------|----------------------------|
| Monad Mainnet  | 143    | Primary target             |

Canonical protocol addresses (Pool, PoolConfigurator, Oracle, ACLManager, `AaveV3ConfigEngine`, EmissionManager, …) live in [`src/networks/MonadMainnet.sol`](src/networks/MonadMainnet.sol).

---

## Listed reserves (11 assets)

Initial listing is declared in a single payload, [`K613Monad_InitialListing`](src/payloads/K613Monad_InitialListing.sol). Every reserve is borrow-enabled, flashloanable, and uses the same liquidation protocol fee (10%). Debt ceiling is zero (no isolation mode on any listing).

### Stablecoins

| Asset  | LTV   | LT    | LB   | RF    | Borrow cap | Supply cap | Rate curve |
|--------|-------|-------|------|-------|------------|------------|------------|
| USDC   | 77%   | 80%   | 5%   | 25%   | 400,000    | 500,000    | Stablecoin |
| AUSD   | 77%   | 80%   | 5%   | 25%   | 400,000    | 500,000    | Stablecoin |
| USDT0  | 77%   | 80%   | 5%   | 25%   | 400,000    | 500,000    | Stablecoin |
| WSRUSD | 77%   | 80%   | 5%   | 25%   | 200,000    | 250,000    | Stablecoin |

All four are `borrowableInIsolation = true`. Caps are in whole units of the underlying.

### Blue-chip collateral

| Asset  | LTV     | LT    | LB    | RF    | Borrow cap | Supply cap | Rate curve  |
|--------|---------|-------|-------|-------|------------|------------|-------------|
| WETH   | 80%     | 83%   | 7.5%  | 25%   | 150        | 200        | Blue-chip   |
| wstETH | 78.5%   | 81%   | 7.5%  | 25%   | 100        | 150        | Blue-chip   |
| WBTC   | 73%     | 78%   | 7.5%  | 25%   | 3          | 5          | Blue-chip   |

wstETH runs at tighter LTV/LT than WETH to price in LST/ETH basis risk.

### Monad-native & derivatives

| Asset  | LTV   | LT    | LB    | RF    | Borrow cap | Supply cap | Rate curve | Notes                              |
|--------|-------|-------|-------|-------|------------|------------|------------|------------------------------------|
| WMON   | 50%   | 60%   | 10%   | 50%   | 350,000    | 500,000    | Volatile   | Wrapped native MON                 |
| SHMON  | 40%   | 55%   | 10%   | 50%   | 350,000    | 500,000    | Volatile   | Liquid staking on MON              |
| SMON   | 35%   | 50%   | 12.5% | 50%   | 100,000    | 200,000    | Volatile   | Thin liquidity — conservative LTV  |
| GMON   | 35%   | 50%   | 12.5% | 50%   | 200,000    | 300,000    | Volatile   | Thin liquidity — conservative LTV  |

MON-derivatives (SHMON / SMON / GMON) have no direct USD Chainlink-style feed. They are priced via [`ExchangeRateAdapter`](src/adapters/ExchangeRateAdapter.sol), which composes `asset/MON × MON/USD` on the fly and returns `min(updatedAt)` of both sources. One adapter per asset; deployed once and referenced by the listing payload.

### Risk-parameter legend

- **LTV** — max loan-to-value at origination (user's borrow cannot push the ratio above this).
- **LT** — liquidation threshold; positions crossing this are open to liquidation.
- **LB** — liquidation bonus kept by the liquidator (in addition to principal).
- **RF** — reserve factor, share of borrow interest routed to the treasury.
- **Caps** — hard ceilings on total outstanding supply / borrow.

Invariant enforced across every listing: `LTV < LT` and `LT × (1 + LB) ≤ 100%` (no insolvent liquidation path).

### Health factor

`LT` per asset feeds into the portfolio-level **Health Factor (HF)** — the single number that decides whether a position can be liquidated:

```
HF = Σ (collateral_i × price_i × LT_i)  /  Σ (debt_j × price_j)
```

- `HF > 1` — position is healthy.
- `HF = 1` — at the liquidation line.
- `HF < 1` — any keeper can call `liquidationCall` and seize up to 50% (or 100% in close-factor-max regime) of the debt, paying out collateral plus the per-asset `LB`.

Raising a reserve's **supply cap** or **LTV** increases user borrowing power; raising **LT** lets existing positions sag further before liquidation. Because HF is a weighted average, adding a low-LT collateral to a position drags the whole HF down, not just the new asset's slice. eMode (below) rewrites the `LT_i` used in the numerator to the category's LT for every in-category asset — which is why `EMODE_ETH` / `EMODE_STABLE` at `LT = 95%` lets users lever up much higher than the per-asset `LT = 80 – 83%` would allow.

Live HF for any address is dumped by [`UserPosition.s.sol`](script/monitoring/UserPosition.s.sol).

---

## Interest rate curves

Three `DefaultReserveInterestRateStrategy` profiles, keyed on the asset's volatility and liquidity depth.

| Profile       | Optimal U | Base  | Slope₁ | Slope₂ | Assets                           |
|---------------|-----------|-------|--------|--------|----------------------------------|
| Stablecoin    | 90%       | 1%    | 4%     | 75%    | USDC, AUSD, USDT0, WSRUSD        |
| Blue-chip     | 80%       | 1%    | 3.5%   | 80%    | WETH, wstETH, WBTC               |
| Volatile      | 65%       | 5%    | 7%     | 100%   | WMON, SHMON, SMON, GMON          |

Below the optimal utilization the borrow APR rises linearly along `slope₁`; past it the second slope takes over to defend available liquidity. Utilization `U = totalBorrow / totalSupply`.

---

## eMode categories

Declared in [`K613Monad_ConfigureEModes`](src/payloads/K613Monad_ConfigureEModes.sol). When a user opts into a category, their positions within the category use the **category's** LTV/LT/LB — which are substantially looser than the per-asset defaults — and become capital-efficient for the target trade (leveraged ETH, stablecoin looping). Positions outside the category are rejected while opted in.

| ID | Category          | LTV   | LT    | LB   | Members                              |
|----|-------------------|-------|-------|------|--------------------------------------|
| 1  | ETH correlated    | 93%   | 95%   | 1%   | WETH, wstETH                         |
| 2  | Stablecoins       | 93%   | 95%   | 1%   | USDC, AUSD, USDT0, WSRUSD            |

Both categories enable the asset as both collateral and borrowable within the category.

---

## xK613 incentives — economics

Supply and borrow emissions are distributed through Aave's `RewardsController` /  `EmissionManager`. Per-second emission rates are derived from on-chain weights stored in [`IncentivesConfig`](src/incentives/IncentivesConfig.sol).

### Yearly budget

| Period  | Total xK613        | Source constant       |
|---------|--------------------|-----------------------|
| Year 1  | 25,000,000         | `YEAR1_TOTAL`         |
| Year 2  | 10,000,000         | `YEAR2_TOTAL`         |
| Year 3  |  5,000,000         | `YEAR3_TOTAL`         |
| **Total** | **40,000,000**   |                       |

For each asset and each side (supply / borrow), the per-second rate is

```
emissionPerSecond = (yearlyTotal × bps) / 10_000 / 365 days
```

truncated to `uint88` (fits `25M × 1e18 / 365d` with room to spare).

### Supply / borrow split

Global split is **65% supply / 35% borrow** across the 11 assets. Supply side is heavier because passive liquidity is what bootstraps a new market; borrowers are additionally compensated by the organic borrow APR, so they need less direct subsidy.

### Per-asset weights (bps of 10,000)

| Asset  | Supply bps | Borrow bps | Total bps | Share of budget |
|--------|-----------:|-----------:|----------:|----------------:|
| USDC   | 1400       | 700        | 2100      | 21.0%           |
| AUSD   | 1300       | 600        | 1900      | 19.0%           |
| WETH   | 1000       | 500        | 1500      | 15.0%           |
| wstETH |  850       | 400        | 1250      | 12.5%           |
| WBTC   |  650       | 500        | 1150      | 11.5%           |
| WSRUSD |  500       | 300        |  800      |  8.0%           |
| USDT0  |  450       | 300        |  750      |  7.5%           |
| WMON   |  150       |  50        |  200      |  2.0%           |
| SHMON  |  100       |  50        |  150      |  1.5%           |
| SMON   |   50       |  50        |  100      |  1.0%           |
| GMON   |   50       |  50        |  100      |  1.0%           |
| **Σ**  | **6500**   | **3500**   | **10000** | **100%**        |

Weights are canonical in [`SetIncentivesWeights.s.sol`](script/incentives/SetIncentivesWeights.s.sol) and written atomically via `IncentivesConfig.setWeights`. Retuning = edit the constants, re-run the script, re-run `ConfigureSupplyIncentives` to push the new per-second rates.

### Constraints enforced on-chain

- `Σ (supplyBps + borrowBps) = 10,000`.
- No duplicate `asset` in a single `setWeights` batch.
- Only `admin` (initially the deployer, rotate to multisig post-launch) can call `setWeights` or `setAdmin`.
- Zero `asset` address is rejected.

### Reward oracle (APR display only)

xK613 has no market price at launch. [`StaticRewardPriceFeed`](src/incentives/StaticRewardPriceFeed.sol) is a fixed-price `AggregatorInterface` used by the UI to render an APR estimate. It does **not** affect distribution: rewards are paid in whole xK613 per second regardless of the oracle value. When xK613 lists on a market, swap this for a live feed via `EmissionManager.setRewardOracle`.

---

## Architecture

```
src/
├── networks/
│   ├── NetworkConfig.sol              # Shared Addresses struct + resolvers
│   └── MonadMainnet.sol               # Canonical deployed addresses for chain 10143
├── adapters/
│   └── ExchangeRateAdapter.sol        # asset/MON × MON/USD → USD aggregator
├── incentives/
│   ├── IncentivesConfig.sol           # On-chain (supplyBps, borrowBps) weights, yearly budgets
│   └── StaticRewardPriceFeed.sol      # Fixed-price aggregator for reward token (APR display)
└── payloads/
    ├── K613PayloadMonad.sol           # Abstract base wired to MonadMainnet.CONFIG_ENGINE
    ├── K613Monad_InitialListing.sol   # One-shot payload listing the 11 reserves
    └── K613Monad_ConfigureEModes.sol  # Blue-chip eMode categories

script/
├── deploy/            DeployAdapters.s.sol                 # SHMON / SMON / GMON oracle adapters
├── operations/        ExecutePayload.s.sol                 # Temp-grants POOL_ADMIN, execute()s, revokes
│                      AdminOps.s.sol                       # One-call PoolConfigurator tweaks
│                      ExecuteEmergencyPayload.s.sol        # setReserveFreeze / setReservePause
├── incentives/        SetIncentivesWeights.s.sol           # Writes the 11-asset 65/35 split
│                      ConfigureSupplyIncentives.s.sol      # Registers aToken + vDebtToken emissions
├── monitoring/        ReserveStatus / HealthCheck / …      # Read-only dashboards
└── admin/             GrantRoles.s.sol                     # Multisig role migration (grant / revoke)
```

### Payload lifecycle

Each payload is a stateless, execute-once contract inheriting `AaveV3Payload`. Its `execute()` `delegatecall`s the deployed `AaveV3ConfigEngine`, which applies every declared change — listings, oracles, collateral parameters, rate strategies, caps, eMode categories — in one transaction. No config contract needs redeploying between payloads, and the engine instance is reused forever.

To apply changes, the caller temporarily grants `POOL_ADMIN` on the Monad `ACLManager` to the deployed payload, calls `execute()`, and revokes — all handled by [`ExecutePayload.s.sol`](script/operations/ExecutePayload.s.sol).

---

## Deployment

Full runbook with simulate / broadcast / verify commands per step: **[DEPLOYMENT.md](DEPLOYMENT.md)**.

High-level order:

1. Deploy `ExchangeRateAdapter` for SHMON / SMON / GMON.
2. Execute `K613Monad_InitialListing` payload.
3. Execute `K613Monad_ConfigureEModes` payload.
4. Deploy `IncentivesConfig`, run `SetIncentivesWeights` (65/35 split).
5. Run `ConfigureSupplyIncentives` (registers emissions on every aToken + variableDebtToken).
6. Grant roles to multisigs, revoke deployer.
7. Rotate `DEFAULT_ADMIN_ROLE` to the main multisig.

---

## Tests

```bash
forge test -vvv
```

Coverage includes:

- **Listing invariants** — `LT × (1 + LB) ≤ 100%`, `LTV < LT`, optimal usage bounded, borrow cap ≤ supply cap, uniform liquidation fee, no duplicate eMode categories.
- **`ExchangeRateAdapter` adversarial** — int256 overflow, `int256.min` guard, extreme decimals (0, 18, 38, 255), mid-flight sign flips.
- **`IncentivesConfig` adversarial** — admin escalation, duplicate assets, zero-sum rejection, `uint88` emission truncation, atomic replacement.

---

## Commands

| Command            | Description        |
|--------------------|--------------------|
| `forge build`      | Compile contracts  |
| `forge test`       | Run tests          |
| `forge fmt`        | Format Solidity    |
| `forge snapshot`   | Gas snapshots      |

## License

MIT
