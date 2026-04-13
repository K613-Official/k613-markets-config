// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {RiskParametersConfig} from "../src/config/RiskParametersConfig.sol";
import {TokensRegistry} from "../src/config/TokensRegistry.sol";
import {ITokensRegistry} from "../src/config/interface/ITokensRegistry.sol";

abstract contract RiskParametersFixture is Test {
    RiskParametersConfig internal risk;
    ITokensRegistry internal tokensRegistry;

    function setUp() public virtual {
        TokensRegistry registry = new TokensRegistry(address(this));
        tokensRegistry = ITokensRegistry(address(registry));
        risk = new RiskParametersConfig(address(this), address(tokensRegistry));
    }
}
