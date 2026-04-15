# Пошаговый запуск скриптов

## 1) Подготовка окружения

1. Скопируй шаблон и заполни обязательные переменные:
   - `MONAD_RPC_URL`
   - `PRIVATE_KEY`
   - при необходимости `ETHERSCAN_API_KEY`
2. Загрузите переменные окружения:

```bash
source .env
```

3. Проверьте сборку:

```bash
forge build
```

## 2) Деплой адаптеров через `DeployAdapters.s.sol`

Этот шаг нужен перед листингом активов, которые используют MON-деривативы (SHMON, SMON, GMON).

```bash
forge script script/DeployAdapters.s.sol \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast --slow -vv
```

Сохраните адреса адаптеров из вывода скрипта и используйте их в `priceFeed` соответствующих листингов.

## 3) Выполнить payload через `ExecutePayload.s.sol`

Скрипт поддерживает два payload:
- `InitialListing`
- `ConfigureEModes`

Шаги:

1. Укажите payload:

```bash
export PAYLOAD=InitialListing
```

2. Запустите выполнение:

```bash

```

3. Для eMode запустите тем же способом:

```bash
export PAYLOAD=ConfigureEModes

forge script script/ExecutePayload.s.sol \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast --slow -vv
```

## 4) Настроить incentives через `ConfigureSupplyIncentives.s.sol`

Обязательные переменные:
- `INCENTIVES_CONFIG`
- `INCENTIVES_REWARD_TOKEN`
- `INCENTIVES_REWARDS_VAULT`
- `INCENTIVES_DISTRIBUTION_END`

Опциональные:
- `INCENTIVES_REWARD_ORACLE_ANSWER` (по умолчанию `800000`)
- `INCENTIVES_REWARD_ORACLE_DECIMALS` (по умолчанию `8`)

Шаги:

1. Экспортируйте параметры:

```bash
export INCENTIVES_CONFIG=0xYourIncentivesConfig
export INCENTIVES_REWARD_TOKEN=0xYourRewardToken
export INCENTIVES_REWARDS_VAULT=0xYourRewardsVault
export INCENTIVES_DISTRIBUTION_END=1767225600
```

2. Запустите скрипт:

```bash
forge script script/ConfigureSupplyIncentives.s.sol \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast --slow -vv
```

3. После первого запуска проверьте вывод и при необходимости сделайте `approve` для `PullRewardsTransferStrategy` от имени `INCENTIVES_REWARDS_VAULT`.

## 5) Миграция ролей через `GrantRoles.s.sol`

Режимы:
- `grantOnly` — выдать роли новым адресам, старые оставить
- `grantRevoke` — выдать новые роли и отозвать роли у deployer

Переменные:
- `GRANT_MODE`
- `MAIN_MULTISIG`
- `EMERGENCY_HOT`

Шаги:

1. Безопасный первый прогон:

```bash
export GRANT_MODE=grantOnly
export MAIN_MULTISIG=0xYourMainMultisig
export EMERGENCY_HOT=0xYourEmergencyHot
```

2. Выполните скрипт:

```bash
forge script script/GrantRoles.s.sol \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast -vv
```

3. После проверки доступа мультисигов переведите в финальный режим:

```bash
export GRANT_MODE=grantRevoke

forge script script/GrantRoles.s.sol \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast -vv
```

## 6) Точечные админ-изменения через `AdminOps.s.sol`

Поддерживаемые операции:
- `supplyCap`
- `borrowCap`
- `reserveFactor`
- `liqProtocolFee`

Шаги:

1. Укажите операцию и параметры:

```bash
export ADMIN_OP=supplyCap
export ADMIN_ASSET=0xYourUnderlyingAsset
export ADMIN_VALUE=300000
```

2. Выполните скрипт:

```bash
forge script script/AdminOps.s.sol \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast -vv
```

## 7) Экстренные действия через `ExecuteEmergencyPayload.s.sol`

Поддерживаемые действия:
- `freeze`
- `unfreeze`
- `pause`
- `unpause`

Шаги:

1. Укажите действие и актив:

```bash
export EMERGENCY_ACTION=freeze
export EMERGENCY_ASSET=0xYourUnderlyingAsset
```

2. Выполните скрипт:

```bash
forge script script/ExecuteEmergencyPayload.s.sol \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast -vv
```

## 8) Рекомендуемый порядок запуска

1. `DeployAdapters` (если листинг включает SHMON/SMON/GMON)
2. `ExecutePayload` с `PAYLOAD=InitialListing`
3. `ExecutePayload` с `PAYLOAD=ConfigureEModes`
4. `ConfigureSupplyIncentives`
5. После проверки всех операций: `GrantRoles` (`grantOnly` → проверка → `grantRevoke`)
6. По необходимости в процессе эксплуатации: `AdminOps`
7. Только при инцидентах: `ExecuteEmergencyPayload`

