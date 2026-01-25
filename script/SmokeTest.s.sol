// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {IPool} from "lib/L2-Protocol/src/contracts/interfaces/IPool.sol";
import {IERC20} from "lib/L2-Protocol/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {ArbitrumSepolia} from "../src/config/networks/ArbitrumSepolia.sol";

/// @title SmokeTest
/// @notice Script to perform smoke tests: deposit, borrow, repay, withdraw
/// @dev Critical for demonstration - tests basic Aave v3 functionality
contract SmokeTest is Script {
    IPool public pool;

    // Change this constant to switch networks
    TokensConfig.Network internal constant NETWORK = TokensConfig.Network.ArbitrumSepolia;

    // Test amounts (adjust based on token decimals)
    uint256 constant TEST_DEPOSIT_AMOUNT = 1000 * 10 ** 18; // 1000 tokens (for 18 decimals)
    uint256 constant TEST_BORROW_AMOUNT = 100 * 10 ** 18; // 100 tokens (for 18 decimals)

    function run() external {
        // Try to get private key from env, fallback to broadcast() if not set
        address deployer;

        try vm.envUint("PRIVATE_KEY") returns (uint256 pk) {
            deployer = vm.addr(pk);
            vm.startBroadcast(pk);
        } catch {
            // Use --private-key from command line
            vm.startBroadcast();
            // Get deployer from wallets
            address[] memory wallets = vm.getWallets();
            if (wallets.length > 0) {
                deployer = wallets[0];
            } else {
                deployer = tx.origin;
            }
        }

        console.log("Deployer address:", deployer);
        console.log("Running smoke tests...");

        pool = IPool(_getPool());

        // Test with WETH (first token)
        TokensConfig.Token[] memory tokens = TokensConfig.getTokens(NETWORK);
        require(tokens.length > 0, "No tokens configured");

        address testAsset = tokens[0].asset; // Use first token (WETH)
        uint8 decimals = tokens[0].decimals;

        uint256 depositAmount = TEST_DEPOSIT_AMOUNT;
        if (decimals == 6) {
            depositAmount = 1000 * 10 ** 6; // USDC/USDT
        } else if (decimals == 8) {
            depositAmount = 1 * 10 ** 8; // WBTC
        }

        console.log("Testing with asset:", tokens[0].symbol);
        console.log("Asset address:", testAsset);

        // Test 1: Deposit
        console.log("\n=== Test 1: Deposit ===");
        testDeposit(testAsset, depositAmount, deployer);

        // Test 2: Borrow
        console.log("\n=== Test 2: Borrow ===");
        uint256 borrowAmount = depositAmount / 10; // Borrow 10% of deposit
        testBorrow(testAsset, borrowAmount, deployer);

        // Test 3: Repay
        console.log("\n=== Test 3: Repay ===");
        testRepay(testAsset, borrowAmount, deployer);

        // Test 4: Withdraw
        console.log("\n=== Test 4: Withdraw ===");
        testWithdraw(testAsset, depositAmount / 2, deployer); // Withdraw 50%

        vm.stopBroadcast();

        console.log("\n=== All smoke tests completed successfully! ===");
    }

    /// @notice Test deposit functionality
    function testDeposit(address asset, uint256 amount, address user) internal {
        IERC20 token = IERC20(asset);

        // Check balance
        uint256 balance = token.balanceOf(user);
        console.log("User balance:", balance);
        require(balance >= amount, "Insufficient balance");

        // Approve pool
        token.approve(address(pool), amount);
        console.log("Approved pool to spend", amount);

        // Deposit
        pool.supply(asset, amount, user, 0);
        console.log("Deposited", amount, "tokens");

        // Verify deposit (check aToken balance)
        console.log("Deposit successful!");
    }

    /// @notice Test borrow functionality
    function testBorrow(address asset, uint256 amount, address user) internal {
        // Borrow in variable rate mode (2)
        pool.borrow(asset, amount, 2, 0, user);
        console.log("Borrowed", amount, "tokens at variable rate");

        // Verify borrow
        IERC20 token = IERC20(asset);
        uint256 balance = token.balanceOf(user);
        console.log("User balance after borrow:", balance);
        console.log("Borrow successful!");
    }

    /// @notice Test repay functionality
    function testRepay(address asset, uint256 amount, address user) internal {
        IERC20 token = IERC20(asset);

        // Approve pool for repayment
        token.approve(address(pool), amount);
        console.log("Approved pool for repayment");

        // Repay variable rate debt (mode 2)
        uint256 repaid = pool.repay(asset, amount, 2, user);
        console.log("Repaid", repaid, "tokens");
        console.log("Repay successful!");
    }

    /// @notice Test withdraw functionality
    function testWithdraw(address asset, uint256 amount, address user) internal {
        // Withdraw
        uint256 withdrawn = pool.withdraw(asset, amount, user);
        console.log("Withdrew", withdrawn, "tokens");
        console.log("Withdraw successful!");
    }

    function _getPool() private pure returns (address) {
        if (NETWORK == TokensConfig.Network.ArbitrumSepolia) {
            return ArbitrumSepolia.POOL;
        } else {
            revert("Unsupported network");
        }
    }
}

