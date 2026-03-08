# Markets Config

Configuration and deployment scripts for lending markets on top of an **Aave v3–compatible protocol** (L2-Protocol). This repo does not deploy the core protocol—it configures **which assets are listed**, **oracle price feeds**, **collateral parameters** (LTV, liquidation threshold, bonus), and **risk parameters** (borrow/supply caps, reserve factor) for an already-deployed pool.

![Overview](image/image.png)

## What This Repo Does

- **Token config** — Asset addresses and Chainlink (or other) price feeds per network.
- **Risk config** — LTV, liquidation threshold, liquidation bonus, reserve factor, borrow/supply caps by asset type (WETH, BTC, stablecoins, etc.).
- **Network config** — Protocol addresses (Pool, PoolConfigurator, Oracle, Treasury, aToken/VariableDebt implementations, interest rate strategy) per chain.
- **Payloads** — Stateless, execute-once contracts (Aave-style governance payloads) that apply config to the protocol.
- **Scripts** — Forge scripts to run payloads or configure step-by-step (oracles → init reserves → collateral → risk).

## Supported Networks

| Network           | Status        |
|------------------|---------------|
| Arbitrum Sepolia | Configured    |
| Monad Mainnet    | Placeholders  |

## Project Structure

```
src/
├── config/           # Static config (tokens, risk, oracles, network addresses)
│   ├── TokensConfig.sol
│   ├── RiskConfig.sol
│   ├── OraclesConfig.sol
│   └── networks/     # ArbitrumSepolia.sol, MonadMainnet.sol, NetworkConfig.sol
└── payloads/        # Governance-style payloads (execute once)
    ├── OracleUpdatePayload.sol
    ├── ListingPayload.sol       # initReserves
    ├── CollateralConfigPayload.sol
    └── RiskUpdatePayload.sol

script/              # Forge deploy/run scripts
├── ConfigureOracles.s.sol
├── InitReserves.s.sol
├── ConfigureCollateral.s.sol
├── ConfigureRisk.s.sol
└── FullMarketSetup.s.sol
```

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Deployed L2-Protocol (Aave fork) with your Pool, PoolConfigurator, Oracle, etc.
- `.env` with at least:
  - `ARBITRUM_SEPOLIA_RPC_URL` (or your chain RPC)
  - `PRIVATE_KEY` — deployer key (hex, with or without `0x`)

Optional: `ETHERSCAN_API_KEY` for contract verification.

## Deployment Order

Apply in this order (Aave v3 semantics):

1. **ConfigureOracles** — Set price feed sources on the protocol oracle.
2. **InitReserves** — Initialize reserves (list assets) in the pool.
3. **ConfigureCollateral** — Set LTV, liquidation threshold, liquidation bonus; enable borrowing.
4. **ConfigureRisk** — Set borrow/supply caps and reserve factors.

### Step-by-step (recommended)

```bash
source .env   # or use foundry's dotenv in foundry.toml

# 1. Oracles
forge script script/ConfigureOracles.s.sol \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --slow -vv

# 2. Init reserves (list assets)
forge script script/InitReserves.s.sol \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --slow -vv

# 3. Collateral (LTV, LT, LB, borrowing)
forge script script/ConfigureCollateral.s.sol \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --slow -vv

# 4. Risk (caps, reserve factor)
forge script script/ConfigureRisk.s.sol \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --slow -vv
```

Omit `--verify` if you are not verifying contracts on a block explorer.

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
