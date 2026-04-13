// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokensConfig} from "./TokensConfig.sol";
import {ITokensRegistry} from "./interface/ITokensRegistry.sol";
import {IRiskParametersConfig} from "./interface/IRiskParametersConfig.sol";

/// @title RiskParametersConfig
/// @notice Admin-managed risk templates and per-symbol caps consumed by `getRiskParams`.
/// @dev Liquidation bonus is expressed like Aave: basis points above 100% collateral `BONUS` where 10_500 means 105%.
contract RiskParametersConfig is IRiskParametersConfig {
    /// @notice Caller is not `admin`.
    error Unauthorized();
    /// @notice `initialAdmin` or `newAdmin` was zero.
    error InvalidAdmin();
    /// @notice Constructor received zero `tokensRegistry_`.
    error InvalidTokensRegistry();
    /// @notice A class risk field exceeded `BASIS_POINTS`.
    error InvalidBasisPointValue();
    /// @notice Liquidation bonus was below `BASIS_POINTS` (100%).
    error InvalidLiquidationBonus();
    /// @notice Supply cap was not strictly greater than borrow cap for caps updates.
    error InvalidCapsOrder();

    /// @notice Emitted when `admin` is rotated.
    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);
    /// @notice Emitted when default class risk changes.
    event DefaultRiskUpdated(uint256 ltv, uint256 lt, uint256 lb, uint256 rf);
    /// @notice Emitted when stablecoin class risk changes.
    event StablecoinRiskUpdated(uint256 ltv, uint256 lt, uint256 lb, uint256 rf);
    /// @notice Emitted when WETH-like class risk changes.
    event WethLikeRiskUpdated(uint256 ltv, uint256 lt, uint256 lb, uint256 rf);
    /// @notice Emitted when BTC-like class risk changes.
    event BtcRiskUpdated(uint256 ltv, uint256 lt, uint256 lb, uint256 rf);
    /// @notice Emitted when WMON class risk changes.
    event WmonRiskUpdated(uint256 ltv, uint256 lt, uint256 lb, uint256 rf);
    /// @notice Emitted when MON derivative class risk changes.
    event MonDerivativeRiskUpdated(uint256 ltv, uint256 lt, uint256 lb, uint256 rf);
    /// @notice Emitted when per-symbol caps are written.
    event TokenCapsUpdated(bytes32 indexed symbolHash, uint256 borrowCap, uint256 supplyCap);
    /// @notice Emitted when legacy default and BTC caps change.
    event LegacyCapsUpdated(uint256 defaultBorrow, uint256 defaultSupply, uint256 btcBorrow, uint256 btcSupply);

    /// @notice Denominator for all percentage-like fields (100% = 10_000).
    uint256 public constant BASIS_POINTS = 10_000;

    /// @notice Template risk curve shared by a bucket of assets.
    /// @param ltv Loan-to-value in basis points.
    /// @param liquidationThreshold Liquidation threshold in basis points.
    /// @param liquidationBonus Liquidation bonus in basis points.
    /// @param reserveFactor Reserve factor in basis points.
    struct ClassRisk {
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 reserveFactor;
    }

    /// @notice Per-symbol borrow and supply caps stored by `keccak256` of the UTF-8 symbol.
    /// @param borrowCap Maximum borrowable units for the reserve.
    /// @param supplyCap Maximum supplied units for the reserve.
    struct TokenCaps {
        uint256 borrowCap;
        uint256 supplyCap;
    }

    /// @notice Governance key allowed to mutate risk and caps.
    address public admin;
    /// @notice Immutable token listing used to enumerate `getRiskParams` results.
    ITokensRegistry public immutable tokensRegistry;

    /// @notice Fallback class when a symbol does not match a specialized bucket.
    ClassRisk public defaultRisk;
    /// @notice Risk template for fiat-pegged stablecoins.
    ClassRisk public stablecoinRisk;
    /// @notice Risk template for ETH-correlated assets.
    ClassRisk public wethLikeRisk;
    /// @notice Risk template for BTC-correlated assets.
    ClassRisk public btcRisk;
    /// @notice Risk template for wrapped MON.
    ClassRisk public wmonRisk;
    /// @notice Risk template for MON ecosystem derivatives.
    ClassRisk public monDerivativeRisk;

    mapping(bytes32 => TokenCaps) private caps;

    /// @notice Borrow and supply caps for stablecoins that fall back to legacy defaults.
    uint256 public legacyDefaultBorrowCap;
    uint256 public legacyDefaultSupplyCap;
    /// @notice Borrow and supply caps for native BTC symbol when not using per-symbol caps.
    uint256 public legacyBtcBorrowCap;
    uint256 public legacyBtcSupplyCap;

    /// @notice Restricts mutating calls to `admin`.
    modifier onlyAdmin() {
        if (msg.sender != admin) revert Unauthorized();
        _;
    }

    /// @notice Initializes admin, registry wiring, default class curves, legacy caps, and seed caps.
    /// @param initialAdmin Non-zero admin address.
    /// @param tokensRegistry_ Non-zero `ITokensRegistry` implementation.
    constructor(address initialAdmin, address tokensRegistry_) {
        if (initialAdmin == address(0)) revert InvalidAdmin();
        if (tokensRegistry_ == address(0)) revert InvalidTokensRegistry();
        admin = initialAdmin;
        tokensRegistry = ITokensRegistry(tokensRegistry_);
        defaultRisk = ClassRisk(7500, 8000, 10_500, 5000);
        stablecoinRisk = ClassRisk(8000, 8500, 10_250, 2500);
        wethLikeRisk = ClassRisk(8000, 8250, 10_500, 2500);
        btcRisk = ClassRisk(7000, 7500, 10_500, 2500);
        wmonRisk = ClassRisk(5500, 6500, 10_750, 5000);
        monDerivativeRisk = ClassRisk(4500, 6000, 10_750, 5000);
        legacyDefaultBorrowCap = 1_000_000;
        legacyDefaultSupplyCap = 2_000_000;
        legacyBtcBorrowCap = 100;
        legacyBtcSupplyCap = 200;
        _initTokenCaps();
    }

    /// @notice Transfers admin rights to `newAdmin`.
    /// @param newAdmin Next admin address.
    function setAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert InvalidAdmin();
        address previousAdmin = admin;
        admin = newAdmin;
        emit AdminUpdated(previousAdmin, newAdmin);
    }

    /// @notice Updates the default class risk template after validation.
    /// @param next Fully specified `ClassRisk` snapshot.
    function setDefaultRisk(ClassRisk calldata next) external onlyAdmin {
        _validateClassRisk(next);
        defaultRisk = next;
        emit DefaultRiskUpdated(next.ltv, next.liquidationThreshold, next.liquidationBonus, next.reserveFactor);
    }

    /// @notice Updates the stablecoin class risk template after validation.
    /// @param next Fully specified `ClassRisk` snapshot.
    function setStablecoinRisk(ClassRisk calldata next) external onlyAdmin {
        _validateClassRisk(next);
        stablecoinRisk = next;
        emit StablecoinRiskUpdated(next.ltv, next.liquidationThreshold, next.liquidationBonus, next.reserveFactor);
    }

    /// @notice Updates the WETH-like class risk template after validation.
    /// @param next Fully specified `ClassRisk` snapshot.
    function setWethLikeRisk(ClassRisk calldata next) external onlyAdmin {
        _validateClassRisk(next);
        wethLikeRisk = next;
        emit WethLikeRiskUpdated(next.ltv, next.liquidationThreshold, next.liquidationBonus, next.reserveFactor);
    }

    /// @notice Updates the BTC-like class risk template after validation.
    /// @param next Fully specified `ClassRisk` snapshot.
    function setBtcRisk(ClassRisk calldata next) external onlyAdmin {
        _validateClassRisk(next);
        btcRisk = next;
        emit BtcRiskUpdated(next.ltv, next.liquidationThreshold, next.liquidationBonus, next.reserveFactor);
    }

    /// @notice Updates the WMON class risk template after validation.
    /// @param next Fully specified `ClassRisk` snapshot.
    function setWmonRisk(ClassRisk calldata next) external onlyAdmin {
        _validateClassRisk(next);
        wmonRisk = next;
        emit WmonRiskUpdated(next.ltv, next.liquidationThreshold, next.liquidationBonus, next.reserveFactor);
    }

    /// @notice Updates the MON derivative class risk template after validation.
    /// @param next Fully specified `ClassRisk` snapshot.
    function setMonDerivativeRisk(ClassRisk calldata next) external onlyAdmin {
        _validateClassRisk(next);
        monDerivativeRisk = next;
        emit MonDerivativeRiskUpdated(next.ltv, next.liquidationThreshold, next.liquidationBonus, next.reserveFactor);
    }

    /// @notice Writes per-symbol caps after enforcing ordering.
    /// @param symbol Plain ticker used for `keccak256` indexing.
    /// @param borrowCap Borrow cap for the symbol.
    /// @param supplyCap Supply cap for the symbol; must exceed `borrowCap`.
    function setTokenCaps(string calldata symbol, uint256 borrowCap, uint256 supplyCap) external onlyAdmin {
        if (supplyCap <= borrowCap) revert InvalidCapsOrder();
        caps[_hashString(symbol)] = TokenCaps(borrowCap, supplyCap);
        emit TokenCapsUpdated(_hashString(symbol), borrowCap, supplyCap);
    }

    /// @notice Updates legacy caps used when a stablecoin or BTC row lacks explicit caps.
    /// @param defaultBorrow Legacy borrow cap for non-explicit stablecoins.
    /// @param defaultSupply Legacy supply cap for non-explicit stablecoins.
    /// @param btcBorrow Legacy borrow cap for native BTC rows.
    /// @param btcSupply Legacy supply cap for native BTC rows.
    function setLegacyCaps(uint256 defaultBorrow, uint256 defaultSupply, uint256 btcBorrow, uint256 btcSupply)
        external
        onlyAdmin
    {
        if (defaultSupply <= defaultBorrow || btcSupply <= btcBorrow) revert InvalidCapsOrder();
        legacyDefaultBorrowCap = defaultBorrow;
        legacyDefaultSupplyCap = defaultSupply;
        legacyBtcBorrowCap = btcBorrow;
        legacyBtcSupplyCap = btcSupply;
        emit LegacyCapsUpdated(defaultBorrow, defaultSupply, btcBorrow, btcSupply);
    }

    /// @notice Reads stored caps for `symbol`.
    /// @param symbol Plain ticker used for `keccak256` indexing.
    /// @return borrowCap Stored borrow cap (zero if unset).
    /// @return supplyCap Stored supply cap (zero if unset).
    function getCaps(string calldata symbol) external view returns (uint256 borrowCap, uint256 supplyCap) {
        TokenCaps memory c = caps[_hashString(symbol)];
        return (c.borrowCap, c.supplyCap);
    }

    /// @inheritdoc IRiskParametersConfig
    function getRiskParams(TokensConfig.Network network)
        external
        view
        override
        returns (IRiskParametersConfig.RiskParams[] memory params)
    {
        TokensConfig.Token[] memory tokens = tokensRegistry.getTokens(network);
        params = new IRiskParametersConfig.RiskParams[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            params[i] = _tokenRiskParams(tokens[i]);
        }
    }

    /// @notice Validates basis-point bounds and liquidation bonus floor.
    /// @param c Candidate class risk snapshot.
    function _validateClassRisk(ClassRisk memory c) private pure {
        if (c.ltv > BASIS_POINTS || c.liquidationThreshold > BASIS_POINTS || c.reserveFactor > BASIS_POINTS) {
            revert InvalidBasisPointValue();
        }
        if (c.liquidationBonus < BASIS_POINTS) revert InvalidLiquidationBonus();
    }

    /// @notice Seeds known production symbols with default cap pairs.
    function _initTokenCaps() private {
        _writeCap("USDC", 200_000, 250_000);
        _writeCap("AUSD", 200_000, 250_000);
        _writeCap("USDT0", 200_000, 250_000);
        _writeCap("WSRUSD", 200_000, 250_000);
        _writeCap("wstETH", 150_000, 190_000);
        _writeCap("WETH", 120_000, 150_000);
        _writeCap("WBTC", 70_000, 90_000);
        _writeCap("WMON", 30_000, 40_000);
        _writeCap("SHMON", 30_000, 40_000);
        _writeCap("SMON", 5000, 7000);
        _writeCap("GMON", 15_000, 20_000);
    }

    /// @notice Persists caps for `symbol` without validation (caller must enforce ordering).
    /// @param symbol Plain ticker.
    /// @param borrowCap Borrow cap.
    /// @param supplyCap Supply cap.
    function _writeCap(string memory symbol, uint256 borrowCap, uint256 supplyCap) private {
        caps[_hashString(symbol)] = TokenCaps(borrowCap, supplyCap);
    }

    /// @notice `keccak256` of the UTF-8 bytes of `str` without allocating a bytes buffer.
    /// @param str Input string in memory.
    /// @return hash Symbol hash used as mapping key.
    function _hashString(string memory str) private pure returns (bytes32 hash) {
        assembly {
            hash := keccak256(add(str, 0x20), mload(str))
        }
    }

    /// @notice Maps a registry token to class risk and caps using hard-coded symbol routing.
    /// @param token Registry row being expanded.
    /// @return row Fully populated `RiskParams` for scripts and payloads.
    function _tokenRiskParams(TokensConfig.Token memory token)
        private
        view
        returns (IRiskParametersConfig.RiskParams memory row)
    {
        bytes32 symbolHash = _hashString(token.symbol);

        ClassRisk memory classData = defaultRisk;
        uint256 borrowCap;
        uint256 supplyCap;

        if (
            symbolHash == _hashString("USDC") || symbolHash == _hashString("AUSD") || symbolHash == _hashString("USDT0")
                || symbolHash == _hashString("WSRUSD") || symbolHash == _hashString("USDT")
                || symbolHash == _hashString("DAI")
        ) {
            classData = stablecoinRisk;
            if (symbolHash == _hashString("USDC")) {
                (borrowCap, supplyCap) = _caps("USDC");
            } else if (symbolHash == _hashString("AUSD")) {
                (borrowCap, supplyCap) = _caps("AUSD");
            } else if (symbolHash == _hashString("USDT0")) {
                (borrowCap, supplyCap) = _caps("USDT0");
            } else if (symbolHash == _hashString("WSRUSD")) {
                (borrowCap, supplyCap) = _caps("WSRUSD");
            } else {
                borrowCap = legacyDefaultBorrowCap;
                supplyCap = legacyDefaultSupplyCap;
            }
        } else if (symbolHash == _hashString("WETH") || symbolHash == _hashString("wstETH")) {
            classData = wethLikeRisk;
            if (symbolHash == _hashString("wstETH")) {
                (borrowCap, supplyCap) = _caps("wstETH");
            } else {
                (borrowCap, supplyCap) = _caps("WETH");
            }
        } else if (symbolHash == _hashString("WBTC") || symbolHash == _hashString("BTC")) {
            classData = btcRisk;
            if (symbolHash == _hashString("WBTC")) {
                (borrowCap, supplyCap) = _caps("WBTC");
            } else {
                borrowCap = legacyBtcBorrowCap;
                supplyCap = legacyBtcSupplyCap;
            }
        } else if (symbolHash == _hashString("WMON")) {
            classData = wmonRisk;
            (borrowCap, supplyCap) = _caps("WMON");
        } else if (symbolHash == _hashString("SHMON")) {
            classData = monDerivativeRisk;
            (borrowCap, supplyCap) = _caps("SHMON");
        } else if (symbolHash == _hashString("SMON")) {
            classData = monDerivativeRisk;
            (borrowCap, supplyCap) = _caps("SMON");
        } else if (symbolHash == _hashString("GMON")) {
            classData = monDerivativeRisk;
            (borrowCap, supplyCap) = _caps("GMON");
        }

        return IRiskParametersConfig.RiskParams({
            asset: token.asset,
            ltv: classData.ltv,
            liquidationThreshold: classData.liquidationThreshold,
            liquidationBonus: classData.liquidationBonus,
            reserveFactor: classData.reserveFactor,
            borrowCap: borrowCap,
            supplyCap: supplyCap
        });
    }

    /// @notice Loads caps for `symbol` from storage.
    /// @param symbol Plain ticker.
    /// @return borrowCap Stored borrow cap.
    /// @return supplyCap Stored supply cap.
    function _caps(string memory symbol) private view returns (uint256 borrowCap, uint256 supplyCap) {
        TokenCaps memory c = caps[_hashString(symbol)];
        return (c.borrowCap, c.supplyCap);
    }
}
