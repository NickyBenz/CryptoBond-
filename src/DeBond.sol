// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


event HoldingCreated(address holder, uint256 depositAmount, uint256 maturity, uint256 tokenID); //Event to emit whenever a new user creates a bond holding
event SavingsWithdrawed(address holder, uint256 withdrawalAmount); //Event to emit whenever a user successfully withdraws from their hoding




import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {BondNFT} from "./BondNFT.sol";
import "lib/uniswap-v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {AggregatorV3Interface} from "../lib/chainlink-local/src/data-feeds/interfaces/AggregatorV3Interface.sol";
import {IPool} from "../lib/aave/contracts/interfaces/IPool.sol";
/// @title DeBond, crypto savings bond
/// @author Nikhil Bezwada
/// @notice Allows users to deposit WBTC tokens (after approving the contract) at a maturity with a fixed limit of $1000

contract DeBond {
    using Math for uint256;
    error CannotWithdrawBeforeMaturity(uint256 maturity); //Error to revert whenever a user attempts to withdraw from their bond before their maturity date
    error DepositOutOfRange(); //Error to revert when the user attempts to deposit above the max withdrawal rate
    error DepositExceedsAccountBalance(); //Error to revert when the user attemps to deposit a token balance higher than their own balance of the token
    error AlreadyDeposited(); //Error to revert if user has already deposited a savings bond 
    error WithdrawalExceedsDepositBalance(); //Error to revert when user requested withdrawal exceeds the amount they had initially deposited
    error NoDepositFound(); //Error to revert when a user tries to withdraw without a deposit
    error InvalidMaturity();
    uint256 constant MAXDEPOSITAMOUNT = 1e3;
    uint256 constant MINDEPOSITAMOUNT = 1e2;
    uint256 constant SCALER = 18;
    //Defined a custom struct to manage each user's holdings
    struct Holding{
        uint256 balance;
        uint256 maturity;
        uint256 tokenID;
    }

    //Maps each user address to their holdings struct
    mapping(address => Holding) s_holdings;

    //Mapping to check if the user has an active holding
    mapping(address => bool) s_isActive;

  

    //Stores the total value of deposits 
    uint256 s_totalDeposits; 
    
    BondNFT immutable i_bond_nft; //NFT attached to the bond 
    address immutable i_WBTC; //Wrapped BTC address
    address immutable i_price_feed; // BTC/USD price feed
    address immutable i_aave_pool; // AAVE pool address
    address immutable i_aWBTC; // AAVE Wrapped BTC address
    

    constructor(address wbtc, address price_feed, address aave_pool, address aWBTC){
        i_bond_nft = new BondNFT(address(this));
        i_WBTC = wbtc;
        i_price_feed = price_feed;
        i_aave_pool = aave_pool;
        i_aWBTC = aWBTC;
        s_totalDeposits = 0;
    }



    /// @notice Deposit WBTC tokens to the contract once contract has recieved token approval and stores them in an AAVE pool
    /// @param depositAmount Amount of WBTC tokens the user would like to deposit 
    /// @param maturity_date Timestamp at which the savings bond should allow the user to withdraw 
    /// Deposits cannot be made below $100 and above $1000.
    
    function depositSavings(uint256 depositAmount, uint256 maturity_date, string memory recipientName,string memory customMessage ) external {
            (uint256 usdDepositValue) = _getUSDAmount(depositAmount);

            if(s_isActive[msg.sender]){
                revert AlreadyDeposited();
            }else if(
                usdDepositValue > MAXDEPOSITAMOUNT || usdDepositValue < MINDEPOSITAMOUNT
            ){
                revert DepositOutOfRange();
            }else if(
                IERC20(i_WBTC).balanceOf(msg.sender) < depositAmount
            )
            {
                 revert DepositExceedsAccountBalance();
            }else if( maturity_date > block.timestamp){
                revert InvalidMaturity();
            }
            else{
                Holding memory userHolding = _createUserHolding(depositAmount, maturity_date,0);
                s_holdings[msg.sender] = userHolding;
                s_isActive[msg.sender] = true;
                s_totalDeposits += depositAmount;
                IERC20(i_WBTC).approve(i_aave_pool, depositAmount);
                IERC20(i_WBTC).transferFrom(msg.sender, address(this), depositAmount);
                IPool(i_aave_pool).supply(i_WBTC, depositAmount, address(this),0);
                uint256 _tokenID = i_bond_nft.mintNFT(msg.sender, recipientName, depositAmount, "WBTC", maturity_date, customMessage);
                s_holdings[msg.sender].tokenID = _tokenID;
                emit HoldingCreated(msg.sender, depositAmount, maturity_date, _tokenID);
            }

    }
    /// @notice Withdraw tokens from contract
    /// @param withdrawalAmount Amount of WBTC tokens the user would like to withdraw 
    /// Withdrawals cannot be made before maturity
    function withDrawSavings(uint256 withdrawalAmount) external {
            if(!(s_isActive[msg.sender])){
                revert NoDepositFound();
            }else{
                Holding memory userHolding = s_holdings[msg.sender];
                (uint256 userBalance, uint256 maturityTime) = (userHolding.balance, userHolding.maturity);
                if(withdrawalAmount > userBalance){
                    revert WithdrawalExceedsDepositBalance();
                }else if(maturityTime > _blockTimeStamp()){
                    revert CannotWithdrawBeforeMaturity(maturityTime);
                }else{
                    s_holdings[msg.sender].balance = userBalance - withdrawalAmount;
                    s_totalDeposits -= withdrawalAmount;
                    IPool(i_aave_pool).withdraw(i_WBTC, withdrawalAmount, address(this));
                    IERC20(i_WBTC).transfer(msg.sender, withdrawalAmount);
                    emit SavingsWithdrawed(msg.sender, withdrawalAmount);
                }
            }
    }


    /// @notice Gets the value of BTC in USD
    /// @param btc_amount  amount of BTC deposited
    /// @return usdAmt the corresponding value of USD
    function _getUSDAmount(uint256 btc_amount) internal view returns (uint256 usdAmt){
        (,int256 price,,,) = AggregatorV3Interface(i_price_feed).latestRoundData();
        uint256 btcDecimals = ERC20(i_WBTC).decimals();
        uint256 usdDecimals = uint256(AggregatorV3Interface(i_price_feed).decimals());
        uint256 scaled_btc_amount = btc_amount *(10**(SCALER));
        usdAmt = Math.mulDiv(scaled_btc_amount, (10**usdDecimals), uint256(price) * 10**(usdDecimals + btcDecimals));
        
 
    }

    function getTokenURI() public view  returns(string memory){
        if(!s_isActive[msg.sender]){
            revert NoDepositFound();
        }else{
            uint256 _tokenID = s_holdings[msg.sender].tokenID;
            return i_bond_nft.tokenURI(_tokenID);
        }
    }

    /// @notice Allows user to check deposit amount based on how much interest it has accrued from AAVE
    /// @return deposit_balance The value of the user's deposit
    function checkDepositAmount() external  returns(uint256 deposit_balance){
        if(!s_isActive[msg.sender]){
            revert NoDepositFound();
        }else{
            deposit_balance = _updateDepositAmount(msg.sender);
        
        }
    }

    /// @notice Updates the user balance based on the interest accrued from AAVE.
    /// @return deposit_balance The updatedvalue of the user's deposit
    function _updateDepositAmount(address holder) internal   returns(uint256 deposit_balance){
        if(!s_isActive[holder]){
            revert NoDepositFound();
        }else{
        uint256 current_balance = Math.mulDiv(_getAAVEBalance(holder),1,10**(SCALER));
        s_holdings[holder].balance = current_balance;
          deposit_balance =  s_holdings[holder].balance;
        
             
        }

    }   
    /// @notice Retrieves the updated user balance from AAVE.
    /// @return user_balance The updated value of the user's deposit
    function _getAAVEBalance(address holder) internal view returns(uint256 user_balance){
        if(s_isActive[holder]){
            uint256 user_deposit = s_holdings[holder].balance;
             uint256 totalAAVEBalance = IERC20(i_aWBTC).balanceOf(address(this));
             uint256 scaled_user_deposit = user_deposit * 10**(SCALER);
            user_balance = Math.mulDiv(scaled_user_deposit, totalAAVEBalance, s_totalDeposits);
        }else{  
            revert NoDepositFound();
        }
    }
    /// @notice Creates a new struct to represent a user's holdings
    /// @param depositAmount The amount the user has deposited
    /// @param maturityDate The maturity date chosen by the user
    function _createUserHolding(uint256 depositAmount, uint256 maturityDate, uint256 tokenID) internal pure returns(Holding memory){
        Holding memory newHolding = Holding(depositAmount, maturityDate, tokenID);
        return newHolding;
    }

    function _blockTimeStamp() internal view returns(uint256 timeStamp){
        return uint256(block.timestamp);
    }


/////////////////////////////////////   Getters     ///////////////////////////////////////////
    function _getIWBTC() external view returns(address){
        return i_WBTC;
    }

    function _getDecimals(address token_address) internal view returns (uint8 decimals) {
            return ERC20(token_address).decimals();
    }
     
    function getPriceFeed() external view returns(address){
        return i_price_feed;
    }
    
    function getAAVEPool() external view returns(address){
        return i_aave_pool;
    }

    function getAWBTC() external view returns (address){
        return i_aWBTC;
    }
}
