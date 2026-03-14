// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title DisputeDAO
 * @dev 去中心化争议解决 DAO - Phase 2
 */
contract DisputeDAO is AccessControl {
    bytes32 public constant JUROR_ROLE = keccak256("JUROR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // 争议
    struct Dispute {
        uint256 id;
        uint256 jobId;
        address plaintiff;
        address defendant;
        string reason;
        string evidence;      // IPFS hash
        uint256 amount;
        address paymentToken;
        DisputeStatus status;
        uint256 createdAt;
        uint256 votingEnds;
        uint256 votesForPlaintiff;
        uint256 votesForDefendant;
        uint256 quorum;
    }

    // 投票
    struct Vote {
        address juror;
        bool supportsPlaintiff;
        string reasoning;
        uint256 timestamp;
    }

    enum DisputeStatus {
        NONE,
        OPEN,
        VOTING,
        RESOLVED_PLAINTIFF,
        RESOLVED_DEFENDANT,
        RESOLVED_SPLIT,
        REJECTED
    }

    // 状态变量
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => Vote[]) public disputeVotes;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => uint256) public jurorStake;
    mapping(address => bool) public isJuror;

    uint256 public disputeCounter;
    uint256 public votingPeriod = 3 days;
    uint256 public quorumPercentage = 50;
    uint256 public minJurorStake = 100 * 10**18; // 100 tokens

    // 事件
    event DisputeCreated(uint256 indexed disputeId, address plaintiff, address defendant);
    event VoteCast(uint256 indexed disputeId, address juror, bool supportsPlaintiff);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus outcome);
    event JurorAdded(address indexed juror);
    event JurorRemoved(address indexed juror);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(JUROR_ROLE, admin);
    }

    /**
     * @dev 创建争议
     */
    function createDispute(
        uint256 _jobId,
        address _defendant,
        string calldata _reason,
        string calldata _evidence,
        uint256 _amount,
        address _paymentToken
    ) external returns (uint256) {
        disputeCounter++;
        uint256 disputeId = disputeCounter;

        disputes[disputeId] = Dispute({
            id: disputeId,
            jobId: _jobId,
            plaintiff: msg.sender,
            defendant: _defendant,
            reason: _reason,
            evidence: _evidence,
            amount: _amount,
            paymentToken: _paymentToken,
            status: DisputeStatus.OPEN,
            createdAt: block.timestamp,
            votingEnds: 0,
            votesForPlaintiff: 0,
            votesForDefendant: 0,
            quorum: 0
        });

        emit DisputeCreated(disputeId, msg.sender, _defendant);

        return disputeId;
    }

    /**
     * @dev 开始投票
     */
    function startVoting(uint256 _disputeId, uint256 _quorum) external onlyRole(ADMIN_ROLE) {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.OPEN, "Not open");

        dispute.status = DisputeStatus.VOTING;
        dispute.votingEnds = block.timestamp + votingPeriod;
        dispute.quorum = _quorum;

        // 激活争议
        emit DisputeCreated(_disputeId, dispute.plaintiff, dispute.defendant);
    }

    /**
     * @dev 投票
     */
    function vote(
        uint256 _disputeId,
        bool _supportsPlaintiff,
        string calldata _reasoning
    ) external onlyRole(JUROR_ROLE) {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.VOTING, "Not in voting");
        require(block.timestamp < dispute.votingEnds, "Voting ended");
        require(!hasVoted[_disputeId][msg.sender], "Already voted");

        // 记录投票
        disputeVotes[_disputeId].push(Vote({
            juror: msg.sender,
            supportsPlaintiff: _supportsPlaintiff,
            reasoning: _reasoning,
            timestamp: block.timestamp
        }));

        hasVoted[_disputeId][msg.sender] = true;

        if (_supportsPlaintiff) {
            dispute.votesForPlaintiff++;
        } else {
            dispute.votesForDefendant++;
        }

        emit VoteCast(_disputeId, msg.sender, _supportsPlaintiff);
    }

    /**
     * @dev 解决争议
     */
    function resolveDispute(uint256 _disputeId) external onlyRole(ADMIN_ROLE) {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.VOTING, "Not in voting");
        require(block.timestamp >= dispute.votingEnds, "Voting not ended");

        uint256 totalVotes = dispute.votesForPlaintiff + dispute.votesForDefendant;
        require(totalVotes >= dispute.quorum, "Quorum not reached");

        // 确定结果
        if (dispute.votesForPlaintiff > dispute.votesForDefendant * 2) {
            dispute.status = DisputeStatus.RESOLVED_PLAINTIFF;
        } else if (dispute.votesForDefendant > dispute.votesForPlaintiff * 2) {
            dispute.status = DisputeStatus.RESOLVED_DEFENDANT;
        } else {
            dispute.status = DisputeStatus.RESOLVED_SPLIT;
        }

        emit DisputeResolved(_disputeId, dispute.status);
    }

    /**
     * @dev 添加陪审员
     */
    function addJuror(address _juror) external onlyRole(ADMIN_ROLE) {
        _grantRole(JUROR_ROLE, _juror);
        isJuror[_juror] = true;
        emit JurorAdded(_juror);
    }

    /**
     * @dev 移除陪审员
     */
    function removeJuror(address _juror) external onlyRole(ADMIN_ROLE) {
        _revokeRole(JUROR_ROLE, _juror);
        isJuror[_juror] = false;
        emit JurorRemoved(_juror);
    }

    /**
     * @dev 获取争议信息
     */
    function getDispute(uint256 _disputeId) external view returns (Dispute memory) {
        return disputes[_disputeId];
    }

    /**
     * @dev 获取投票
     */
    function getVotes(uint256 _disputeId) external view returns (Vote[] memory) {
        return disputeVotes[_disputeId];
    }

    /**
     * @dev 获取投票结果
     */
    function getVotingResult(uint256 _disputeId) external view returns (
        uint256 forPlaintiff,
        uint256 forDefendant,
        uint256 total,
        uint256 quorum,
        bool quorumReached
    ) {
        Dispute storage dispute = disputes[_disputeId];
        forPlaintiff = dispute.votesForPlaintiff;
        forDefendant = dispute.votesForDefendant;
        total = forPlaintiff + forDefendant;
        quorum = dispute.quorum;
        quorumReached = total >= quorum;
    }

    // 管理函数
    function setVotingPeriod(uint256 _period) external onlyRole(ADMIN_ROLE) {
        votingPeriod = _period;
    }

    function setQuorumPercentage(uint256 _percentage) external onlyRole(ADMIN_ROLE) {
        require(_percentage <= 100, "Invalid percentage");
        quorumPercentage = _percentage;
    }
}
