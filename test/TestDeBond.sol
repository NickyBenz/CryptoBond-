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
    address wbtc;
    address usdc;
    DeBond deBond;
    address whale;
    uint256 wbtc_deposit;
    function setUp() public {
        deployer = new DeployDeBond();
        (deBond, wbtc, usdc , whale, wbtc_deposit ) = deployer.run();
        vm.startPrank(whale);
        IERC20(wbtc).approve(address(deBond), ScriptConstants.WBTC_APPROVE_AMOUNT);
        vm.stopPrank();

    
    }
    ////////////////////////////////External Function Test/////////////////////////////////////////

   


    function testDeposit() public {
        vm.startPrank(whale);
        uint256 current_timestamp = block.timestamp;
        uint256 maturity_timestamp = current_timestamp + ScriptConstants.MATURITY;
        deBond.depositSavings(wbtc_deposit, maturity_timestamp, whale, "Nikhil", "Hi");

        vm.stopPrank();
    }

    function testCheckUpdateAmount() public {
        vm.startPrank(whale);
        uint256 deposit_timestamp = block.timestamp;
        uint256 maturity_timestamp = deposit_timestamp + ScriptConstants.MATURITY;
        deBond.depositSavings(wbtc_deposit, maturity_timestamp, whale, "Nikhil", "Hi");
        vm.warp(deposit_timestamp + ScriptConstants.ONEMONTHEPOCHTIME);
        uint256 aave_deposit = deBond.checkCurrentBalance();
        vm.stopPrank();
        console.log(aave_deposit);
     
    }

    function testDepositFailOutOfRange(uint256 usd_deposit) public{
        vm.assume((usd_deposit > 1e9 && usd_deposit < 2e9) || usd_deposit < 1e2);
        vm.startPrank(whale);
        vm.expectRevert(DeBond.DepositOutOfRange.selector);
        uint256 current_timestamp = block.timestamp;
        uint256 maturity_timestamp = current_timestamp + ScriptConstants.MATURITY;
        deBond.depositSavings(usd_deposit, maturity_timestamp,whale,"Nikhil", "Hi");
        vm.stopPrank();
    }

      

    function testDepositFailIfAmountExceedsTokenBalance() public{
        uint256 privKey = vm.envUint("DEV_PRIVKEY"); //Junk account
        address user = vm.addr(privKey); //User with no tokens
        vm.startPrank(user);    
        vm.expectRevert(DeBond.DepositExceedsAccountBalance.selector);
        uint256 current_timestamp = block.timestamp;
        uint256 maturity_timestamp = current_timestamp + ScriptConstants.MATURITY;
        deBond.depositSavings(wbtc_deposit,maturity_timestamp,whale, "Nikhil", "Hi");
        vm.stopPrank();
    }



    function testWithdrawal() public {
        vm.startPrank(whale);
        uint256 initial_user_balance = IERC20(wbtc).balanceOf(whale); 
        uint256 current_timestamp = block.timestamp;
        uint256 maturity_timestamp = current_timestamp + ScriptConstants.MATURITY;
        deBond.depositSavings(wbtc_deposit,  maturity_timestamp,whale, "Nikhil", "Hi");
        vm.warp(maturity_timestamp);
        deBond.withDrawSavings(wbtc_deposit);
        uint256 final_user_balance = IERC20(wbtc).balanceOf(whale);
        vm.stopPrank();
        assert(initial_user_balance<=final_user_balance);

    }

    function testWithdrawalFailsIfWithdrawedBeforeMaturity() public {
        vm.startPrank(whale);
        uint256 current_timestamp = block.timestamp;
        uint256 maturity_timestamp = current_timestamp + ScriptConstants.MATURITY;
        deBond.depositSavings(wbtc_deposit,maturity_timestamp,whale, "Nikhil", "Hi");
        bytes memory expectedRevertData = abi.encodeWithSelector(DeBond.CannotWithdrawBeforeMaturity.selector, maturity_timestamp);
        vm.expectRevert(expectedRevertData );
        deBond.withDrawSavings(wbtc_deposit);
        vm.stopPrank();
       
    }

    function testWithdrawalFailIfAmountExceedsDepositBalance() public {
        vm.startPrank(whale);
        uint256 current_timestamp = block.timestamp;
        uint256 maturity_timestamp = current_timestamp + ScriptConstants.MATURITY;
        deBond.depositSavings(wbtc_deposit,maturity_timestamp,whale, "Nikhil", "Hi");
        vm.warp(maturity_timestamp);
        vm.expectRevert(DeBond.WithdrawalExceedsDepositBalance.selector);
        uint256 withdrawal_amount = wbtc_deposit +1; 
        deBond.withDrawSavings(withdrawal_amount);
        vm.stopPrank();
    }

    function testUserCanCheckDepositValue() public{
        vm.startPrank(whale);
        uint256 current_timestamp = block.timestamp;
        uint256 maturity_timestamp = current_timestamp + ScriptConstants.MATURITY;
        deBond.depositSavings(wbtc_deposit,maturity_timestamp,whale, "Nikhil", "Hi");
        uint256 actual_deposit_value = deBond.checkDepositAmount();
        vm.stopPrank();
        assertEq(actual_deposit_value, wbtc_deposit);
    }

    
    


}
