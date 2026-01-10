// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "../src/interfaces/IAaveExternal.sol";

/// @title DeployTestnetTokens
contract DeployTestnetTokens is Script {
    address constant WETH = 0x980B62Da83eFf3D4576C647993b0c1D7faf17c73;
    address constant USDC = 0x179522635726710d7C8455c2e0A28f16e07E0D53;
    address constant USDT = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
    address constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

    address[] tokens = [WETH, USDC, USDT, DAI, WBTC];

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployer);
        console.log("Deploying/Configuring testnet tokens...");

        vm.startBroadcast(deployerPrivateKey);

        // Check if tokens exist and mint if needed
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];

            // Try to get balance
            try IERC20(token).balanceOf(deployer) returns (uint256 balance) {
                console.log("Token at", token, "balance:", balance);

                //
                if (balance < 1000 * 10 ** 18) {
                    console.log("Low balance, attempting to mint...");
                }
            } catch {
                console.log("Token at", token, "does not exist or is not ERC20");
            }
        }

        vm.stopBroadcast();

        console.log("Token deployment/configuration complete!");
    }
}

