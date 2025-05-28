// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


event HoldingCreated(address holder, uint256 depositAmount, uint256 maturity); //Event to emit whenever a new user creates a bond holding
event SavingsWithdrawed(address holder, uint256 withdrawalAmount); //Event to emit whenever a user successfully withdraws from their hoding

error CannotWithdrawBeforeMaturity(uint256 maturity); //Error to revert whenever a user attempts to withdraw from their bond before their maturity date
error ExceededMaxUSDAmount(uint256 amount); //Error to revert when the user attempts to deposit above the max withdrawal rate
error DepositExceedsAccountBalance(); //Error to revert when the user attemps to deposit a token balance higher than their own balance of the token
error AlreadyDeposited(); //Error to revert if user has already deposited a savings bond 
error WithdrawalExceedsBalance(); //Error to revert when user requested withdrawal exceeds the amount they had initially deposited
error NoDepositFound(); //Error to revert when a user tries to withdraw without a deposit


import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/uniswap-v3-core/contracts/interfaces/IUniswapV3Pool.sol";
contract DeBond {
    address constant  WBTCUSDCPOOL = 0xfBB6Eed8e7aa03B138556eeDaF5D271A5E1e43ef; //Uniswap V3 USDC/cbBTC pool to retrieve price 
    address constant cbBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    uint256 constant MAXDEPOSITAMOUNT = 1000;
    //Defined a custom struct to manage each user's holdings
    struct Holding{
        uint256 balance;
        uint256 maturity;
    }

    //Maps each user address to their holdings struct
    mapping(address => Holding) s_holdings;

    //Mapping to check if the user has an active holding
    mapping(address => bool) s_isActive;
    
 


    function depositSavings(uint256 depositAmount, uint256 maturity_date ) external {
            if(s_isActive[msg.sender]){
                revert AlreadyDeposited();
            }else if(
                depositAmount > MAXDEPOSITAMOUNT
            ){
                revert ExceededMaxUSDAmount(depositAmount);
            }else if(
                IERC20(cbBTC).balanceOf(msg.sender) < depositAmount
            )
            {
                 revert DepositExceedsAccountBalance();
            }
            else{
                Holding memory userHolding = _createUserHolding(depositAmount, maturity_date);
                s_holdings[msg.sender] = userHolding;
                s_isActive[msg.sender] = true;
                IERC20(cbBTC).transferFrom(msg.sender, address(this), depositAmount);
                emit HoldingCreated(msg.sender, depositAmount, maturity_date);
            }

    }

    function withDrawSavings(uint256 withdrawalAmount) external {
            if(!(s_isActive[msg.sender])){
                revert NoDepositFound();
            }else{
                Holding memory userHolding = s_holdings[msg.sender];
                (uint256 userBalance, uint256 maturityTime) = (userHolding.balance, userHolding.maturity);
                if(withdrawalAmount > userBalance){
                    revert WithdrawalExceedsBalance();
                }else if(maturityTime > _blockTimeStamp()){
                    revert CannotWithdrawBeforeMaturity(maturityTime);
                }else{
                    s_holdings[msg.sender].balance = userBalance - withdrawalAmount;
                    IERC20(cbBTC).transfer(msg.sender, withdrawalAmount);
                    emit SavingsWithdrawed(msg.sender, withdrawalAmount);
                }
            }
    }



    function _getUSDAmount(uint256 btc_amount) internal view returns (uint256 usdAmt){
        (uint160 sqrtPriceX96,,,,,, ) = IUniswapV3Pool(WBTCUSDCPOOL).slot0(); //Retrieves the current spot price from the USDC/cbBTC pool on UniswapV3
        //Convert the price into a readable price 
        //Price = sqrtPriceX96^2 /(2^192)

        uint256 formatted_price = (sqrtPriceX96 * sqrtPriceX96)/(2**192); 
        //Retrieve the decimals from the USDC token contract
        uint8 usdDecimals = _getDecimals(USDC); 
        uint8 btcDecimals = _getDecimals(cbBTC);
        uint256 scaledBtcAmount = btc_amount * (10 ** (usdDecimals - btcDecimals)); //Gets the BTC amount in terms of USDC decimals
        usdAmt = scaledBtcAmount * formatted_price * (10 ** uint256(usdDecimals));  

    }

    function _createUserHolding(uint256 depositAmount, uint256 maturityDate) internal pure returns(Holding memory){
        Holding memory newHolding = Holding(depositAmount, maturityDate);
        return newHolding;
    }

    function _blockTimeStamp() internal view returns(uint256 timeStamp){
        return uint256(block.timestamp);
    }

    function _getDecimals(address token_address) internal view returns (uint8 decimals) {
            return ERC20(token_address).decimals();
    }


}
