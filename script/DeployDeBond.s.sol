// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "lib/forge-std/src/Script.sol";
import {DeBond} from "../src/DeBond.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


library ScriptConstants {
    address constant  WBTCUSDCPOOL = 0xfBB6Eed8e7aa03B138556eeDaF5D271A5E1e43ef; //Uniswap V3 USDC/cbBTC pool on base to retrieve price 
    address constant cbBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf; //Coinbase Wrapped BTC (cbBTC) address for base
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; //USDC address for base 
    uint256 constant WBTCDEPOSIT = 93e12; 
}

contract DeployDeBond is Script{
    
    
    
    function run() public {
        uint privKey = vm.envUint("DEV_PRIVKEY"); //Recieves the deployer (set as a junk account)
        address testUser = vm.addr(privKey); 
        
        vm.startBroadcast();
        
        IERC20(ScriptConstants.cbBTC).transfer(testUser, ScriptConstants.WBTCDEPOSIT);
        DeBond deBond = new DeBond(); //Deploys the contract to the chain

        vm.stopBroadcast();
    }
}