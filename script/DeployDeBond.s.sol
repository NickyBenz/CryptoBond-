// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "lib/forge-std/src/Script.sol";
import {DeBond} from "../src/DeBond.sol";
contract DeployDeBond is Script{
    
    
    function run() public {
        uint privKey = vm.envUint("DEV_PRIVKEY"); //Recieves the deployer (set as a junk account)
        vm.addr(privKey); 
        vm.startBroadcast();

        DeBond deBond = new DeBond(); //Deploys the contract to the chain

        vm.stopBroadcast();
    }
}