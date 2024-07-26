// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MockLinkToken} from "@chainlink/contracts/src/v0.8/mocks/MockLinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 enteranceFee;
        uint256 interval;
        address vrfCoordinatorAddress; // RandomNumber provider address
        bytes32 gasLane; // keyhash from https://docs.chain.link/vrf/v2-5/supported-networks
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
    }

    NetworkConfig public i_activeNetworkConfig;

    uint256 private constant DEFAULT_ANVIL_KEY =
        0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;
    uint256 public constant ENTERANCE_FEE = 0.1 ether;
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

    function getSepoliaEthConfig() private view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                enteranceFee: ENTERANCE_FEE,
                interval: INTERNAL,
                vrfCoordinatorAddress: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 8994031556172742096443285160779108459213353806142790342698480270645491199446, // if 0, it will create one !!
                callbackGasLimit: 500000, // 500,000
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789, // https://docs.chain.link/resources/link-token-contracts
                deployerKey: vm.envUint("PRIVATE_KEY")
            });
    }

    function getAnvilEthConfig() private returns (NetworkConfig memory) {
        if (i_activeNetworkConfig.vrfCoordinatorAddress != address(0)) {
            return i_activeNetworkConfig;
        }
        // deploy the mock
        vm.startBroadcast();

        // vrf mock
        VRFCoordinatorV2_5Mock vrfMock = new VRFCoordinatorV2_5Mock(
            0.25 ether, // 0.25 LINK
            0.00001 ether,
            0.1 ether // 100000000 gwei per LINK
        );

        // link token mock
        MockLinkToken linkMock = new MockLinkToken();

        vm.stopBroadcast();

        return
            NetworkConfig({
                enteranceFee: 0.001 ether,
                interval: INTERNAL,
                vrfCoordinatorAddress: address(vrfMock), // mock need !
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 0,
                callbackGasLimit: 500000,
                link: address(linkMock), // mock need !
                deployerKey: DEFAULT_ANVIL_KEY
            });
    }
}
