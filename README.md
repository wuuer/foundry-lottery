# Proveably Random Raffle Contracts

## About

This code is to create a proveably random smart contract lottery.

## What we want it to do ?

1. Users can enter by paying for a ticket
   1. The ticket fees are going to go to the winner during the draw
2. After X period of time , the lottery will automatically draw a winner
   1. And this will be done programatically
3. Using Chainlink VRF & Chainlink Automation
   1. Chainlink VRF --> Randomness
   2. Chainlink Automation --? Time based trigger

## Tests !

1. write some deploy scripts
2. Write our tests

   setup environment variables

   ```bash
   source .env
   ```

   test on a local chain

   ```bash
   forge test
   ```

   test on a forked Testnet

   ```bash
   forge test --fork-url $SEPOLIA_RPC_URL
   ```

   3. Forked mainnet
