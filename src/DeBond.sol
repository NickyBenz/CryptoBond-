// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


event HoldingCreated(address holder, uint256 depositAmount, uint256 maturity); //Event to emit whenever a new user creates a bond holding
event SavingsWithdrawed(address holder, uint256 withdrawalAmount); //Event to emit whenever a user successfully withdraws from their hoding




import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/uniswap-v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {AggregatorV3Interface} from "../lib/chainlink-local/src/data-feeds/interfaces/AggregatorV3Interface.sol";

/// @title DeBond, crypto savings bond
/// @author Nikhil Bezwada
/// @notice Allows users to deposit WBTC tokens (after approving the contract) at a maturity with a fixed limit of $1000

contract DeBond {
    error CannotWithdrawBeforeMaturity(uint256 maturity); //Error to revert whenever a user attempts to withdraw from their bond before their maturity date
    error ExceededMaxUSDAmount(); //Error to revert when the user attempts to deposit above the max withdrawal rate
    error DepositExceedsAccountBalance(); //Error to revert when the user attemps to deposit a token balance higher than their own balance of the token
    error AlreadyDeposited(); //Error to revert if user has already deposited a savings bond 
    error WithdrawalExceedsBalance(); //Error to revert when user requested withdrawal exceeds the amount they had initially deposited
    error NoDepositFound(); //Error to revert when a user tries to withdraw without a deposit   
    uint256 constant MAXDEPOSITAMOUNT = 1e3;
    uint256 constant SCALER = 18;
    //Defined a custom struct to manage each user's holdings
    struct Holding{
        uint256 balance;
        uint256 maturity;
    }

    //Maps each user address to their holdings struct
    mapping(address => Holding) s_holdings;

    //Mapping to check if the user has an active holding
    mapping(address => bool) s_isActive;
    
    address constant cbBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf; //Coinbase Wrapped BTC (cbBTC) address for base
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; //USDC address for base 
    address constant usdc_btc_aggregator = 0x64c911996D3c6aC71f9b455B1E8E7266BcbD848F;

    /// @notice Deposit WBTC tokens to the contract once contract has recieved approval
    /// @param depositAmount Amount of WBTC tokens the user would like to deposit 
    /// @param maturity_date Timestamp at which the savings bond should allow the user to withdraw 
    function depositSavings(uint256 depositAmount, uint256 maturity_date ) external {
            (uint256 usdDepositValue) = _getUSDAmount(depositAmount);

            if(s_isActive[msg.sender]){
                revert AlreadyDeposited();
            }else if(
                usdDepositValue > MAXDEPOSITAMOUNT
            ){
                revert ExceededMaxUSDAmount();
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
    /// @notice Withdraw tokens from contract
    /// @param withdrawalAmount Amount of WBTC tokens the user would like to withdraw 
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



    function _getUSDAmount(uint256 btc_amount) public view returns (uint256 usdAmt){
        (,int256 price,,,) = AggregatorV3Interface(usdc_btc_aggregator).latestRoundData();
        uint256 btcDecimals = ERC20(cbBTC).decimals();
        uint256 usdDecimals = uint256(AggregatorV3Interface(usdc_btc_aggregator).decimals());
        uint256 scaled_btc_amount = btc_amount *(10**(SCALER));
        usdAmt = Math.mulDiv(scaled_btc_amount, (10**usdDecimals), uint256(price) * 10**(usdDecimals + btcDecimals));
        
 
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
