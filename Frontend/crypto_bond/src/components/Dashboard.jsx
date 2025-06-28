import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useNavigate, useLocation } from 'react-router-dom';
import { getUnixTime } from 'date-fns';
import { bondabi } from '../assets/BondABI.json';
import { tokenabi } from '../assets/TokenABI.json';
export default function Dashboard() {
  const navigate = useNavigate();
  const location = useLocation();

  const [wallet_address, setWallet] = useState("");
  const [bondContract, setBondContract] = useState(null);
  const [tokenContract, setTokenContract] = useState(null);
  const [hasDeposit, setDeposited] = useState(false);
  const bondContractAddress = ''; 
  const tokenAddress = '0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf'; 
  const [depositAmount, setDepositAmount] = useState('');
  const [withdrawalAmount, setWithdrawal] = useState('');
  const [maturity_date, setMaturity] = useState('');
  const [message, setMessage] = useState('');
  const [name, setName] = useState('');
  const [address, setRecipientAddress] = useState('');
  const [current_balance, setBalance] = useState('0');
  const decimals = 8;
  const [loading, setLoading] = useState(false);
  const [maturityChecked, isdateChecked] = useState(false)
  const [balanceChecked, isbalancechecked] = useState(false)
  const initializeBondContract = async () => {


    let wallet = location.state
    if (!window.ethereum) {
      window.alert('MetaMask not detected');
      return;
    }
   
    setWallet(wallet)

    console.log(wallet_address)
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const network = await provider.getNetwork();
    if (network.chainId !== 8453) {
      window.alert('Please switch to Base network.');
      return;
    }
    const signer = provider.getSigner();
    const bondContractInstance = new ethers.Contract(bondContractAddress, bondabi, signer);
    const tokenContractInstance = new ethers.Contract(tokenAddress, tokenabi, signer);
    setBondContract(bondContractInstance);
    setTokenContract(tokenContractInstance);
    await provider.send('eth_requestAccounts', []);
    
  };


  useEffect(() => {
    initializeBondContract();
  }, []);

  const checkStatus = async () => {
      
    try {
      setLoading(true)
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      await provider.send('eth_requestAccounts', []);
      const signer = provider.getSigner();
      const walletAddress = await signer.getAddress();
      const isActive = await bondContract.isActive(walletAddress);
      console.log(isActive)
      setDeposited(isActive);
    } catch (error) {
      console.error('Error checking deposit status:', error);
    }finally{
      setLoading(false)
    }
  }

  const depositSavings = async () => {
    if (!window.ethereum) {
      window.alert('Please install MetaMask');
      return;
    }
    if (!bondContract || !tokenContract) {
      window.alert('Contracts not initialized. Please try again.');
      return;
    }
    if (!depositAmount || isNaN(depositAmount) || depositAmount <= 0) {
      window.alert('Please enter a valid deposit amount.');
      return;
    }
    if (!maturity_date) {
      window.alert('Please select a valid maturity date.');
      return;
    }
    if (!ethers.utils.isAddress(address)) {
      window.alert('Please enter a valid recipient address.');
      return;
    }
    if (!name || !message) {
      window.alert('Please fill in recipient name and message.');
      return;
    }
    const maturityTimestamp = getUnixTime(new Date(maturity_date));
    const currentTimestamp = Math.floor(Date.now() / 1000);
    if (maturityTimestamp <= currentTimestamp) {
      window.alert('Maturity date must be in the future.');
      return;
    }
    try {
      setLoading(true);
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      await provider.send('eth_requestAccounts', []);
      const signer = provider.getSigner();
      const walletAddress = await signer.getAddress();
      const depositAmountBN = ethers.utils.parseUnits(depositAmount.toString(), decimals);

      // Check balance
      const balance = await tokenContract.balanceOf(walletAddress);
      if (balance.lt(depositAmountBN)) {
        window.alert(`Insufficient WBTC balance. Available: ${ethers.utils.formatUnits(balance, decimals)} WBTC`);
        setLoading(false);
        return;
      }

      // Check if user already has a deposit
      const isActive = await bondContract.isActive(walletAddress);
      if (isActive) {
        window.alert('User already has an active deposit.');
        setLoading(false);
        return;
      }

      // Log current allowance
      const currentAllowance = await tokenContract.allowance(walletAddress, bondContractAddress);
      console.log('Current allowance:', ethers.utils.formatUnits(currentAllowance, decimals), 'WBTC');

      // Reset and set new allowance
      if (currentAllowance.gt(0)) {
        let gasLimitReset;
        try {
          gasLimitReset = await tokenContract.estimateGas.approve(bondContractAddress, 0);
        } catch (error) {
          console.error('Reset allowance gas estimation failed:', error);
          gasLimitReset = ethers.BigNumber.from('100000');
        }
        const resetTx = await tokenContract.approve(bondContractAddress, 0, {
          gasLimit: gasLimitReset.mul(120).div(100),
        });
        console.log('Reset allowance transaction:', resetTx.hash);
        await resetTx.wait();
      }

      // Approve new allowance
      let gasLimitApproval;
      try {
        gasLimitApproval = await tokenContract.estimateGas.approve(bondContractAddress, depositAmountBN);
        console.log('Estimated gas for approval:', gasLimitApproval.toString());
      } catch (error) {
        console.error('Approval gas estimation failed:', error);
        gasLimitApproval = ethers.BigNumber.from('100000');
        window.alert('Gas estimation for approval failed. Using fallback gas limit.');
      }
      const approvalTx = await tokenContract.approve(bondContractAddress, depositAmountBN, {
        gasLimit: gasLimitApproval.mul(120).div(100),
      });
      console.log('Approval transaction sent:', approvalTx.hash);
      const approvalReceipt = await approvalTx.wait();
      if (approvalReceipt.status !== 1) {
        window.alert('Approval transaction failed. Check BaseScan for details.');
        setLoading(false);
        return;
      }
      const newAllowance = await tokenContract.allowance(walletAddress, bondContractAddress);
      console.log('New allowance:', ethers.utils.formatUnits(newAllowance, decimals), 'WBTC');
      if (newAllowance.lt(depositAmountBN)) {
        window.alert('Allowance not set correctly. Please try again.');
        setLoading(false);
        return;
      }

      // Estimate gas for deposit
      let gasLimitDeposit;
      try {
        gasLimitDeposit = await bondContract.estimateGas.depositSavings(
          depositAmountBN,
          maturityTimestamp,
          address,
          name,
          message
        );
        console.log('Estimated gas for deposit:', gasLimitDeposit.toString());
      } catch (error) {
        console.error('Deposit gas estimation failed:', error);
        console.error('Revert reason:', error.reason || error.message);
        console.error('Error data:', error.data);
        gasLimitDeposit = ethers.BigNumber.from('1000000'); // Increased for Base
        window.alert('Gas estimation for deposit failed. Using fallback gas limit.');
      }

      // Deposit
      const depositTx = await bondContract.depositSavings(
        depositAmountBN,
        maturityTimestamp,
        address,
        name,
        message,
        {
          gasLimit: gasLimitDeposit.mul(120).div(100),
        }
      );
      console.log('Deposit transaction sent:', depositTx.hash);
      const depositReceipt = await depositTx.wait();

      if (depositReceipt.status === 1) {
        setDeposited(true);
        window.alert('Deposit successful!');
      } else {
        window.alert('Deposit transaction failed. Check BaseScan for details.');
        navigate('/error');
      }
    } catch (error) {
      console.error('Error details:', error);
      console.error('Error reason:', error.reason || error.message);
      console.error('Error data:', error.data);
      window.alert(`Error: ${error.reason || 'Transaction failed. Check console for details.'}`);
    } finally {
      setLoading(false);
    }
  };

  const withdrawSavings = async () => {
    if (!window.ethereum) {
      window.alert('Please install MetaMask');
      return;
    }
    if (!bondContract) {
      window.alert('Contract not initialized. Please try again.');
      return;
    }
    if (!withdrawalAmount || isNaN(withdrawalAmount) || withdrawalAmount <= 0) {
      window.alert('Please enter a valid withdrawal amount.');
      return;
    }
    try {
      setLoading(true);
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      await provider.send('eth_requestAccounts', []);
      const signer = provider.getSigner();
      const walletAddress = await signer.getAddress();
      const withdrawalAmountBN = ethers.utils.parseUnits(withdrawalAmount.toString(), decimals);

      // Check if user has an active deposit
      const isActive = await bondContract.isActive(walletAddress);
      if (!isActive) {
        window.alert('No active deposit found.');
        setLoading(false);
        return;
      }

      let gasLimit;
      try {
        gasLimit = await bondContract.estimateGas.withDrawSavings(withdrawalAmountBN);
        console.log('Estimated gas for withdrawal:', gasLimit.toString());
      } catch (error) {
        console.error('Withdraw gas estimation failed:', error);
        console.error('Revert reason:', error.reason || error.message);
        console.error('Error data:', error.data);
        gasLimit = ethers.BigNumber.from('1000000'); 
        window.alert('Gas estimation for withdrawal failed. Using fallback gas limit.');
      }

      const withdrawTx = await bondContract.withDrawSavings(withdrawalAmountBN, {
        gasLimit: gasLimit.mul(120).div(100),
      });
      console.log('Withdrawal transaction sent:', withdrawTx.hash);
      const withdrawReceipt = await withdrawTx.wait();

      if (withdrawReceipt.status === 1) {
        window.alert('Withdrawal successful!');
        setDeposited(false);
      } else {
        window.alert('Withdrawal transaction failed. Check BaseScan for details.');
        navigate('/error');
      }
    } catch (error) {
      console.error('Error details:', error);
      console.error('Error reason:', error.reason || error.message);
      console.error('Error data:', error.data);
      window.alert(`Error: ${error.reason || 'Withdrawal failed. Check console for details.'}`);
    } finally {
      setLoading(false);
    }
  };


  const balanceStatus = async () => {
    if (!window.ethereum) {
      window.alert('Please install MetaMask');
      return;
    }
    try {
      const balance = await bondContract.getDeposit(address);
      console.log(balance)
      const formattedBalance = ethers.utils.formatUnits(balance, decimals)
      setBalance(formattedBalance);
      isbalancechecked(true)
    } catch (error) {
      console.error('Error details:', error);
      console.error('Error reason:', error.reason);
      window.alert(`Error: ${error.reason || 'Failed to fetch balance.'}`);
    }
  };

  const get_maturity = async () => {
    if(!window.ethereum){
      window.alert("Please install metamask");
      return; 
    }
    try{
      const maturity = await bondContract.getMaturity(address);
      const formattedMaturity =  Date(maturity.toNumber() * 1000);
      const maturity_string = formattedMaturity.toLocaleString();
      setMaturity(maturity_string);
      isdateChecked(true)
    }catch(error){
      console.error("Error details:",error)
      console.error("Error reason:", error.reason)
      window.alert(`Error: ${error.reason || 'Failed to get maturity'}`)
    }
  }


  return (
    <div>
      {!loading ? (
        !hasDeposit ? (
          <div>
            <h1>Welcome: {wallet_address}</h1>
            <br />
            <br />
            <button onClick={() => navigate('/')}>Disconnect</button>
            <h3>Deposit Saving</h3>
            <button onClick={depositSavings}>Deposit Savings</button>
            <br />
            <h4>Set Deposit Amount</h4>
            <br />
            <input
              value={depositAmount}
              type="number"
              onChange={(e) => setDepositAmount(e.target.value)}
              placeholder="Enter deposit amount (WBTC)"
            />
            <br />
            <h4>Set Maturity Date</h4>
            <br />
            <input
              value={maturity_date}
              type="datetime-local"
              onChange={(e) => setMaturity(e.target.value)}
            />
            <br />
            <h4>Set Recipient Name</h4>
            <br />
            <input
              value={name}
              type="text"
              onChange={(e) => setName(e.target.value)}
              placeholder="Set recipient name"
            />
            <br />
            <h4>Set Recipient Address</h4>
            <br />
            <input
              value={address}
              type="text"
              onChange={(e) => setRecipientAddress(e.target.value)}
              placeholder="Set recipient address"
            />
            <br />
            <h4>Set Custom Message</h4>
            <br />
            <input
              value={message}
              type="text"
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Set custom message"
            />
            <br></br>
            <h4>Already Deposited?</h4>
            <button onClick={checkStatus}>Go to deposit</button>
          </div>
        ) : (
          <div>
            <h1>Welcome {wallet_address}</h1>
            <br />
            <h2>See your bond status</h2>
            <h3>Current Deposit Amount</h3>
            <h3>Withdraw Saving</h3>
            <button onClick={withdrawSavings}>Withdraw Savings</button>
            <h4>Set Withdrawal Amount</h4>
            <input
              value={withdrawalAmount}
              type="number"
              onChange={(e) => setWithdrawal(e.target.value)}
              placeholder="Set withdrawal amount"
            />
            <h3>Check Deposit Status</h3>
            <button onClick={balanceStatus}>Check Deposit</button>
  {balanceChecked?(<p>Balance: {current_balance} WBTC</p>
                  ):(<p>Click to check your balance  here!</p>)}
            <button onClick={get_maturity}>Check Maturity</button>
            {maturityChecked?( <p>Maturity: {maturity_date}</p>
                ):(<p>Click to check your maturity date here!</p>)}
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