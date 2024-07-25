// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 enteranceFee;
        uint256 interval;
        address vrfCoordinatorAddress; // RandomNumber provider address
        bytes32 gasLane; // keyhash from https://docs.chain.link/vrf/v2-5/supported-networks
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }

    NetworkConfig public i_activeNetworkConfig;

    uint256 public constant ENTERANCE_FEE = 1 ether;
    uint256 public constant INTERNAL = 30; // seconds

    constructor() {
        // sepolia online testnet
        if (block.chainid == 11155111) {
            i_activeNetworkConfig = getSepoliaEthConfig();
        }
        // anvil local testnet
        else {
            i_activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() private pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                enteranceFee: ENTERANCE_FEE,
                interval: INTERNAL,
                vrfCoordinatorAddress: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 8994031556172742096443285160779108459213353806142790342698480270645491199446,
                callbackGasLimit: 40000 // 40,000
            });
    }

    function getAnvilEthConfig() private returns (NetworkConfig memory) {
        if (i_activeNetworkConfig.vrfCoordinatorAddress != address(0)) {
            return i_activeNetworkConfig;
        }
        // deploy the mock
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfMock = new VRFCoordinatorV2_5Mock(
            0.25 ether, // 0.25 LINK
            1,
            1e9 // 1 gwei LINK
        );
        vm.stopBroadcast();

        return
            NetworkConfig({
                enteranceFee: 0.001 ether,
                interval: INTERNAL,
                vrfCoordinatorAddress: address(vrfMock),
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 8994031556172742096443285160779108459213353806142790342698480270645491199446,
                callbackGasLimit: 40000
            });
    }
}
