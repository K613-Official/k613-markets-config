// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title IAaveOracle
/// @notice Interface for Aave v3 Oracle
interface IAaveOracle {
    /// @notice Sets the price feed sources for multiple assets
    /// @param assets Array of asset addresses
    /// @param sources Array of price feed addresses
    function setAssetSources(address[] calldata assets, address[] calldata sources) external;

    /// @notice Gets the price of an asset
    /// @param asset The asset address
    /// @return The price of the asset
    function getAssetPrice(address asset) external view returns (uint256);

    /// @notice Gets the price feed source for an asset
    /// @param asset The asset address
    /// @return The price feed address
    function getSourceOfAsset(address asset) external view returns (address);
}

/// @title IPoolAddressesProvider
/// @notice Interface for Aave v3 PoolAddressesProvider
interface IPoolAddressesProvider {
    /// @notice Returns the address of the PoolConfigurator proxy
    /// @return The PoolConfigurator proxy address
    function getPoolConfigurator() external view returns (address);

    /// @notice Returns the address of the Pool proxy
    /// @return The Pool proxy address
    function getPool() external view returns (address);

    /// @notice Returns the address of the price oracle
    /// @return The price oracle address
    function getPriceOracle() external view returns (address);

    /// @notice Returns the address of the PoolDataProvider
    /// @return The PoolDataProvider address
    function getPoolDataProvider() external view returns (address);

    /// @notice Returns the address for a given id
    /// @param id The id to get the address for
    /// @return The address for the given id
    function getAddress(bytes32 id) external view returns (address);
}

/// @title IPoolConfigurator
/// @notice Interface for Aave v3 PoolConfigurator
interface IPoolConfigurator {
    /// @notice Initializes multiple reserves
    /// @param input The array of initialization parameters
    function initReserves(ConfiguratorInputTypes.InitReserveInput[] calldata input) external;

    /// @notice Updates the borrow cap of a reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @param newBorrowCap The new borrow cap
    function setBorrowCap(address asset, uint256 newBorrowCap) external;

    /// @notice Updates the supply cap of a reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @param newSupplyCap The new supply cap
    function setSupplyCap(address asset, uint256 newSupplyCap) external;

    /// @notice Updates the reserve factor of a reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @param newReserveFactor The new reserve factor
    function setReserveFactor(address asset, uint256 newReserveFactor) external;

    /// @notice Updates the liquidation bonus of a reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @param newLiquidationBonus The new liquidation bonus
    function setLiquidationBonus(address asset, uint256 newLiquidationBonus) external;

    /// @notice Updates the liquidation threshold of a reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @param newLiquidationThreshold The new liquidation threshold
    function setLiquidationThreshold(address asset, uint256 newLiquidationThreshold) external;

    /// @notice Updates the LTV of a reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @param newLtv The new LTV
    function setLtv(address asset, uint256 newLtv) external;

    /// @notice Configures the reserve as collateral
    /// @param asset The address of the underlying asset of the reserve
    /// @param ltv The loan to value of the asset when used as collateral
    /// @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
    /// @param liquidationBonus The bonus liquidators receive to liquidate this asset
    function configureReserveAsCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external;

    /// @notice Enables or disables borrowing on a reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @param enabled True if borrowing should be enabled, false otherwise
    function setReserveBorrowing(address asset, bool enabled) external;

    /// @notice Enables or disables stable rate borrowing on a reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @param enabled True if stable rate borrowing should be enabled, false otherwise
    function setReserveStableRateBorrowing(address asset, bool enabled) external;
}

/// @title ConfiguratorInputTypes
/// @notice Types for PoolConfigurator input
library ConfiguratorInputTypes {
    struct InitReserveInput {
        address aTokenImpl;
        address stableDebtTokenImpl;
        address variableDebtTokenImpl;
        uint8 underlyingAssetDecimals;
        address interestRateStrategyAddress;
        address underlyingAsset;
        address treasury;
        address incentivesController;
        string aTokenName;
        string aTokenSymbol;
        string variableDebtTokenName;
        string variableDebtTokenSymbol;
        string stableDebtTokenName;
        string stableDebtTokenSymbol;
        bytes params;
    }
}

/// @title IPool
/// @notice Interface for Aave v3 Pool
interface IPool {
    /// @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens
    /// @param asset The address of the underlying asset to supply
    /// @param amount The amount to be supplied
    /// @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
    ///   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    ///   is a different wallet
    /// @param referralCode Code used to register the integrator originating the operation, for potential rewards
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /// @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    /// @param asset The address of the underlying asset to withdraw
    /// @param amount The underlying amount to be withdrawn
    /// @param to The address that will receive the underlying, same as msg.sender if the user
    ///   wants to receive it on his own wallet, or a different address if the beneficiary is a
    ///   different wallet
    /// @return The final amount withdrawn
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /// @notice Allows users to borrow a specific `amount` of the reserve underlying asset
    /// @param asset The address of the underlying asset to borrow
    /// @param amount The amount to be borrowed
    /// @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
    /// @param referralCode The code used to register the integrator originating the operation, for potential rewards
    /// @param onBehalfOf The address of the user who will receive the debt
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        external;

    /// @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
    /// @param asset The address of the borrowed underlying asset previously borrowed
    /// @param amount The amount to repay
    /// @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
    /// @param onBehalfOf The address of the user who will get his debt reduced/removed
    /// @return The final amount repaid
    function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);
}

/// @title IERC20
/// @notice Standard ERC20 interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

