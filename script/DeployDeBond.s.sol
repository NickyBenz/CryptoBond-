// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "lib/forge-std/src/Script.sol";
import {DeBond} from "../src/DeBond.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {AggregatorV3Interface} from "../lib/chainlink-local/src/data-feeds/interfaces/AggregatorV3Interface.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

library ScriptConstants {
   
    uint256 constant MATURITY = 1e3;
    uint256 constant USD_DEPOSIT_AMOUNT = 500e6; //User will try to deposit 500 USD
    uint256 constant WBTC_APROVE_AMOUNT = 1e8;
    uint256 constant SCALAR =18;
    uint256 constant ONEMONTHEPOCHTIME = 28e6;

}

contract DeployDeBond is Script{
    
    
    
    function run() public returns(DeBond, address whale, uint256 wbtc_deposit_amount) {
        
        vm.startBroadcast(); //Starts broadcasting to blockchain

        HelperConfig helperConfig = new HelperConfig();

        helperConfig.setActiveConfig();

        (address wbtc, address usdc,address chain_whale,  address aave_pool, address price_feed, address awbtc)  = helperConfig.config();

        whale = chain_whale;

        wbtc_deposit_amount = _getBTCAmount(ScriptConstants.USD_DEPOSIT_AMOUNT, price_feed, usdc, wbtc);


        DeBond deBond = new DeBond(wbtc, price_feed, aave_pool, awbtc); //Deploys the contract to the chain


        vm.stopBroadcast();        
        // vm.startPrank(ScriptConstants.cBBTCWHALE); //Start a prank as a WBTC whale 
        
        
        // DeBond deBond = new DeBond(); //Deploys the contract to the chain
        //  wbtc_deposit_amount =  _getBTCAmount(ScriptConstants.USD_DEPOSIT_AMOUNT); //$500 USD to decimals 
        // IERC20(ScriptConstants.cbBTC).approve(address(deBond), ScriptConstants.WBTC_APROVE_AMOUNT); //Approves the contract to recieve tokens

         return (deBond, whale, wbtc_deposit_amount);
    }   
    
    function _getBTCAmount(uint256 usd_amount, address price_feed, address usdc, address wbtc) internal view returns (uint256 wbtc_amt){
              (,int256 price,,,) = AggregatorV3Interface(price_feed).latestRoundData();
            uint256 usd_decimals = AggregatorV3Interface(price_feed).decimals();
             uint256 usdc_decimals = ERC20(usdc).decimals();
             uint256 wbtc_decimals = ERC20(wbtc).decimals();
             wbtc_amt = Math.mulDiv(usd_amount, 10**(usd_decimals+wbtc_decimals), uint256(price)*10**(usdc_decimals));
    }

}
