// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;


import {Test} from "forge-std/Test.sol";
import {DecentralizedCrowdfundingDeploy} from "../script/DecentralizedCrowdfundingDeploy.s.sol";


contract DeployTest is Test{

    function test_DeployScript() public {
        DecentralizedCrowdfundingDeploy deployScript = new DecentralizedCrowdfundingDeploy();
        address deployedAddress = deployScript.run();

        assertTrue(deployedAddress != address(0), "Deployment failed, address is zero");
        assertTrue(deployedAddress.code.length > 0, "Deployment failed, no code at address");
    }
}