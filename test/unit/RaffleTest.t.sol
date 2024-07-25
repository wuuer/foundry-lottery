// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";

contract RaffleTest is Test {
    Raffle private raffle;

    // deploy
    function setUp() external {
        DeployRaffle deploy = new DeployRaffle();
        raffle = deploy.run();
    }
}
