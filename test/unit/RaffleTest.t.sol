// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";

contract RaffleTest is Test {
    Raffle private raffle;
    // faked user
    address private PLAYER = makeAddr("player");
    uint256 private constant STARING_ETH = 1 ether;
    uint256 private constant interval = 30;

    /** Events **/
    event EnteredRaffle(address indexed player);

    // deploy
    function setUp() external {
        DeployRaffle deploy = new DeployRaffle();
        raffle = deploy.run();
        vm.deal(PLAYER, STARING_ETH);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    ////////////////////
    // enterRaffle   //
    //////////////////

    function testRaffleRevertsWhenYouDontPayEnough() public {
        uint256 eth = 0.0001 ether;
        vm.expectRevert(Raffle.Raffle__NotEnoughETHSent.selector);
        raffle.enterRaffle{value: eth}();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        uint256 enteranceFee = raffle.getEnteranceFee();
        hoax(PLAYER, enteranceFee);
        raffle.enterRaffle{value: enteranceFee}();
        address enteredPlayer = raffle.getPlayer(0);
        assertEq(enteredPlayer, PLAYER);
    }

    function testEmitsEventOnEnterance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        // expect the next will emit this event
        emit EnteredRaffle(PLAYER);

        raffle.enterRaffle{value: STARING_ETH}();
    }

    function testCantEnterWhenRaffleStateInCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: STARING_ETH}();
        // set the timestamp
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        hoax(makeAddr("player2"), STARING_ETH);
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: STARING_ETH}();
    }

    ////////////////////
    // checkUpkeep   //
    //////////////////

    function testCheckUpKeepReturnsFalseIfItThatHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        vm.assertEq(upkeepNeeded, false);
    }

    function testCheckUpKeepReturnsFalseIfItRaffleIsNotOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: STARING_ETH}();
        // set the timestamp
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        vm.assertEq(upkeepNeeded, false);
    }

    function testCheckUpKeepReturnsFalseIfEnoughTimePassed() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: STARING_ETH}();
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        vm.assertEq(upkeepNeeded, false);
    }

    function testCheckUpKeepReturnTrueIfConditionMeet() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: STARING_ETH}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        vm.assertEq(upkeepNeeded, true);
    }

    ////////////////////
    // performUpkeep //
    //////////////////

    function testPerformUpKeepOnIfcheckUpkeepReturnTrue() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: STARING_ETH}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.checkUpkeep("");

        raffle.performUpkeep("");
        Raffle.RaffleState state = raffle.getRaffleState();
        assert(state == Raffle.RaffleState.CALCUATING);
    }

    function testPerformUpKeepOnFailsIfcheckUpkeepReturnFalse() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpKeepNotNeeded.selector,
                0, // balance
                0, // player count
                Raffle.RaffleState.OPEN //raffle state
            )
        );
        raffle.performUpkeep("");
    }

    modifier raffleEnterdAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: STARING_ETH}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpKeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEnterdAndTimePassed
    {
        // log emited events
        vm.recordLogs();
        raffle.performUpkeep(""); // emit requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        // 0: RandomWordsRequested from requestRandomWords
        // 1: RequestedRaffleWinner from performUpkeep
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState state = raffle.getRaffleState();
        assert(state == Raffle.RaffleState.CALCUATING);
        assert(uint256(requestId) > 0);
    }

    /////////////////////////
    // fulfillRandomWords //
    ///////////////////////

    modifier skipFork() {
        // skip if it is not anil network
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testfulfillRandomWordsCanOnlyBeCalledAfterPerfromUpKeep(
        uint256 requestId // Fuzz test
    ) public raffleEnterdAndTimePassed skipFork {
        address coordinator = address(raffle.s_vrfCoordinator());
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(coordinator).fulfillRandomWords(
            requestId,
            address(raffle)
        );
    }

    function testFullfillRandomWordsPicksAWinnerResetAndSendsMoney()
        public
        raffleEnterdAndTimePassed
        skipFork
    {
        uint256 additionalEntrants = 5;
        uint160 startIndex = 1;
        for (uint160 i = startIndex; i < startIndex + additionalEntrants; i++) {
            hoax(address(i), STARING_ETH);
            raffle.enterRaffle{value: STARING_ETH}();
        }

        uint256 totalBalance = address(raffle).balance;
        uint256 previousTimestamp = raffle.getLastTimestamp();
        // log emited events
        vm.recordLogs();
        raffle.performUpkeep(""); // emit requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        // 0: RandomWordsRequested from requestRandomWords
        // 1: RequestedRaffleWinner from performUpkeep
        bytes32 requestId = entries[1].topics[1];
        address coordinator = address(raffle.s_vrfCoordinator());
        VRFCoordinatorV2_5Mock(coordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );
        Raffle.RaffleState state = raffle.getRaffleState();
        assert(state == Raffle.RaffleState.OPEN);
        address recentWinner = raffle.getRecentWinner();
        assert(recentWinner != address(0));
        assert(address(recentWinner).balance == totalBalance);
        assert(address(raffle).balance == 0);
        assert(raffle.getLengthofPlayers() == 0);
        assert(previousTimestamp < raffle.getLastTimestamp());
    }
}
