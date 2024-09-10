// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimunDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    // What can we do to work with addresses outside our system?
    // 1. Unit
    //  - Testing a specific part of our code
    // 2. Integration
    //  - Testing how our code works with other parts of our code
    // 3. Forked
    //  - Testing our code on a simulated real environment
    // 4. Staging
    //  - Testing our code in a real environment that is not prod

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    // using CHEATCODES in htpps://book.getfoundry.sh/cheatcodes/expect-revert
    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // hey, the next line should revert!
        fundMe.fund(); // send zero value
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.startPrank(USER); // the next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
        vm.stopPrank();
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
        vm.stopPrank();
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithDrwaWithSingleFunder() public funded {
        // Best practice for testing
        // --------------------------

        // Arrange -> Set up the test
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act -> Action i want to test
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert -> Assert the test
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithDrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // we are going to use hoax (its from forge-std), starts a prank and gives value, all in one call
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testCheaperWithDrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // we are going to use hoax (its from forge-std), starts a prank and gives value, all in one call
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithDraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}

// forge coverage --fork-url [URL_ON_WE_ARE_TESTING] -----> this is were you see how much of the code is tested
