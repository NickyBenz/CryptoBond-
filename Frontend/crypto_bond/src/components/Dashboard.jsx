import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useNavigate } from 'react-router-dom';
import {getUnixTime} from "date-fns"
import { useLocation } from 'react-router-dom';
import  {bondabi} from "../assets/BondABI.json";
import {tokenabi} from "../assets/TokenABI.json";
import {abi} from "../assets/TokenABI.json";
export default function Dashboard(){
    const navigate = useNavigate()
    const loc = useLocation();
    const wallet_address = loc.state
    const [contract, setContract] = useState('')
    const [hasDeposit, setDeposit] = useState('')
    const contractAddress = "";
    const [depositAmount, setDepositAmount] = useState(0)
    const [withdrawalAmount, setWithdrawal] = useState(0)
    const [maturity_date, setMaturity] = useState(0)
    const [message, setMessage] = useState("")
    const [name, setName] = useState("")
    const [current_balance, setBalance] = useState(0)

    bondContractAddress = ''
    tokenAddress = ''
  


    const initializeBondContract = async ()=>{
    if (window.ethereum) {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const signer = provider.getSigner();
        const bondContract = new ethers.Contract(bondContractAddress, abi, signer);
        const tokenContractInstance = new ethers.Contract(tokenAddress, tokenabi, signer);
        setContract(contractInstance);
        await provider.send("eth_requestAccounts",[])
             }
        else{
            window.alert('MetaMask not detected');
        }
    }

    useEffect(()=>{
        initializeBondContract();
        
    }, [])



    const depositSavings = async ()=>{
        if (typeof window.ethereum !== 'undefined') {
           const provider = new ethers.providers.Web3Provider(window.ethereum);
           const signer = provider.getSigner();
          const contract = new ethers.Contract(
        'contract_address', // Replace with your contract address
        abi,
        signer
      );

        try{
          const approvaltx = tokenContractInstance.functions.approve(bondContractAddress, ethers.BigNumber(depositAmount))
          const tx = contract.functions.depositSavings(ethers.BigNumber.from(depositAmount), getUnixTime(new Date(maturity_date)), name, message)
          await tx.wait()

        }catch(error){
          console.error(error)
        }
    }else{
      window.alert("Please install Metamask")
    }

  
  };

  const withdrawSavings = async ()=>{
        if (typeof window.ethereum !== 'undefined') {
           const provider = new ethers.providers.Web3Provider(window.ethereum);
           const signer = provider.getSigner();
          const contract = new ethers.Contract(
        'contract_address', // Replace with your contract address
        abi,
        signer
      );

        try{
          const tx = contract.functions.withdrawSavings(ethers.BigNumber.from(withdrawalAmount))
          await tx.wait()
          
        }catch(error){
          console.error(error)
        }
    }else{
      window.alert("Please install Metamask")
    }
  }
   const balanceStatus = async ()=>{
        if (typeof window.ethereum !== 'undefined') {
           const provider = new ethers.providers.Web3Provider(window.ethereum);
           const signer = provider.getSigner();
          const contract = new ethers.Contract(
        'contract_address', // Replace with your contract address
        abi,
        signer
      );

        try{
          const currentBalance =await contract.functions.checkDepositAmount()
          const formattedBalance = currentBalance.toNumber()
          setBalance(formattedBalance)
          
        }catch(error){
          console.error(error)
        }
    }else{
      window.alert("Please install Metamask")
    }

  
  };



 

    return(
      <div>


      <h1>Welcome: {wallet_address}</h1>
                       <br></br>
                       <h2>See your bond status</h2>
                       <br></br>
            <button onClick={()=>{navigate('/')}}>Disconnect</button>


            {!hasDeposit ? (
  <div>
    <h3>Deposit Saving</h3>
    <button onClick={depositSavings}>Deposit Savings</button>
    <br></br>
    <input
      value={depositAmount}
      type='number'
      onChange={(e) => setDepositAmount(e.target.value)}
      placeholder="Set deposit amount"
    />
    <br></br>
    <input
      value={maturity_date}
      type='datetime-local'
      onChange={(e) => setMaturity(e.target.value)}
      placeholder="Set maturity date"
    />
    <br></br>
      <input
      value={name}
      type='text'
      onChange={(e) => setName(e.target.value)}
      placeholder="Set recipient name"
    />
    <br></br>
     <input
      value={message}
      type='text'
      onChange={(e) => setMessage(e.target.value)}
      placeholder="Set recipient name"
    />          


  </div>
) : (
  <div>


    



    <h3>Withdraw Saving</h3>
    <button onClick={withdrawSavings}>Withdraw Savings</button>

    <input
      value={withdrawalAmount} 
      type='number'
      onChange={(e) => setWithdrawal(e.target.value)}
      placeholder="Set withdrawal amount"
    />


    <h3>Check Deposit Status</h3>
          <button onClick={balanceStatus}>Check Deposit</button>
          <p>Balance: {current_balance} WBTC</p>
     


  </div>
)}
            




      </div>


           

           
            
            
            
            


          )

        





}