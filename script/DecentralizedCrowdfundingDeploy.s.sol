// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import "../src/DecentralizedCrowdfunding.sol";
import {Script,console2} from "forge-std/Script.sol";

contract DecentralizedCrowdfundingDeploy is Script {
    function run() external returns (address) {
        DecentralizedCrowdfunding crowdfunding = new DecentralizedCrowdfunding();
        console2.log("DecentralizedCrowdfunding deployed at:", address(crowdfunding));
        return address(crowdfunding);
    }
}