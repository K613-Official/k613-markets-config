// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPoolConfigurator} from "lib/K613-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {
    IDefaultInterestRateStrategyV2
} from "lib/K613-Protocol/src/contracts/interfaces/IDefaultInterestRateStrategyV2.sol";
import {
    ConfiguratorInputTypes
} from "lib/K613-Protocol/src/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol";
import {TokensConfig} from "../config/TokensConfig.sol";
import {ITokensRegistry} from "../config/interface/ITokensRegistry.sol";
import {NetworkConfig} from "../config/networks/NetworkConfig.sol";
import {ArbitrumSepolia} from "../config/networks/ArbitrumSepolia.sol";
import {MonadMainnet} from "../config/networks/MonadMainnet.sol";

/// @title ListingPayload
/// @notice Governance payload that lists reserves via `initReserves` only.
/// @dev Stateless, execute-only. Use `CollateralConfigPayload` and `RiskUpdatePayload` for further steps.
/// @dev Switch `NETWORK` to target another deployment.
contract ListingPayload {
    error ZeroTokensRegistry();

    ITokensRegistry public immutable tokensRegistry;

    TokensConfig.Network internal constant NETWORK = TokensConfig.Network.MonadMainnet;

    constructor(address tokensRegistry_) {
        if (tokensRegistry_ == address(0)) revert ZeroTokensRegistry();
        tokensRegistry = ITokensRegistry(tokensRegistry_);
    }

    function execute() external {
        NetworkConfig.Addresses memory addrs = _getAddresses();
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(NETWORK);

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

        IPoolConfigurator configurator = IPoolConfigurator(NetworkConfig.getPoolConfigurator(addrs));
        configurator.initReserves(inputs);
    }

    /// @notice Resolves `NetworkConfig.Addresses` for `NETWORK`.
    /// @return addrs Addresses used for reserve initialization.
    function _getAddresses() private pure returns (NetworkConfig.Addresses memory addrs) {
        if (NETWORK == TokensConfig.Network.ArbitrumSepolia) {
            return ArbitrumSepolia.getAddresses();
        } else if (NETWORK == TokensConfig.Network.MonadMainnet) {
            return MonadMainnet.getAddresses();
        } else {
            revert("Unsupported network");
        }
    }

    /// @notice Keccak256 over the UTF-8 bytes of a string.
    /// @param str Input string.
    /// @return hash `keccak256` of input contents.
    function _hashString(string memory str) private pure returns (bytes32 hash) {
        assembly {
            hash := keccak256(add(str, 0x20), mload(str))
        }
    }

    /// @notice Returns per-asset interest rate data based on asset class.
    /// @param symbol Token symbol used to determine asset class.
    /// @return data ABI-encoded `InterestRateData`.
    function _getInterestRateData(string memory symbol) private pure returns (bytes memory data) {
        bytes32 h = _hashString(symbol);

        // Stablecoins: high optimal usage, low slopes
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
