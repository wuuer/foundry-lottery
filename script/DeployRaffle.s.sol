// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle) {
        HelperConfig config = new HelperConfig();

        (
            uint256 enteranceFee,
            uint256 interval,
            address vrfCoordinatorAddress,
            bytes32 gasLane,
            uint256 subscriptionId,
            uint32 callbackGasLimit
        ) = config.i_activeNetworkConfig();

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
        return raffle;
    }
}
