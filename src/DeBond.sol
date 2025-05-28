// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


event HoldingCreated(address, uint256, uint256); //Event to emit whenever a new user creates a bond holding
event SavingsWithdrawed(address, uint256); //Event to emit whenever a user successfully withdraws from their hoding

error CannotWithdrawBeforeMaturity(uint256 maturity); //Error to revert whenever a user attempts to withdraw from their bond before their maturity date
error ExceededMaxUSDAmount(uint256 amount); //Error to emit when the user attempts to deposit above the max withdrawal rate


import {ERC20,IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV3Pool} from "@uniswapv3/contracts/interfaces/IUniswapV3Pool.sol";

contract DeBond {
    address constant  WBTCUSDCPOOL = 0xfBB6Eed8e7aa03B138556eeDaF5D271A5E1e43ef;
    address constant cbBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    uint256 constant MAXDEPOSITAMOUNT = 1000;
    //Defined a custom struct to manage each user's holdings
    struct Holdings{
        uint256 balance;
        uint256 maturity;
    }

    //Maps each user address to their holdings struct
    mapping(address => Holdings) s_holdings;

    //Mapping to check if the user has an active holding
    mapping(address => bool) s_isActive;

    
    function _getUSDAmount(uint256 btc_amount) internal view returns (uint256 usdAmt){
        (uint160 sqrtPriceX96,,,,,, ) = IUniswapV3Pool(WBTCUSDCPOOL).slot0(); //Retrieves the current spot price from the USDC/cbBTC pool on UniswapV3
        //Convert the price into a readable price 
        //Price = sqrtPriceX96^2 /(2^192)
        uint256 formatted_price = (sqrtPriceX96 * sqrtPriceX96)/(2**192); 
        //Retrieve the decimals from the USDC token contract
        uint8 usdDecimals = ERC20(USDC).decimals(); 

        usdAmt = formatted_price * (10 ** uint256(usdDecimals));

    }

}
