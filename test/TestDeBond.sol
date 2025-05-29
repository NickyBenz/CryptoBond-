// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test,console} from "lib/forge-std/src/Test.sol";
import {ScriptConstants,DeployDeBond} from "../script/DeployDeBond.s.sol";
import {DeBond} from "../src/DeBond.sol";
import {IERC20} from  "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IUniswapV3Pool} from "lib/uniswap-v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {AggregatorV3Interface} from "../lib/chainlink-local/src/data-feeds/interfaces/AggregatorV3Interface.sol";

contract TestDeBond is Test {
    DeployDeBond deployer;
    DeBond deBond;
    address user;
    function setUp() public {
        deployer = new DeployDeBond();
        deBond = deployer.run();
    }



    function testDeposit() public  {
        vm.startPrank(ScriptConstants.cBBTCWHALE);

        uint256 initial_WBTC_Balance = IERC20(ScriptConstants.cbBTC).balanceOf(ScriptConstants.cBBTCWHALE);
        uint256 wbtc_deposit = _getBTCAmount(ScriptConstants.USD_DEPOSIT_AMOUNT);
        deBond.depositSavings(wbtc_deposit, ScriptConstants.MATURITY );

        uint256 final_WBTC_Balance = IERC20(ScriptConstants.cbBTC).balanceOf(ScriptConstants.cBBTCWHALE);
        

        vm.stopPrank();


        assertEq(initial_WBTC_Balance, final_WBTC_Balance + wbtc_deposit );


    }

    function testWithdrawal() public {
        vm.startPrank(ScriptConstants.cBBTCWHALE);

        uint256 initial_WBTC_Balance = IERC20(ScriptConstants.cbBTC).balanceOf(ScriptConstants.cBBTCWHALE);
        uint256 wbtc_deposit = _getBTCAmount(ScriptConstants.USD_DEPOSIT_AMOUNT);
        deBond.depositSavings(wbtc_deposit, ScriptConstants.MATURITY );
        uint256 depositTimestamp = block.timestamp;
        vm.warp(depositTimestamp + ScriptConstants.MATURITY);   
        deBond.withDrawSavings(wbtc_deposit);
        uint256 final_WBTC_Balance = IERC20(ScriptConstants.cbBTC).balanceOf(ScriptConstants.cBBTCWHALE);


        vm.stopPrank();

    

        assertEq(initial_WBTC_Balance, final_WBTC_Balance  );

    }



    function testDepositFailAbove1000USD(uint256 usd_deposit_amount) public  { 
        vm.assume(usd_deposit_amount > 1000);
        vm.startPrank(ScriptConstants.cBBTCWHALE);

        uint256 initial_WBTC_Balance = IERC20(ScriptConstants.cbBTC).balanceOf(ScriptConstants.cBBTCWHALE);
        console.log(initial_WBTC_Balance);
        uint256 wbtc_deposit = _getBTCAmount(usd_deposit_amount);
        console.log(wbtc_deposit);
        vm.expectRevert(DeBond.ExceededMaxUSDAmount.selector);
        deBond.depositSavings(wbtc_deposit, ScriptConstants.MATURITY );

        uint256 final_WBTC_Balance = IERC20(ScriptConstants.cbBTC).balanceOf(ScriptConstants.cBBTCWHALE);
        

        vm.stopPrank();




    }



    function _getBTCAmount(uint256 usd_amount) internal view returns(uint256 wbtcAmt){
         (,int256 price,,,) = AggregatorV3Interface(ScriptConstants.PRICEFEED).latestRoundData();
         uint256 decimals = uint256(AggregatorV3Interface(ScriptConstants.PRICEFEED).decimals());
         uint256 btc_decimals = ERC20(ScriptConstants.cbBTC).decimals();
         wbtcAmt = (usd_amount * (10**decimals) * (10**btc_decimals)* (10))/(uint256(price));
                 
    }

    function testGetUSDAmount() public {
                vm.startPrank(ScriptConstants.cBBTCWHALE);
                uint256 btcDecimals = ERC20(ScriptConstants.cbBTC).decimals();

                uint256 testWBTC = 1*(10**btcDecimals);
                (uint256 usdAmt) = deBond._getUSDAmount(testWBTC);
                console.log(usdAmt);
                vm.stopPrank();
                
    }

}
