import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ethers } from 'ethers';

export default function HomePage(){
  const [isConnected, setIsConnected] = useState(false); //State variable storing whether or not metamask is installed 
  const [account, setAccount] = useState(''); //Sets the current Ethereum account 
  const [provider, setProvider] = useState(null); //Sets the HTTP provider 
  const [chain, setChain] = useState(''); //Sets the chain ID 
  const navigate = useNavigate(); 
  const isMetaMaskInstalled = () => {
    return typeof window.ethereum !== 'undefined'; //Checks if metamask is installed or not
  };

  const connectToMetaMask = async () => {
    if (!isMetaMaskInstalled()) {
      alert('Please install MetaMask first!'); //Tells user to connect metamask 
      return;
    }

     try {
      const accounts = await window.ethereum.request({ 
        method: 'eth_requestAccounts' //Requests the metamask 
      });
      
      const provider = new ethers.getDefaultProvider("https://eth-mainnet.g.alchemy.com/v2/l9uW6evddktHwzEm4qTmS"); //Gets a HTTP provider from the brower  
      const network = await provider.getNetwork(); //Gets the current chain 
      
      setAccount(accounts[0]); //Gets the first account 
      setIsConnected(true); //Sets the state to connected 
      setProvider(provider); //Sets the HTTP provider to the browser 
      network.chainId == 1 ? setChain("ETH Main-Net") : setChain("ETH L2")

      window.ethereum.on('accountsChanged', handleAccountsChanged); //
      window.ethereum.on('chainConfigured', handleChainChanged);


    } catch (error) {
      console.error('Error connecting to MetaMask:', error);
    }
  }

    const handleAccountsChanged = (accounts) => {
    if (accounts.length === 0) { //If no accounts then connection is false 
      setIsConnected(false);
      setAccount('');
    } else {
      setAccount(accounts[0]); //Otherwise sets the account 
    }
  };

  const handleChainChanged = () => {
    window.location.reload(); //Reloads if chain does not work  
  };


   const disconnect = () => {
    setIsConnected(false);
    setAccount('');
    setProvider(null);
    setChain('');

    // Remove event listeners
    if (window.ethereum) {
      window.ethereum.removeListener('accountsChanged', handleAccountsChanged);
      window.ethereum.removeListener('chainChanged', handleChainChanged);
    }
  };

  // Clean up on unmount
  useEffect(() => {
    return () => {
      if (window.ethereum) {
        window.ethereum.removeListener('accountsChanged', handleAccountsChanged);
        window.ethereum.removeListener('chainChanged', handleChainChanged);
      }
    };
    }, []);



      return (
    <div className="home-page">
      <h1>Crypto Savings Bond</h1>
      
      {!isConnected ? (
        <button onClick={connectToMetaMask} className="connect-button">
          Connect Wallet 
        </button>
      ) : (
        <div className="wallet-info">
          <p>Connected Account: {account}</p>
          <p>Chain ID: {chain}</p>
          <button onClick={disconnect} className="disconnect-button">
            Disconnect
          </button>
          <button onClick={
            ()=>{navigate('/dashboard',{state:account})}
          }>Go to Dashboard</button>
        </div>
      )}
    </div>
  );
};


