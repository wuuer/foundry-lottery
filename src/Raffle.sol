// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {console} from "forge-std/Test.sol";

/**
 * @title A sample Raffle Contract
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFV2
 */
// from SubscriptionConsumer.sol  https://docs.chain.link/vrf/v2-5/subscription/get-a-random-number
contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle__NotEnoughETHSent();
    error Raffle__RaffleNotOpen();
    error Raffle__TransferFailed();
    error Raffle__UpKeepNotNeeded(
        uint256 currentBalance,
        uint256 numOfPlayers,
        uint256 RaffleState
    );

    /** type declaraction**/
    enum RaffleState {
        OPEN,
        CALCUATING
    }

    /** state variables **/
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint16 private constant NUM_WORDS = 1;

    uint256 private immutable i_enteranceFee;
    // @dev Duration of the lottety in seconds
    uint256 private immutable i_interval;

    bytes32 private immutable i_gasLane;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /** Events **/

    event EnteredRaffle(address indexed player);
    event Pickedwinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 enteramceFee,
        uint256 interval,
        address vrfCoordinatorAddress,
        bytes32 gasLane, // keyhash from https://docs.chain.link/vrf/v2-5/supported-networks
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinatorAddress) {
        i_enteranceFee = enteramceFee;
        i_interval = interval;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_enteranceFee, "Not enough ETH sent!");
        // save gas way using custom error
        if (msg.value < i_enteranceFee) {
            revert Raffle__NotEnoughETHSent();
        }
        if (RaffleState.OPEN != s_raffleState) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));

        // 1. Makes migration easiser
        // 2. Makes front end "indexing" easier
        emit EnteredRaffle(msg.sender);
    }

    /* CEI: Checks , Effects, Interactions
     * @dev Pick up the winner fandomly.
     * @param randomWords random generated number from VRF
     */
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata randomWords
    ) internal override {
        // Checks
        address payable[] memory players = s_players;
        // Effects
        uint256 indexOfWinner = randomWords[0] % players.length;
        address payable winner = players[indexOfWinner];
        s_recentWinner = winner;

        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        emit Pickedwinner(winner);

        // Interactions
        (bool isSucc, ) = winner.call{value: address(this).balance}("");
        s_raffleState = RaffleState.OPEN;
        if (!isSucc) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * @dev To tell chainlink automation when is the time to call performUpkeep
     * The follwing should be true for RaffleState to return true
     * 1. i_interval time has passed
     * 2. RaffleState is OPEN
     * 3. Balance is greater than 0
     * 4. At least one player entered
     * @param
     * @return upkeepNeeded
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded =
            ((block.timestamp - s_lastTimestamp) > i_interval) &&
            RaffleState.OPEN == s_raffleState &&
            address(this).balance > 0 &&
            s_players.length > 0;

        return (upkeepNeeded, "0x0");
    }

    // 1. Get a random number
    // 2. Use the random number to pick a player
    // 3. Be automatically called
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        // check to see if enough time has passed
        s_raffleState = RaffleState.CALCUATING;
        /* uint256 requestId =*/
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
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
        emit RequestedRaffleWinner(requestId);
    }

    /** Getter Function  */
    function getEnteranceFee() external view returns (uint256) {
        return i_enteranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getLengthofPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLastTimestamp() external view returns (uint256) {
        return s_lastTimestamp;
    }
}
