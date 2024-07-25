// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle Contract
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFV2
 */
contract Raffle {
    error Raffle__NotEnoughETHSent();

    /** state variables **/
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint16 private constant NUM_WORDS = 1;

    uint256 private immutable i_enteranceFee;
    // @dev Duration of the lottety in seconds
    uint256 private immutable i_interval;
    // randrom number generator
    address private immutable i_vrfCoordinator;
    address private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimestamp;

    /** Events **/

    event EnteredRaffle(address indexed player);

    constructor(
        uint256 enteramceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane, // keyhash from https://docs.chain.link/vrf/v2-5/supported-networks
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) {
        i_enteranceFee = enteramceFee;
        i_interval = interval;
        i_vrfCoordinator = vrfCoordinator;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimestamp = block.timestamp;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_enteranceFee, "Not enough ETH sent!");
        // save gas way using custom error
        if (msg.value >= i_enteranceFee) {
            revert Raffle__NotEnoughETHSent();
        }
        s_players.push(payable(msg.sender));

        // 1. Makes migration easiser
        // 2. Makes front end "indexing" easier
        emit EnteredRaffle(msg.sender);
    }

    // 1. Get a random number
    // 2. Use the random number to pick a player
    // 3. Be automatically called
    function pickWinner() external {
        // check to see if enough time has passed
        if (block.timestamp - s_lastTimestamp < i_interval) {
            revert();
        }
        // from SubscriptionConsumer.sol  https://docs.chain.link/vrf/v2-5/subscription/get-a-random-number
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false}) // true: ETH false: LINK
                )
            })
        );
    }

    /** Getter Function  */
    function getEnteranceFee() public view returns (uint256) {
        return i_enteranceFee;
    }
}
