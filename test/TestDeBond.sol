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



    

}
