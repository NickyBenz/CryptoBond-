# Crypto Legacy Bond


## Overview
Crypto Legacy Bond is an innovative blockchain-based savings vehicle. This unique product recognizes the absence of similar offerings in the market and aims to provide a secure and meaningful way to save cryptocurrencies.

## Features
Time-Locked Smart Contracts: Users can lock cryptocurrencies (WBTC, ETH, USDC, USDT) in a smart contract on Base L2 (Ethereum layer-2) until a customizable maturity date. Withdrawals or sales are prohibited before maturity, ensuring the funds are preserved for their intended purpose.

## Contract Functions

- makeDeposit: This function takes a balance and maturity from the user for their tokens to create and store a holding 
- withDraw: If the holding is past maturity, the user is allowed to withdraw from their holding
- _getUSDAmount(): Internal function accessing the WBTC/USDT pool to check the USD value of the pool, ensuring it works.

