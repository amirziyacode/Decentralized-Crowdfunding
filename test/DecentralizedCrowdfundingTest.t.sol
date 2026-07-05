// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {DecentralizedCrowdfunding} from "../src/DecentralizedCrowdfunding.sol";

contract DecentralizedCrowdfundingTest is Test {
    DecentralizedCrowdfunding public crowdfunding;

    address user = makeAddr("user");

    function setUp() public {
        crowdfunding = new DecentralizedCrowdfunding();
        vm.deal(user, 100 ether);
    }

    modifier CreateCampaign() {
        vm.prank(user);
        crowdfunding.createCampaign("Test Campaign", "This is a test campaign", 100 ether, 1 days);
        _;
    }

    // ==================== CreateCampaign ====================
    function testCreateCampaign() public {
        vm.startPrank(user);
        crowdfunding.createCampaign("Test Campaign", "This is a test campaign", 100 ether, 1 days);

        (address creator, string memory title, string memory description, uint256 goal, uint256 deadline,,,,) =
            crowdfunding.getCampaign(0);

        uint256 duration = 1 days;
        uint256 expectDealline = block.timestamp + (duration * 1 days);

        assertEq(crowdfunding.getCampaignLenght(), 1);
        assertEq(creator, user);
        assertEq(title, "Test Campaign");
        assertEq(description, "This is a test campaign");
        assertEq(goal, 100 ether);
        assertEq(deadline, expectDealline);

        vm.stopPrank();
    }

    function testCreateCampaignWithZeroGoal() public {
        vm.startPrank(user);
        vm.expectRevert(DecentralizedCrowdfunding.GoalMustBeGreaterThanZero.selector);
        crowdfunding.createCampaign("Test Campaign", "This is a test campaign", 0, 1 days);
        vm.stopPrank();
    }

    function testCreateCampaignWithZeroDuration() public {
        vm.startPrank(user);
        vm.expectRevert(DecentralizedCrowdfunding.DurationMustBeGreaterThanZero.selector);
        crowdfunding.createCampaign("Test Campaign", "This is a test campaign", 100 ether, 0);
        vm.stopPrank();
    }

    // ==================== FundCampaing ====================

    function testFundCampaign_InvalidState() public {
        vm.startPrank(user);

        crowdfunding.createCampaign("Test Campaign", "This is a test campaign", 100 ether, 1 days);

        crowdfunding.setCampaignState(0, DecentralizedCrowdfunding.CampaignState.Failed);

        vm.expectRevert(DecentralizedCrowdfunding.CampaingState_Invalid.selector);

        crowdfunding.fundCampaign{value: 1 ether}(0);
    }

    function test_SetStateOnlyOwner() public CreateCampaign(){


        vm.expectRevert(DecentralizedCrowdfunding.Error_onlyCreator.selector);
        crowdfunding.setCampaignState(0, DecentralizedCrowdfunding.CampaignState.Failed);
    }

    function testFundCampaign_NotExpaired() public CreateCampaign(){

        vm.warp(block.timestamp + (1 days * 1 days) + 1 seconds);

        vm.expectRevert(DecentralizedCrowdfunding.fundCampaing_DeadlingExpired.selector);

        crowdfunding.fundCampaign{value: 1 ether}(0);
    }

    function testFundCampaing_revert_if_goal_is_full() public CreateCampaign(){


        vm.expectRevert(DecentralizedCrowdfunding.fundCampaing_is_full.selector);

        crowdfunding.fundCampaign{value: 101 ether}(0);
    }

    function testFundCampaign() public {
        vm.startPrank(user);
        crowdfunding.createCampaign("Test Campaign", "This is a test campaign", 100 ether, 1 days);

        crowdfunding.fundCampaign{value: 50 ether}(0);

        (,,,,, uint256 totalFunded,, address[] memory contributors,) = crowdfunding.getCampaign(0);

        uint256 contribution = crowdfunding.getContribution(0, user);

        assertEq(totalFunded, 50 ether);
        assertEq(contributors.length, 1);
        assertEq(contributors[0], user);
        assertEq(contribution, 50 ether);

        vm.stopPrank();
    }

    function testFuzz_FundCampaign_withAnyFund(uint256 fund) public{
        uint256 goal = 100 ether;

        vm.startPrank(user);


        crowdfunding.createCampaign("Test Campaign", "This is a test campaign", goal, 1 days);

        vm.assume(fund > 0 && fund <= goal);

        crowdfunding.fundCampaign{value:fund}(0);

        (,,,,, uint256 totalFunded,, address[] memory contributors,) = crowdfunding.getCampaign(0);


        uint256 contribution = crowdfunding.getContribution(0, user);

        assertEq(totalFunded, fund);
        assertEq(contributors.length, 1);
        assertEq(contributors[0], user);
        assertEq(contribution, fund);

        vm.stopPrank();
    }

    // ==================== ReFundCampaing ====================
    function testRefundCampaign_revert_FailedState() public {
        vm.startPrank(user);

        crowdfunding.createCampaign("Test Campaign", "This is a test campaign", 100 ether, 1 days);

        vm.stopPrank();

        vm.expectRevert(DecentralizedCrowdfunding.CampaingState_Invalid.selector);
        crowdfunding.refund(0);
    }

    function testRefundCampaign_onlyContributed() public {
        vm.startPrank(user);
        crowdfunding.createCampaign("Test Campaign", "This is a test campaign", 100 ether, 1 days);

        crowdfunding.setCampaignState(0, DecentralizedCrowdfunding.CampaignState.Failed);

        vm.stopPrank();

        vm.expectRevert(DecentralizedCrowdfunding.refund_onlyContributions.selector);
        crowdfunding.refund(0);
    }

    function testRefundCampaign() public {
        vm.startPrank(user);
        crowdfunding.createCampaign("Test Campaign", "This is a test campaign", 100 ether, 1 days);

        crowdfunding.fundCampaign{value: 50 ether}(0);

        crowdfunding.setCampaignState(0, DecentralizedCrowdfunding.CampaignState.Failed);

        uint256 balanceBeforeRefund = user.balance;

        crowdfunding.refund(0);

        uint256 balanceAfterRefund = user.balance;

        assertEq(balanceAfterRefund - balanceBeforeRefund, 50 ether);

        vm.stopPrank();
    }

    function testFuzz_RefundCampaign_withAnyFund(uint256 fund) public{
        uint256 goal = 100 ether;

        vm.startPrank(user);

        crowdfunding.createCampaign("Test Campaign", "This is a test campaign", goal, 1 days);

        vm.assume(fund > 0 && fund <= goal);

        crowdfunding.fundCampaign{value:fund}(0);

        crowdfunding.setCampaignState(0, DecentralizedCrowdfunding.CampaignState.Failed);

        uint256 balanceBeforeRefund = user.balance;

        crowdfunding.refund(0);

        uint256 balanceAfterRefund = user.balance;

        assertEq(balanceAfterRefund - balanceBeforeRefund, fund);

        vm.stopPrank();

    }

    // ==================== finalizeCampaign ====================
    function testFinalizeCampaign_DeadlingExpired() public CreateCampaign(){

        vm.warp(block.timestamp + (1 days * 1 days) + 1 seconds);

        vm.expectRevert(DecentralizedCrowdfunding.finalizeCampaign_DeadlingExpired.selector);

        crowdfunding.finalizeCampaign(0);
    }

    function testfinalizeCampaign_SetState_Successful() public CreateCampaign(){

        crowdfunding.fundCampaign{value: 100 ether}(0);

        crowdfunding.finalizeCampaign(0);

        (,,,,,, DecentralizedCrowdfunding.CampaignState state,,) = crowdfunding.getCampaign(0);

        assertEq(uint256(state), uint256(DecentralizedCrowdfunding.CampaignState.Successful));
    }

    function testfinalizeCampaign_SetState_Failed() public CreateCampaign(){

        crowdfunding.fundCampaign{value: 50 ether}(0);

        crowdfunding.finalizeCampaign(0);

        (,,,,,, DecentralizedCrowdfunding.CampaignState state,,) = crowdfunding.getCampaign(0);

        assertEq(uint256(state), uint256(DecentralizedCrowdfunding.CampaignState.Failed));
    }
    // ==================== voteForWithdrawal ====================

    function testVoteForWithdrawal_hasVoted() public {
        vm.startPrank(user);
        crowdfunding.createCampaign("Test Campaign", "This is a test campaign", 100 ether, 1 days);

        crowdfunding.setCampaignUserVoted(0, user);
        crowdfunding.setCampaignState(0, DecentralizedCrowdfunding.CampaignState.Successful);

        vm.expectRevert(DecentralizedCrowdfunding.voteForWithdrawal_Already_Voted.selector);

        crowdfunding.voteForWithdrawal(0);

        vm.stopPrank();
    }

    function testVoteForWithdrawal_onlyContributions() public {
        vm.startPrank(user);
        crowdfunding.createCampaign("Test Campaign", "This is a test campaign", 100 ether, 1 days);

        crowdfunding.setCampaignState(0, DecentralizedCrowdfunding.CampaignState.Successful);

        vm.expectRevert(DecentralizedCrowdfunding.voteForWithdrawal_onlyContributions.selector);

        crowdfunding.voteForWithdrawal(0);

        vm.stopPrank();
    }

    function testVoteForWithdrawal_Success() public CreateCampaign(){

        vm.prank(user);
        // set Contribution for user
        crowdfunding.fundCampaign{value: 50 ether}(0);

        vm.prank(user);
        crowdfunding.setCampaignState(0, DecentralizedCrowdfunding.CampaignState.Successful);

        vm.prank(user);
        crowdfunding.voteForWithdrawal(0);

        (,,,,,,,, uint256 voteCount) = crowdfunding.getCampaign(0);

        bool checkVoted = crowdfunding.getIsVoted(0, user);

        assertEq(voteCount, 1);

        assertEq(checkVoted, true);

        vm.stopPrank();
    }

    // ==================== voteForWithdrawal ====================
    function testWithdrawFunds_NotOwner() public CreateCampaign(){

        vm.expectRevert(DecentralizedCrowdfunding.Error_onlyCreator.selector);

        crowdfunding.withdrawFunds(0);
    }

    function testWithdrawFunds_revert_if_voter_lesse_than_half_Of_voter() public {
        vm.startPrank(user);

        crowdfunding.createCampaign("Test Campaign", "This is a test campaign", 100 ether, 1 days);

        crowdfunding.setCampaignState(0, DecentralizedCrowdfunding.CampaignState.Successful);

        vm.expectRevert(DecentralizedCrowdfunding.WithdrawFunds_not_enough_votes.selector);

        crowdfunding.withdrawFunds(0);

        vm.stopPrank();
    }

    //  for withdraw we should have 50 % voter
    function testWithdrawFunds_Success() public CreateCampaign(){

        address invester = makeAddr("invester");
        vm.deal(invester, 100 ether);

        vm.prank(invester);
        crowdfunding.fundCampaign{value: 30 ether}(0);

        // ========= fund a invester and sumbite a vote ===============
        vm.prank(user);
        crowdfunding.setCampaignState(0, DecentralizedCrowdfunding.CampaignState.Successful);

        // set one voter
        vm.prank(invester);
        crowdfunding.voteForWithdrawal(0);

        // ========= test withdraw with user ===============

        vm.prank(user);
        crowdfunding.setCampaignState(0, DecentralizedCrowdfunding.CampaignState.Active);

        vm.prank(user);
        crowdfunding.fundCampaign{value: 50 ether}(0);

        vm.prank(user);
        crowdfunding.setCampaignState(0, DecentralizedCrowdfunding.CampaignState.Successful);

        // set another voter
        vm.prank(user);
        crowdfunding.voteForWithdrawal(0);

        vm.prank(user);
        crowdfunding.withdrawFunds(0);

        (,,,,, uint256 totalFunds, DecentralizedCrowdfunding.CampaignState camapignState,,) =
            crowdfunding.getCampaign(0);   

        assertEq(uint256(camapignState), uint256(DecentralizedCrowdfunding.CampaignState.Successful));
        assertEq(totalFunds, 0);
        assertEq(user.balance, 130 ether);
        assertEq(address(crowdfunding).balance,0);

    }

    // ==================== getContribution ====================

    function testGetContribution() public {
        vm.startPrank(user);
        crowdfunding.createCampaign("Test Campaign", "This is a test campaign", 100 ether, 1 days);

        crowdfunding.fundCampaign{value: 50 ether}(0);

        uint256 contribution = crowdfunding.getContribution(0, user);

        assertEq(contribution, 50 ether);

        vm.stopPrank();
    }


    function testGet_IsVoted() public CreateCampaign(){

        vm.prank(user);
        bool checkVote  = crowdfunding.getIsVoted(0,user);

        assertEq(checkVote,false);
    }

    // ==================== Setter ====================

    function testSetCampaignState() public CreateCampaign() {

        vm.prank(user);
        crowdfunding.setCampaignState(0,DecentralizedCrowdfunding.CampaignState.Successful);

        (,,,,,,DecentralizedCrowdfunding.CampaignState state,,) = crowdfunding.getCampaign(0);

        assertEq(uint256(state),uint256(DecentralizedCrowdfunding.CampaignState.Successful));
    }



    function testGetCampaignByID() public CreateCampaign(){

        (address creator, string memory title, string memory description, uint256 goal, uint256 deadline,,,,) =
            crowdfunding.getCampaign(0);


       assertEq(creator,user);
       assertEq(title,"Test Campaign");
       assertEq(description,"This is a test campaign");
       assertEq(goal,100 ether);
       assertEq(deadline,block.timestamp + (1 days * 1 days));            
    }



    
}
