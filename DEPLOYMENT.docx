# Monad Mainnet Deployment Runbook

Пошаговый гайд по деплою K613 lending market на Monad. Шаги строго последовательны — каждый следующий зависит от результата предыдущего.

## 0. Предусловия

- Deployer-ключ с ролями `DEFAULT_ADMIN_ROLE`, `POOL_ADMIN`, `RISK_ADMIN`, `EMERGENCY_ADMIN` на [ACLManager](src/networks/MonadMainnet.sol#L20) (назначаются при деплое пула K613-Protocol, до этих скриптов).
- Деплоенные мультисиги: `MAIN_MULTISIG` (Safe) и `EMERGENCY_HOT` (EOA или лёгкий Safe).
- Достаточно MON на deployer-кошельке.
- `MONAD_RPC_URL` указывает на HTTPS-эндпоинт mainnet.

**Базовые env, нужны каждому broadcast-скрипту:**

```bash
export MONAD_RPC_URL="https://..."
export PRIVATE_KEY="0x..."          # deployer
export ETHERSCAN_API_KEY="..."      # опционально, для --verify
```

### Правило: сначала симуляция, потом broadcast

Для каждого шага ниже даны **две** команды:
1. **Simulate** — та же самая команда, но **без** `--broadcast`. Forge исполняет tx в `eth_call`-режиме против живого стейта, газ не тратится, ничего не пишется. Если симуляция падает — broadcast запускать нельзя, сначала чинится причина.
2. **Broadcast** — та же команда с `--broadcast`, отправляет tx в mempool.

Для read-only скриптов (мониторинг) `--broadcast` не нужен вообще — они всегда read-only.

---

## 1. Deploy oracle adapters (только если нужны LST)

Разворачивает `ExchangeRateAdapter` для SHMON/SMON/GMON — склейка `token/MON × MON/USD`. Запускать только если у этих LST нет готовых USD-фидов.

**Скрипт:** [script/deploy/DeployAdapters.s.sol](script/deploy/DeployAdapters.s.sol)

**Env:** только базовые.

**Simulate:**

```bash
forge script script/deploy/DeployAdapters.s.sol:DeployAdapters \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  -vvvv
```

**Broadcast:**

```bash
forge script script/deploy/DeployAdapters.s.sol:DeployAdapters \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  -vvvv
```

**Результат:** 3 адреса — `shmonAdapter`, `smonAdapter`, `gmonAdapter`. Скопировать в [K613Monad_InitialListing.sol](src/payloads/K613Monad_InitialListing.sol) в `SHMON_FEED`, `SMON_FEED`, `GMON_FEED`. Пересобрать: `forge build`.

---

## 2. Initial listing (11 reserves)

Деплоит `K613Monad_InitialListing` и вызывает `execute()`. Листит все 11 ассетов через `AaveV3ConfigEngine` одной транзакцией.

**Скрипт:** [script/operations/ExecutePayload.s.sol](script/operations/ExecutePayload.s.sol)

**Env:**

```bash
export PAYLOAD="InitialListing"
```

**Simulate:**

```bash
PAYLOAD="InitialListing" \
forge script script/operations/ExecutePayload.s.sol:ExecutePayload \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  -vvvv
```

**Broadcast:**

```bash
PAYLOAD="InitialListing" \
forge script script/operations/ExecutePayload.s.sol:ExecutePayload \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  -vvvv
```

**Проверка:** запустить [ReserveStatus](#reservestatus) — должно показать 11 резервов с правильными caps/rates.

---

## 3. Configure eModes (blue-chip категории)

Деплоит `K613Monad_ConfigureEModes`: 2 eMode категории — ETH-correlated (WETH/wstETH) и Stablecoins (USDC/AUSD/USDT0/WSRUSD). **Обязательно после шага 2** — движок требует, чтобы ассеты уже были залистены.

**Скрипт:** [script/operations/ExecutePayload.s.sol](script/operations/ExecutePayload.s.sol)

**Env:**

```bash
export PAYLOAD="ConfigureEModes"
```

**Simulate:**

```bash
PAYLOAD="ConfigureEModes" \
forge script script/operations/ExecutePayload.s.sol:ExecutePayload \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  -vvvv
```

**Broadcast:**

```bash
PAYLOAD="ConfigureEModes" \
forge script script/operations/ExecutePayload.s.sol:ExecutePayload \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  -vvvv
```

---

## 4. Deploy `IncentivesConfig` + `setWeights`

Деплоит `IncentivesConfig` (хранилище весов supply/borrow в bps). Без него шаг 5 не стартует. Делается один раз; потом `setWeights` вызывается по мере необходимости от admin.

Отдельного forge-script для этого нет — деплой через `forge create`:

```bash
forge create src/incentives/IncentivesConfig.sol:IncentivesConfig \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --constructor-args "$(cast wallet address --private-key "$PRIVATE_KEY")"
```

Сохранить напечатанный адрес:

```bash
export INCENTIVES_CONFIG="0x..."
```

Затем вызвать `setWeights(...)` через `cast send`. Сумма `supplyBps + borrowBps` по всем ассетам должна равняться `10_000`.

---

## 5. Configure supply/borrow incentives (xK613 emissions)

Для каждого aToken и variableDebtToken настраивает `emissionPerSecond` через `EmissionManager.configureAssets`. Деплоит `StaticRewardPriceFeed` и `PullRewardsTransferStrategy`.

**Скрипт:** [script/incentives/ConfigureSupplyIncentives.s.sol](script/incentives/ConfigureSupplyIncentives.s.sol)

**Env:**

```bash
export INCENTIVES_CONFIG="0x..."            # с шага 4
export INCENTIVES_REWARD_TOKEN="0x..."      # xK613
export INCENTIVES_REWARDS_VAULT="0x..."     # кошелёк/контракт с xK613
export INCENTIVES_DISTRIBUTION_END="..."    # unix timestamp (uint32), конец Year 1
# опционально:
# export INCENTIVES_REWARD_ORACLE_ANSWER="800000"
# export INCENTIVES_REWARD_ORACLE_DECIMALS="8"
```

**Simulate:**

```bash
forge script script/incentives/ConfigureSupplyIncentives.s.sol:ConfigureSupplyIncentives \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  -vvvv
```

**Broadcast:**

```bash
forge script script/incentives/ConfigureSupplyIncentives.s.sol:ConfigureSupplyIncentives \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  -vvvv
```

**Пост-экшен (критично):** из `INCENTIVES_REWARDS_VAULT` нужно approve напечатанный в логах `PullRewardsTransferStrategy` на `type(uint256).max` по xK613 — иначе claim'ы юзеров будут падать.

```bash
cast send "$INCENTIVES_REWARD_TOKEN" \
  "approve(address,uint256)" "<STRATEGY_ADDRESS>" 115792089237316195423570985008687907853269984665640564039457584007913129639935 \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "<VAULT_OWNER_KEY>"
```

**Проверка:** [IncentivesStatus](#incentivesstatus) — должен показать emissionPerSecond на всех aToken/vDebtToken.

---

## 6. Grant roles to multisigs (`grantOnly`)

Выдаёт роли мультисигам, **оставляя** deployer'у — для rollback. Также передаёт `owner()` у `PoolAddressesProvider` и `EmissionManager` на `MAIN_MULTISIG`.

**Скрипт:** [script/admin/GrantRoles.s.sol](script/admin/GrantRoles.s.sol)

**Env:**

```bash
export GRANT_MODE="grantOnly"
export MAIN_MULTISIG="0x..."    # Safe — получит POOL_ADMIN, RISK_ADMIN, ownership
export EMERGENCY_HOT="0x..."    # EOA/Safe — получит EMERGENCY_ADMIN
```

**Simulate:**

```bash
GRANT_MODE="grantOnly" \
MAIN_MULTISIG="0x..." \
EMERGENCY_HOT="0x..." \
forge script script/admin/GrantRoles.s.sol:GrantRoles \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  -vvvv
```

**Broadcast:**

```bash
GRANT_MODE="grantOnly" \
MAIN_MULTISIG="0x..." \
EMERGENCY_HOT="0x..." \
forge script script/admin/GrantRoles.s.sol:GrantRoles \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  -vvvv
```

**Тест:** из `MAIN_MULTISIG` провести любую тестовую операцию (например `AdminOps` с `supplyCap` на маленький твик). Если мультисиг успешно исполняет — переходить к шагу 7. Если нет — у deployer'а всё ещё есть роли для отката.

---

## 7. Revoke deployer roles (`grantRevoke`)

Тот же скрипт, режим `grantRevoke`. Отзывает `POOL_ADMIN / RISK_ADMIN / EMERGENCY_ADMIN` у deployer. `DEFAULT_ADMIN_ROLE` **не** трогает.

**Env:**

```bash
export GRANT_MODE="grantRevoke"
export MAIN_MULTISIG="0x..."
export EMERGENCY_HOT="0x..."
```

**Simulate:**

```bash
GRANT_MODE="grantRevoke" \
MAIN_MULTISIG="0x..." \
EMERGENCY_HOT="0x..." \
forge script script/admin/GrantRoles.s.sol:GrantRoles \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  -vvvv
```

**Broadcast:**

```bash
GRANT_MODE="grantRevoke" \
MAIN_MULTISIG="0x..." \
EMERGENCY_HOT="0x..." \
forge script script/admin/GrantRoles.s.sol:GrantRoles \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  -vvvv
```

**Проверка:** [HealthCheck](#healthcheck) с `CHECK_DEPLOYER=<deployer>` — все `is*Admin` должны быть `false`, `hasDefaultAdminRole` пока `true`.

---

## 8. Rotate `DEFAULT_ADMIN_ROLE` (вручную, точка невозврата)

**Только после** того как подтверждено: мультисиг успешно вызывает `grantRole` через тестовую tx, все мониторинги зелёные.

Две транзакции через `cast`:

```bash
# 1) grant DEFAULT_ADMIN_ROLE мультисигу
cast send 0x115840CF79eb27713E0Bd3B66076651f8C081B0B \
  "grantRole(bytes32,address)" \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
  "$MAIN_MULTISIG" \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY"
```

```bash
# 2) renounce у deployer
cast send 0x115840CF79eb27713E0Bd3B66076651f8C081B0B \
  "renounceRole(bytes32,address)" \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
  "$(cast wallet address --private-key "$PRIVATE_KEY")" \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY"
```

(`0x1158...081B` — адрес `ACL_MANAGER` из [MonadMainnet.sol](src/networks/MonadMainnet.sol).)

После `renounceRole` deployer-ключ больше ничего не может на пуле.

---

## Daily operations (после деплоя)

### AdminOps — caps / reserveFactor / liqProtocolFee

**Скрипт:** [script/operations/AdminOps.s.sol](script/operations/AdminOps.s.sol)

**Env:**

```bash
export ADMIN_OP="supplyCap"     # | borrowCap | reserveFactor | liqProtocolFee
export ADMIN_ASSET="0x..."      # underlying
export ADMIN_VALUE="300000"     # caps в целых юнитах, factors в bps
```

**Simulate:**

```bash
ADMIN_OP="supplyCap" \
ADMIN_ASSET="0x..." \
ADMIN_VALUE="300000" \
forge script script/operations/AdminOps.s.sol:AdminOps \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  -vvvv
```

**Broadcast:**

```bash
ADMIN_OP="supplyCap" \
ADMIN_ASSET="0x..." \
ADMIN_VALUE="300000" \
forge script script/operations/AdminOps.s.sol:AdminOps \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  -vvvv
```

Вызывать ключом с `POOL_ADMIN` / `RISK_ADMIN`. После шага 7 — только через Safe Transaction Builder от `MAIN_MULTISIG`.

### Emergency freeze / pause

**Скрипт:** [script/operations/ExecuteEmergencyPayload.s.sol](script/operations/ExecuteEmergencyPayload.s.sol)

**Env:**

```bash
export EMERGENCY_ACTION="freeze"   # | unfreeze | pause | unpause
export EMERGENCY_ASSET="0x..."
```

**Simulate:**

```bash
EMERGENCY_ACTION="freeze" \
EMERGENCY_ASSET="0x..." \
forge script script/operations/ExecuteEmergencyPayload.s.sol:ExecuteEmergencyPayload \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  -vvvv
```

**Broadcast:**

```bash
EMERGENCY_ACTION="freeze" \
EMERGENCY_ASSET="0x..." \
forge script script/operations/ExecuteEmergencyPayload.s.sol:ExecuteEmergencyPayload \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  -vvvv
```

Запускать от ключа/мультисига с `EMERGENCY_ADMIN` (после шага 7 — `EMERGENCY_HOT`).

---

## Monitoring (read-only, всегда без `--broadcast`)

### ReserveStatus

Дамп всех резервов: caps, ликвидность, rate, утилизация, frozen/paused. **Env:** нет.

```bash
forge script script/monitoring/ReserveStatus.s.sol:ReserveStatus \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  -vvvv
```

### HealthCheck

Audit owner'ов и ролей. Запускать после каждого шага 6–8.

**Env:**

```bash
export CHECK_DEPLOYER="0x..."   # опционально
export CHECK_REWARD="0x..."     # опционально
```

```bash
CHECK_DEPLOYER="0x..." \
forge script script/monitoring/HealthCheck.s.sol:HealthCheck \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  -vvvv
```

### IncentivesStatus

`emissionPerSecond` / `distributionEnd` / vault balance / allowance.

**Env:**

```bash
export INCENTIVES_REWARD_TOKEN="0x..."
export INCENTIVES_REWARDS_VAULT="0x..."
```

```bash
INCENTIVES_REWARD_TOKEN="0x..." \
INCENTIVES_REWARDS_VAULT="0x..." \
forge script script/monitoring/IncentivesStatus.s.sol:IncentivesStatus \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  -vvvv
```

### UserPosition

Health factor + per-reserve позиция юзера.

**Env:**

```bash
export USER="0x..."
```

```bash
USER="0x..." \
forge script script/monitoring/UserPosition.s.sol:UserPosition \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  -vvvv
```

---

## Шпаргалка — порядок исполнения

| # | Шаг | Скрипт / действие | Кто исполняет |
|---|-----|-------------------|---------------|
| 1 | Oracle adapters (если нужны) | `script/deploy/DeployAdapters.s.sol:DeployAdapters` | deployer |
| 2 | Initial listing | `script/operations/ExecutePayload.s.sol:ExecutePayload` (`PAYLOAD=InitialListing`) | deployer |
| 3 | eMode категории | `script/operations/ExecutePayload.s.sol:ExecutePayload` (`PAYLOAD=ConfigureEModes`) | deployer |
| 4 | `IncentivesConfig` + `setWeights` | `forge create` + `cast send` | deployer |
| 5 | xK613 emissions | `script/incentives/ConfigureSupplyIncentives.s.sol:ConfigureSupplyIncentives` | deployer |
| 6 | Grant roles to multisigs | `script/admin/GrantRoles.s.sol:GrantRoles` (`GRANT_MODE=grantOnly`) | deployer |
| 6a | Тест-tx от `MAIN_MULTISIG` | ручной Safe tx | multisig |
| 7 | Revoke deployer roles | `script/admin/GrantRoles.s.sol:GrantRoles` (`GRANT_MODE=grantRevoke`) | deployer |
| 8 | Rotate `DEFAULT_ADMIN_ROLE` | `cast send grantRole + renounceRole` | deployer |

После шага 8 deployer-ключ «умер». Все дальнейшие операции — только через `MAIN_MULTISIG` и `EMERGENCY_HOT`.

**Правило на каждом broadcast-шаге:** сначала прогнать команду без `--broadcast` (simulate), убедиться что трассировка зелёная, только потом повторить с `--broadcast`.
