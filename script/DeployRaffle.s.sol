// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription} from "./Interactions.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle) {
        HelperConfig config = new HelperConfig();
        (
            uint256 enteranceFee,
            uint256 interval,
            address vrfCoordinatorAddress,
            bytes32 gasLane,
            uint256 subscriptionId,
            uint32 callbackGasLimit,
            address linkAddress,
            uint256 deployerKey
        ) = config.i_activeNetworkConfig();

        // subscriptionId = 0 when it is deployed in anvil network
        // Or you pass 0 to subscriptionId in HelperConfig
        if (subscriptionId == 0) {
            // https://vrf.chain.link/sepolia/new
            // create vrf subscription
            CreateSubscription createSubscription = new CreateSubscription();
            uint256 subId = createSubscription.createSubscription(
                vrfCoordinatorAddress,
                deployerKey
            );
            // fund the subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                subId,
                vrfCoordinatorAddress,
                linkAddress,
                deployerKey
            );

            subscriptionId = subId;
        }

        console.log("Deploying Raffle ...");
        vm.startBroadcast(); // use the default signer to deploy
        Raffle raffle = new Raffle(
            enteranceFee,
            interval,
            vrfCoordinatorAddress,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();
        console.log("Raffle address: ", address(raffle));

        // not in mainnet
        if (block.chainid != 1) {
            // add consumer to subscription
            AddConsumer add = new AddConsumer();
            add.addConsumer(
                subscriptionId,
                vrfCoordinatorAddress,
                address(raffle),
                deployerKey
            );
        }

        return raffle;
    }
}
