## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

Для деплоя используйте скрипты из директории `script/`.



**Пошаговый деплой:**
1. ConfigureOracles → 2. InitalReserves → 3. ConfigureCollateral → 4. ConfigureRisk 

forge script script/ConfigureOracles.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL   --private-key $PRIVATE_KEY   --broadcast   --verify   --slow   -vvvv


⚠️ **Важно**: Перед деплоем настройте переменные окружения:
- `PRIVATE_KEY` - приватный ключ деплоера (без 0x)
- `RPC_URL` - RPC URL сети (например, для Arbitrum Sepolia)

📖 **Подробная инструкция**: См. [DEPLOY.md](./DEPLOY.md) для полной документации по деплою.

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
