// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

/**
 * @title Decentralized Crowdfunding Contract
 * @dev This contract allows users to create and manage crowdfunding campaigns in a decentralized manner.
 * @author Amirali
 * @notice This contract is designed for educational purposes and may not be suitable for production use without further testing and security audits.
 */
contract DecentralizedCrowdfunding {
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

    // ==================== Errors ====================
    error GoalMustBeGreaterThanZero();
    error DurationMustBeGreaterThanZero();

    error CampaingState_Invalid();

    error fundCampaing_is_full();
    error fundCampaing_Should_graterThanzero();
    error fundCampaing_DeadlingExpired();

    error finalizeCampaign_DeadlineActive();

    error voteForWithdrawal_Already_Voted();
    error voteForWithdrawal_onlyContributions();

    error refund_onlyContributions();

    error Error_onlyCreator();

    error WithdrawFunds_not_enough_votes();

    // ==================== Events ====================
    event CampaignCreated(
        uint256 campaignId, address indexed creator, string title, string description, uint256 goal, uint256 deadline
    );

    event CampaignFund(uint256 campaignId, address indexed sender, uint256 amount);

    event VoteCast(uint256 campaignId, address indexed sender);

    event Refunded(uint256 campaignId, address indexed contributor, uint256 amount);

    event CampaignFinalized(uint256 campaignId, CampaignState campaignState);

    event WithdrawFunds(uint256 campaignId, address indexed creator, uint256 totalFunds);

    // ====================  modifaiers ====================
    modifier _atSatate(uint256 _campaignId, CampaignState _campaignState) {
        if (campaigns[_campaignId].state != _campaignState) {
            revert CampaingState_Invalid();
        }
        _;
    }

    modifier onlyCreator(uint256 _campaignId) {
        if (campaigns[_campaignId].creator != msg.sender) {
            revert Error_onlyCreator();
        }
        _;
    }

    // ==================== state Varibales ====================

    enum CampaignState {
        Pending,
        Active,
        Successful,
        Failed,
        Refunded
    }

    Campaign[] public campaigns;

    // ==================== external Functions ====================

    /**
     * @param _title is for set a Campaing Name
     * @param _description is for set a Campaing Description
     * @param _goal is for set a Campaing Goal
     * @param _duration is for set a Campaing Duration
     */
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

    /**
     * @notice Fund a specific campaign by its ID.
     * @param _campaignID The ID of the campaign to fund.
     */
    function fundCampaign(uint256 _campaignID) external payable _atSatate(_campaignID, CampaignState.Active) {
        Campaign storage campaign = campaigns[_campaignID];

        if (msg.value <= 0) {
            revert fundCampaing_Should_graterThanzero();
        }

        if (block.timestamp >= campaign.deadline) {
            revert fundCampaing_DeadlingExpired();
        }

        if (msg.value > campaign.goal) {
            revert fundCampaing_is_full();
        }

        if (campaign.contributions[msg.sender] == 0) {
            campaign.contributors.push(msg.sender);
        }

        campaign.contributions[msg.sender] += msg.value;
        campaign.totalFunds += msg.value;

        emit CampaignFund(_campaignID, msg.sender, msg.value);
    }

    /**
     * @notice Vote a specific campaign by its ID.
     * @param _campaignID The ID of the campaign to fund.
     * voted for withdraw fund from Campagn
     */
    function voteForWithdrawal(uint256 _campaignID) external _atSatate(_campaignID, CampaignState.Successful) {
        Campaign storage campaign = campaigns[_campaignID];

        if (campaign.hasVoted[msg.sender] == true) {
            revert voteForWithdrawal_Already_Voted();
        }

        if (campaign.contributions[msg.sender] == 0) {
            revert voteForWithdrawal_onlyContributions();
        }

        campaign.voteCount++;
        campaign.hasVoted[msg.sender] = true;

        emit VoteCast(_campaignID, msg.sender);
    }

    /**
     * @notice Refund a specific campaign by its ID.
     * @param _campaignID The ID of the campaign to fund.
     * refund for contributors if the campaign is failed
     */
    function refund(uint256 _campaignID) external _atSatate(_campaignID, CampaignState.Failed) {
        Campaign storage campaign = campaigns[_campaignID];

        uint256 contributed = campaign.contributions[msg.sender];

        if (contributed == 0) {
            revert refund_onlyContributions();
        }

        (bool success,) = payable(msg.sender).call{value: contributed}("");

        require(success, "Refund failed");

        campaign.contributions[msg.sender] = 0;

        emit Refunded(_campaignID, msg.sender, contributed);
    }

    /**
     * @notice Finalize a specific campaign by its ID.
     * @param _campaignID The ID of the campaign to fund.
     * finalize the campaign and set the state to successful or failed
     */
    function finalizeCampaign(uint256 _campaignID) external _atSatate(_campaignID, CampaignState.Active) {
        Campaign storage campaign = campaigns[_campaignID];

        if (block.timestamp <= campaign.deadline) {
            revert finalizeCampaign_DeadlineActive();
        }

        if (campaign.totalFunds >= campaign.goal) {
            campaign.state = CampaignState.Successful;
        } else {
            campaign.state = CampaignState.Failed;
        }

        emit CampaignFinalized(_campaignID, campaign.state);
    }

    /**
     * @notice Withdraw funds from a specific campaign by its ID.
     * @param _campaignID The ID of the campaign to fund.
     * withdraw funds from the campaign if the campaign is successful and the creator has enough votes
     */
    function withdrawFunds(uint256 _campaignID)
        external
        onlyCreator(_campaignID)
        _atSatate(_campaignID, CampaignState.Successful)
    {
        Campaign storage campaign = campaigns[_campaignID];

        if (campaign.voteCount * 2 <= campaign.contributors.length) {
            revert WithdrawFunds_not_enough_votes();
        }

        (bool success,) = payable(campaign.creator).call{value: campaign.totalFunds}("");

        uint256 amount = campaign.totalFunds;

        campaign.totalFunds = 0;
        campaign.state = CampaignState.Successful;

        require(success, "withdrawFunds failed");

        emit WithdrawFunds(_campaignID, campaign.creator, amount);
    }

    // ==================== Getter Functions ====================
    function getCampaignLenght() public view returns (uint256 len) {
        return campaigns.length;
    }

    function getCampaign(uint256 _campaignID)
        public
        view
        returns (
            address creator,
            string memory title,
            string memory description,
            uint256 goal,
            uint256 deadline,
            uint256 totalFunds,
            CampaignState state,
            address[] memory contributors,
            uint256 voteCount
        )
    {
        Campaign storage campaign = campaigns[_campaignID];
        return (
            campaign.creator,
            campaign.title,
            campaign.description,
            campaign.goal,
            campaign.deadline,
            campaign.totalFunds,
            campaign.state,
            campaign.contributors,
            campaign.voteCount
        );
    }

    function getContribution(uint256 _campaignID, address _contributor) public view returns (uint256) {
        Campaign storage campaign = campaigns[_campaignID];
        return campaign.contributions[_contributor];
    }


    function getIsVoted(uint256 _campaignID, address _voter) public view returns (bool) {
        return campaigns[_campaignID].hasVoted[_voter];
    }

    // ==================== Setter Functions ====================
    function setCampaignState(uint256 _campaignID, CampaignState _state) external onlyCreator(_campaignID) {
        Campaign storage campaign = campaigns[_campaignID];

        campaign.state = _state;
    }

    function setCampaignUserVoted(uint256 _campaignID, address _user) external onlyCreator(_campaignID) {
        Campaign storage campaign = campaigns[_campaignID];
        campaign.hasVoted[_user] = true;
    }
}
