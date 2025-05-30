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
    uint256 wbtc_deposit;
    function setUp() public {
        deployer = new DeployDeBond();
        (deBond, wbtc_deposit) = deployer.run();
        
    }
    ////////////////////////////////External Function Test/////////////////////////////////////////

    function testDeposit() public {
        vm.startPrank(ScriptConstants.cBBTCWHALE);
        deBond.depositSavings(wbtc_deposit,ScriptConstants.MATURITY);

        vm.stopPrank();
    }

    function testDepositFailOutOfRange(uint256 usd_deposit) public{
        vm.assume((usd_deposit > 1e9 && usd_deposit < 2e9) || usd_deposit < 1e2);
        vm.startPrank(ScriptConstants.cBBTCWHALE);
        vm.expectRevert(DeBond.DepositOutOfRange.selector);
        deBond.depositSavings(usd_deposit,ScriptConstants.MATURITY);
        vm.stopPrank();
    }

      

    function testDepositFailIfAmountExceedsTokenBalance() public{
        uint256 privKey = vm.envUint("DEV_PRIVKEY"); //Junk account
        address user = vm.addr(privKey); //User with no tokens
        vm.startPrank(user);    
        vm.expectRevert(DeBond.DepositExceedsAccountBalance.selector);
        deBond.depositSavings(wbtc_deposit,ScriptConstants.MATURITY);
        vm.stopPrank();
    }



    function testWithdrawal() public {
        vm.startPrank(ScriptConstants.cBBTCWHALE);
        deBond.depositSavings(wbtc_deposit,ScriptConstants.MATURITY);
        uint256 curr_timestamp = block.timestamp;
        vm.warp(curr_timestamp + ScriptConstants.MATURITY);
        deBond.withDrawSavings(wbtc_deposit);
        vm.stopPrank();
    }

    function testWithdrawalFailsIfWithdrawedBeforeMaturity() public {
        vm.startPrank(ScriptConstants.cBBTCWHALE);
        deBond.depositSavings(wbtc_deposit,ScriptConstants.MATURITY);
        deBond.withDrawSavings(wbtc_deposit);
        vm.stopPrank();
    }

    function testWithdrawalFailIfAmountExceedsDepositBalance() public {
        vm.startPrank(ScriptConstants.cBBTCWHALE);
        deBond.depositSavings(wbtc_deposit,ScriptConstants.MATURITY);
        uint256 curr_timestamp = block.timestamp;
        vm.warp(curr_timestamp + ScriptConstants.MATURITY);
        vm.expectRevert(DeBond.WithdrawalExceedsDepositBalance.selector);
        uint256 withdrawal_amount = wbtc_deposit +1; 
        deBond.withDrawSavings(withdrawal_amount);
        vm.stopPrank();
    }

    function testUserCanCheckDepositValue() public{
        vm.startPrank(ScriptConstants.cBBTCWHALE);
        deBond.depositSavings(wbtc_deposit,ScriptConstants.MATURITY);
        uint256 actual_deposit_value = deBond.checkDepositAmount();
        vm.stopPrank();
        assertEq(actual_deposit_value, wbtc_deposit);
    }

    function testGetUSDAmount() public view {
        uint256 usd_amount = deBond._getUSDAmount(ScriptConstants.WBTC_APROVE_AMOUNT);
        console.log(usd_amount);
    }
   
    

}
