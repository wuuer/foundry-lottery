-include .env

fundSubcription-sepolia:; forge script ./script/Interactions.s.sol:FundSubscription --rpc-url ${SEPOLIA_RPC_URL} --private-key ${PRIVATE_KEY} --broadcast