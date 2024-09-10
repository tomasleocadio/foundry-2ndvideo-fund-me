// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // Before broadcast this has no gas fees, thats why we need to declare before startBroadcast()
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig(); // helperConfig.activeNetworkConfig() calls the auto-generated getter, returning the NetworkConfig struct, from which you can access priceFeed
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
