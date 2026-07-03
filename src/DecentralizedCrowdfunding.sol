// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

/**
 * @title Decentralized Crowdfunding Contract
 * @dev This contract allows users to create and manage crowdfunding campaigns in a decentralized manner.
 * @author Amirali
 * @notice This contract is designed for educational purposes and may not be suitable for production use without further testing and security audits.
 */
contract DecentralizedCrowdfunding {
    // ==================== Errors ====================
    error GoalMustBeGreaterThanZero();
    error DurationMustBeGreaterThanZero();
    error fundCampaing_Should_graterThanzero();
    error fundCampaing_DeadlingExpired();
    error fundCampaing_State_is_Failed();
    error fundCampaing_is_full();

    // ==================== Events ====================
    event CampaignCreated(
        uint256 campaignId,
        address indexed creator,
        string title,
        string description,
        uint256 goal,
        uint256 deadline
    );

    event CampaignFund(
        uint256 campaignId,
        address indexed sender,
        uint256 amountSend
    );

    // ==================== state Varibales ====================

    enum CampaignState {
        Pending,
        Active,
        Successful,
        Failed,
        Refunded
    }

    Campaign[] public campaigns;

    // ==================== Struct ====================
    struct Campaign {
        address payable creator;
        string title;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 totalFunds;
        CampaignState state;
        mapping(address => uint256) contributions;
        address[] contributors;
        uint256 voteCount;
        mapping(address => bool) hasVoted;
    }

    // ==================== external Functions ====================

    function createCampaign(string memory _title, string memory _description, uint256 _goal, uint256 _duration)
        external
    {
        if (_goal <= 0) {
            revert GoalMustBeGreaterThanZero();
        }
        if (_duration <= 0) {
            revert DurationMustBeGreaterThanZero();
        }

        Campaign storage newCapaign = campaigns.push();

        newCapaign.creator = payable(msg.sender);
        newCapaign.title = _title;
        newCapaign.description = _description;
        newCapaign.goal = _goal;
        newCapaign.deadline = block.timestamp + (_duration * 1 days);
        newCapaign.state = CampaignState.Active;

        emit CampaignCreated(campaigns.length - 1, msg.sender, _title, _description, _goal, newCapaign.deadline);
    }

    function fundCampaign(uint256 _campaignID) external payable {
        Campaign storage campaign = campaigns[_campaignID];

        if (msg.value <= 0) {
            revert fundCampaing_Should_graterThanzero();
        }

        if (campaign.deadline > block.timestamp) {
            revert fundCampaing_DeadlingExpired();
        }

        // state is faild
        if (campaign.state != CampaignState.Failed) {
            revert fundCampaing_State_is_Failed();
        }

        if(msg.value > campaign.goal){
            revert fundCampaing_is_full();
        }

        if(campaign.contributions[msg.sender] == 0){
            campaign.contributors.push(msg.sender);
        }

        campaign.contributions[msg.sender] += msg.value;
        campaign.totalFunds += msg.value;

        emit CampaignFund(_campaignID,msg.sender,msg.value);
    }

    
}
