// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Script} from "lib/forge-std/src/Script.sol";


library CHAIN_DATA{
    ///BASE-MAIN-NET
    uint256 constant BASE_CHAIN_ID = 8453;
    address constant BASE_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; //USDC address for base 
    address constant BASE_cbBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf; //Coinbase Wrapped BTC (cbBTC) address for base
    address constant BASE_cBBTCWHALE = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb; //Whale address to fork with on Bbase 
    address constant BASE_PRICEFEED = 0x64c911996D3c6aC71f9b455B1E8E7266BcbD848F;
    address constant BASE_AAVE_POOL = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;
    address constant BASE_aCBBTC = 0xBdb9300b7CDE636d9cD4AFF00f6F009fFBBc8EE6;

    //BASE_SEPOLIA_MAIN_NET
    

    ///MAIN-NET
    uint256 constant MAIN_NET_CHAINID = 1;
    address constant MAIN_NET_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant MAIN_NET_WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant MAIN_NET_WHALE = 0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8;
    address constant MAIN_NET_AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant MAIN_NET_PRICEFEED = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;
    address constant MAIN_NET_aWBTC = 0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8;

    ///OPTIMISM
    uint256 constant OPTIMISM_CHAINID = 10;
    address constant OPTIMISM_USDC = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;
    address constant OPTIMISM_WBTC = 0x68f180fcCe6836688e9084f035309E29Bf0A2095;
    address constant OPTIMISM_WHALE = 0x078f358208685046a11C85e8ad32895DED33A249;
    address constant OPTIMISM_AAVE_POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    address constant OPTIMISM_PRICEFEED = 0xD702DD976Fb76Fffc2D3963D037dfDae5b04E593;
    address constant OPTIMISM_aWBTC = 0x078f358208685046a11C85e8ad32895DED33A249;



}

contract HelperConfig is Script{


    struct ChainConfig{
        address wbtc;
        address usdc; 
        address whale;
        address aave_pool;
        address price_feed;
        address awbtc;
    }

    ChainConfig public config; 

    function setActiveConfig() public {
        if(block.chainid == CHAIN_DATA.MAIN_NET_CHAINID){
            config = getMainNetConfig();
        }else if(block.chainid == CHAIN_DATA.BASE_CHAIN_ID){
            config = getBaseConfig();
        }else{
            config = getOptimismConfig();
        }
        
    }

    function getBaseConfig() public pure returns (ChainConfig memory){
        return ChainConfig(
            CHAIN_DATA.BASE_cbBTC,
            CHAIN_DATA.BASE_USDC,
            CHAIN_DATA.BASE_cBBTCWHALE,
            CHAIN_DATA.BASE_AAVE_POOL,
            CHAIN_DATA.BASE_PRICEFEED,
            CHAIN_DATA.BASE_aCBBTC
        );
    }

    function getOptimismConfig() public pure returns (ChainConfig memory){
        return ChainConfig(
            CHAIN_DATA.OPTIMISM_WBTC,
            CHAIN_DATA.OPTIMISM_USDC,
            CHAIN_DATA.OPTIMISM_WHALE,
            CHAIN_DATA.OPTIMISM_AAVE_POOL,
            CHAIN_DATA.OPTIMISM_PRICEFEED,
            CHAIN_DATA.OPTIMISM_aWBTC
        );
    }

    function getMainNetConfig() public pure returns (ChainConfig memory){
            return ChainConfig(
            CHAIN_DATA.MAIN_NET_WBTC,
            CHAIN_DATA.MAIN_NET_USDC,
            CHAIN_DATA.MAIN_NET_WHALE,
            CHAIN_DATA.MAIN_NET_AAVE_POOL,
            CHAIN_DATA.MAIN_NET_PRICEFEED,
            CHAIN_DATA.MAIN_NET_aWBTC
        );
    }





}