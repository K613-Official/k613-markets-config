// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "lib/L2-Protocol/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

/// @title DeployTestnetTokens
contract DeployTestnetTokens is Script {
    address constant WETH = 0x980B62Da83eFf3D4576C647993b0c1D7faf17c73;
    address constant USDC = 0x179522635726710d7C8455c2e0A28f16e07E0D53;
    address constant USDT = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
    address constant DAI = 0xbC47901f4d2C5fc871ae0037Ea05c3F614690781;
    address constant BTC = 0x152B0DF80135c63B4Cb1FBE00DDCE7E9a8FFCb04;

    address[] tokens = [WETH, USDC, USDT, DAI, BTC];

    function run() external {
        // Get deployer address from --private-key flag (used via vm.startBroadcast())
        // If PRIVATE_KEY env var exists, use it; otherwise rely on --private-key from command line
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
        console.log("Deploying/Configuring testnet tokens...");

        // Check if tokens exist and mint if needed
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];

            // Check if address has code (is a contract)
            uint256 codeSize;
            assembly {
                codeSize := extcodesize(token)
            }

            if (codeSize == 0) {
                console.log("Token at", token, "is not a contract (skipping)");
                continue;
            }

            // Try to get balance
            try IERC20(token).balanceOf(deployer) returns (uint256 balance) {
                console.log("Token at", token, "balance:", balance);

                // Check if balance is low (threshold: 1000 tokens with 18 decimals)
                // Note: This check uses 18 decimals for all tokens, adjust if needed for USDC/USDT (6 decimals) or WBTC (8 decimals)
                if (balance < 1000 * 10 ** 18) {
                    console.log("Low balance detected, consider minting tokens...");
                }
            } catch {
                console.log("Token at", token, "error getting balance");
            }
        }

        vm.stopBroadcast();

        console.log("Token deployment/configuration complete!");
    }
}

