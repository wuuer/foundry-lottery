// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MockLinkToken} from "@chainlink/contracts/src/v0.8/mocks/MockLinkToken.sol";
import {DeployRaffle} from "./DeployRaffle.s.sol";
import {Raffle} from "../src/Raffle.sol";

import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingHelperConfig() internal returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinatorAddress,
            ,
            ,
            ,
            ,
            uint256 deployerKey
        ) = helperConfig.i_activeNetworkConfig();
        return createSubscription(vrfCoordinatorAddress, deployerKey);
    }

    function createSubscription(
        address vrfCoordinatorAddress,
        uint256 deployerKey
    ) public returns (uint256) {
        console.log("Creating subscription on ChainId :", block.chainid);
        vm.startBroadcast(deployerKey);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinatorAddress)
            .createSubscription();
        vm.stopBroadcast();
        console.log("your subscriptionId is ", subId);
        return subId;
    }

    function run() external {
        createSubscriptionUsingHelperConfig();
    }
}

contract FundSubscription is Script {
    uint256 private constant FUND_AMOUNT = 50 ether;

    function fundSubscriptionUsingHelperConfig() internal {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinatorAddress,
            ,
            uint256 subId,
            ,
            address link,
            uint256 deployerKey
        ) = helperConfig.i_activeNetworkConfig();

        fundSubscription(subId, vrfCoordinatorAddress, link, deployerKey);
    }

    function fundSubscription(
        uint256 subId,
        address vrfCoordinatorAddress,
        address linkAddress,
        uint256 deployerKey
    ) public {
        console.log("funding subscription on ChainId :", block.chainid);
        console.log("using  vrfCoordinatorAddress :", vrfCoordinatorAddress);
        console.log("using  subscriptionId:", subId);
        vm.startBroadcast(deployerKey);
        // anvil local testnet
        if (block.chainid == 31337) {
            VRFCoordinatorV2_5Mock(vrfCoordinatorAddress).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            // sepolia testnet
        } else if (block.chainid == 11155111) {
            MockLinkToken(linkAddress).transferAndCall(
                vrfCoordinatorAddress,
                FUND_AMOUNT,
                abi.encode(subId)
            );
        }
        vm.stopBroadcast();
    }

    function run() external {
        fundSubscriptionUsingHelperConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingHelperConfig(address raffle) internal {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinatorAddress,
            ,
            uint256 subId,
            ,
            ,
            uint256 deployerKey
        ) = helperConfig.i_activeNetworkConfig();

        addConsumer(subId, vrfCoordinatorAddress, raffle, deployerKey);
    }

    function addConsumer(
        uint256 subId,
        address vrfCoordinatorAddress,
        address raffle,
        uint256 deployerKey
    ) public {
        console.log("adding consumer on subId :", subId);
        console.log("using  vrfCoordinatorAddress :", vrfCoordinatorAddress);
        console.log("on chainId:", block.chainid);

        vm.startBroadcast(deployerKey); // use deployerKey to deploy

        VRFCoordinatorV2_5Mock(vrfCoordinatorAddress).addConsumer(
            subId,
            raffle
        );
        vm.stopBroadcast();
    }

    function run() external {
        // DeployRaffle deploy = new DeployRaffle();
        // vm.startBroadcast();
        // Raffle raffle = deploy.run();
        // vm.stopBroadcast();

        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );

        addConsumerUsingHelperConfig(address(mostRecentlyDeployed));
    }
}
