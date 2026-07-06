// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import "../src/DecentralizedCrowdfunding.sol";
import {Script,console2} from "forge-std/Script.sol";

contract DecentralizedCrowdfundingDeploy is Script {
    function run() external returns (address) {
        vm.startBroadcast();

        DecentralizedCrowdfunding crowdfunding = new DecentralizedCrowdfunding();

        vm.stopBroadcast();
        
        console2.log("DecentralizedCrowdfunding deployed at:", address(crowdfunding));
        return address(crowdfunding);
    }
}