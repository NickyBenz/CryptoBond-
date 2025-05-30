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
    
    function testDeposit() public {
        console.log(_getBTCAmount(ScriptConstants.USD_DEPOSIT_AMOUNT));
    }

    function testWithdrawal() public {
        
    }

    function testGetUSDAmount() public {
        uint256 usd_amount = deBond._getUSDAmount(ScriptConstants.WBTC_DEPOSIT_AMOUNT);
        console.log(usd_amount);
    }

    function _getBTCAmount(uint256 usd_amount) public returns(uint256 wbtc_amt){
        (,int256 price,,,) = AggregatorV3Interface(ScriptConstants.PRICEFEED).latestRoundData();
        uint256 usd_decimals = AggregatorV3Interface(ScriptConstants.PRICEFEED).decimals();
        uint256 usdc_decimals = ERC20(ScriptConstants.USDC).decimals();
        uint256 wbtc_decimals = ERC20(ScriptConstants.cbBTC).decimals();
        wbtc_amt = Math.mulDiv(usd_amount, 10**(usd_decimals+wbtc_decimals), uint256(price)*10**(usdc_decimals));

    }
    

}
