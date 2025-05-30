// SPDX-License-Identifier: MIT
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
    address whale;
    uint256 wbtc_deposit;
    function setUp() public {
        deployer = new DeployDeBond();
        (deBond, whale, wbtc_deposit ) = deployer.run();
        
    }
    ////////////////////////////////External Function Test/////////////////////////////////////////

    function testDeposit() public {
        vm.startPrank(whale);
        deBond.depositSavings(wbtc_deposit,ScriptConstants.MATURITY);

        vm.stopPrank();
    }

    function testUpdateAmount() public {
        vm.startPrank(whale);
        deBond.depositSavings(wbtc_deposit,ScriptConstants.MATURITY);
        uint256 current_timestamp = block.timestamp;
        vm.warp(current_timestamp + ScriptConstants.ONEMONTHEPOCHTIME);
        uint256 aave_deposit = deBond.updateDepositAmount();
        vm.stopPrank();
        console.log(aave_deposit);
     
    }

    function testDepositFailOutOfRange(uint256 usd_deposit) public{
        vm.assume((usd_deposit > 1e9 && usd_deposit < 2e9) || usd_deposit < 1e2);
        vm.startPrank(whale);
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
        vm.startPrank(whale);
        deBond.depositSavings(wbtc_deposit,ScriptConstants.MATURITY);
        uint256 curr_timestamp = block.timestamp;
        vm.warp(curr_timestamp + ScriptConstants.MATURITY);
        deBond.withDrawSavings(wbtc_deposit);
        vm.stopPrank();
    }

    function testWithdrawalFailsIfWithdrawedBeforeMaturity() public {
        vm.startPrank(whale);
        deBond.depositSavings(wbtc_deposit,ScriptConstants.MATURITY);
        deBond.withDrawSavings(wbtc_deposit);
        vm.stopPrank();
    }

    function testWithdrawalFailIfAmountExceedsDepositBalance() public {
        vm.startPrank(whale);
        deBond.depositSavings(wbtc_deposit,ScriptConstants.MATURITY);
        uint256 curr_timestamp = block.timestamp;
        vm.warp(curr_timestamp + ScriptConstants.MATURITY);
        vm.expectRevert(DeBond.WithdrawalExceedsDepositBalance.selector);
        uint256 withdrawal_amount = wbtc_deposit +1; 
        deBond.withDrawSavings(withdrawal_amount);
        vm.stopPrank();
    }

    function testUserCanCheckDepositValue() public{
        vm.startPrank(whale);
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
