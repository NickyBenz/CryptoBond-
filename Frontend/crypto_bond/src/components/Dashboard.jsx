import { useState, useEffect } from 'react';
import { BigNumber, ethers } from 'ethers';
import { useNavigate } from 'react-router-dom';
import {getUnixTime} from "date-fns"
import { useLocation } from 'react-router-dom';
import  {bondabi} from "../assets/BondABI.json";
import {tokenabi} from "../assets/TokenABI.json";
export default function Dashboard(){
    const navigate = useNavigate()
    const loc = useLocation();
    const wallet_address = loc.state
    const [bondContract, setBondContract] = useState()
    const [tokenContract, setTokenContract] = useState()
    const [hasDeposit, deposited] = useState(false)
    const bondContractAddress = "0x22f975329aaF60C97Fc8ADbe64db93B139CF1a71";
    const tokenAddress = '0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf'
    const [depositAmount, setDepositAmount] = useState(0)
    const [withdrawalAmount, setWithdrawal] = useState(0)
    const [maturity_date, setMaturity] = useState(0)
    const [message, setMessage] = useState("")
    const [name, setName] = useState("")
    const [address, setRecipientAddress] = useState("")
    const [current_balance, setBalance] = useState(0)
    const decimals = 8
    const [loading, setLoading] = useState(false)

    const initializeBondContract = async ()=>{
    if (window.ethereum) {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const signer = provider.getSigner();
        const bondContractInstance = new ethers.Contract(bondContractAddress, bondabi, signer);
        const tokenContractInstance = new ethers.Contract(tokenAddress, tokenabi, signer);
        setBondContract(bondContractInstance);
        setTokenContract(tokenContractInstance);
        await provider.send("eth_requestAccounts",[])
             }
        else{
            window.alert('MetaMask not detected');
        }


    }


   
    useEffect( ()=> {
        initializeBondContract();
    }, [])

    

    const depositSavings = async ()=>{
        if (typeof window.ethereum !== 'undefined') {
           const provider = new ethers.providers.Web3Provider(window.ethereum);
           const signer = provider.getSigner();
          

        try{
          const _gasLimit = ethers.utils.hexlify(1000000000)
          setLoading(true)
          const approvaltx = await tokenContract.functions.approve(bondContractAddress, ethers.utils.parseUnits(parseFloat(depositAmount).toString(), decimals),{gasLimit:_gasLimit})
          const deposittx = await bondContract.functions.depositSavings(ethers.utils.parseUnits(parseFloat(depositAmount).toString(), decimals ),
         getUnixTime(new Date(maturity_date)), address ,name, message,{gasLimit: _gasLimit})
         setLoading(true)
         const depositHash = deposittx.hash
         const depositReciept = await provider.waitForTransaction(depositHash)
         setLoading(false)
         depositReciept.status == 1? deposited(true) : navigate('/error')
        


        }catch(error){
          console.error(error)
          return <p>Error:Make sure all fields are filled</p>
        }
    }else{
      window.alert("Please install Metamask")
    }

  
  };

  const withdrawSavings = async ()=>{
        if (typeof window.ethereum !== 'undefined') {
           const provider = new ethers.providers.Web3Provider(window.ethereum);
           const signer = provider.getSigner();
       

        try{
          const withdrawaltx = bondContract.functions.withdrawSavings(BigNumber.from(withdrawalAmount))
          await withdrawaltx.wait()
          
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

        try{
          const currentBalance =await bondContract.functions.checkDepositAmount()
          const formattedBalance = currentBalance
          setBalance(formattedBalance)
          
        }catch(error){
          console.error(error)
        }
    }else{
      window.alert("Please install Metamask")
    }

  
  };



 

   return (
  <div>
    {!loading ? (
      !hasDeposit ? (
        <div>
          <h1>Welcome: {wallet_address}</h1>
          <br />
          <br />
          <button onClick={() => { navigate('/'); }}>Disconnect</button>

          <h3>Deposit Saving</h3>
          <button onClick={depositSavings}>Deposit Savings</button>
          <br />
          <h4>Set Deposit Amount</h4>
          <br />
          <input
            value={depositAmount}
            type='number'
            onChange={(e) => setDepositAmount(e.target.value)}
          />
          <br />
          <h4>Set Maturity Date</h4>
          <br />
          <input
            value={maturity_date}
            type='datetime-local'
            onChange={(e) => setMaturity(e.target.value)}
          />
          <br />
          <h4>Set Recipient Name</h4>
          <br />
          <input
            value={name}
            type='text'
            onChange={(e) => setName(e.target.value)}
            placeholder="Set recipient name"
          />
          <br />
          <h4>Set Recipient Address</h4>
          <br />
          <input
            value={address}
            type='text'
            onChange={(e) => setRecipientAddress(e.target.value)}
            placeholder="Set recipient address"
          />
          <br />
          <h4>Set Custom Message</h4>
          <br />
          <input
            value={message}
            type='text'
            onChange={(e) => setMessage(e.target.value)}
            placeholder="Set custom message"
          />
        </div>
      ) : (
        <div>
          <h1>Welcome {wallet_address}</h1>
          <br></br>
          <h2>See your bond status</h2>

          <h3>Current Deposit Amount</h3>
          <h3>Withdraw Saving</h3>
          <button onClick={withdrawSavings}>Withdraw Savings</button>
          <h4>Set Withdrawal Amount</h4>
          <br />
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
      )
    ) : (
      <div>
        <h1>Transaction processing...</h1>
      </div>
    )}
  </div>
);




}