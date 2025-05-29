// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test,console} from "lib/forge-std/src/Test.sol";
import {ScriptConstants,DeployDeBond} from "../script/DeployDeBond.s.sol";
import {DeBond} from "../src/DeBond.sol";
import {IERC20} from  "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
contract TestDeBond is Test {
    DeployDeBond deployer;
    DeBond deBond;
    function setUp() public {
        deployer = new DeployDeBond();
        deBond = deployer.run();
    }

    function testGetUSDAmount() public  {
        vm.startPrank(ScriptConstants.cBBTCWHALE);

        uint256 initial_WBTC_Balance = IERC20(ScriptConstants.cbBTC).balanceOf(ScriptConstants.cBBTCWHALE);


        deBond.depositSavings(ScriptConstants.WBTCDEPOSIT, ScriptConstants.MATURITY );

        uint256 final_WBTC_Balance = IERC20(ScriptConstants.cbBTC).balanceOf(ScriptConstants.cBBTCWHALE);


        vm.stopPrank();


        assertEq(initial_WBTC_Balance, final_WBTC_Balance + ScriptConstants.WBTCDEPOSIT);


    }
    
}
