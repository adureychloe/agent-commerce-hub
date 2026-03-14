// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title A2AMarketplace
 * @dev Agent-to-Agent 交易市场
 */
contract A2AMarketplace is AccessControl {
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    // A2A 消息
    struct A2AMessage {
        bytes32 id;
        address from;
        address to;
        bytes payload;
        uint256 timestamp;
        bool delivered;
    }

    // 谈判记录
    struct Negotiation {
        bytes32 id;
        address buyer;
        address seller;
        uint256 serviceId;
        uint256 proposedPrice;
        uint256 agreedPrice;
        NegotiationStatus status;
        uint256 createdAt;
    }

    enum NegotiationStatus {
        PROPOSED,
        COUNTER_OFFERED,
        ACCEPTED,
        REJECTED,
        EXPIRED
    }

    // 争议
    struct Dispute {
        uint256 id;
        uint256 jobId;
        address initiator;
        string reason;
        DisputeStatus status;
        uint256 createdAt;
        uint256 resolvedAt;
    }

    enum DisputeStatus {
        OPEN,
        RESOLVED_BUYER,
        RESOLVED_SELLER,
        RESOLVED_SPLIT,
        CLOSED
    }

    // 信誉评分
    struct Reputation {
        uint256 totalRatings;
        uint256 totalScore;
        uint256 averageScore;
        uint256 completedJobs;
        uint256 disputedJobs;
    }

    mapping(bytes32 => A2AMessage) public messages;
    mapping(bytes32 => Negotiation) public negotiations;
    mapping(uint256 => Dispute) public disputes;
    mapping(address => Reputation) public reputations;

    uint256 public disputeCounter;

    // 事件
    event MessageSent(bytes32 indexed id, address from, address to);
    event NegotiationStarted(bytes32 indexed id, address buyer, address seller);
    event PriceProposed(bytes32 indexed id, uint256 price);
    event NegotiationAccepted(bytes32 indexed id, uint256 price);
    event DisputeOpened(uint256 indexed id, uint256 jobId);
    event DisputeResolved(uint256 indexed id, DisputeStatus outcome);
    event RatingSubmitted(address indexed agent, uint256 score);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @dev 发送 A2A 消息
     */
    function sendMessage(
        address _to,
        bytes calldata _payload
    ) external returns (bytes32) {
        bytes32 id = keccak256(abi.encodePacked(msg.sender, _to, block.timestamp));
        
        messages[id] = A2AMessage({
            id: id,
            from: msg.sender,
            to: _to,
            payload: _payload,
            timestamp: block.timestamp,
            delivered: false
        });

        emit MessageSent(id, msg.sender, _to);
        return id;
    }

    /**
     * @dev 开始谈判
     */
    function startNegotiation(
        address _seller,
        uint256 _serviceId,
        uint256 _proposedPrice
    ) external returns (bytes32) {
        bytes32 id = keccak256(abi.encodePacked(msg.sender, _seller, _serviceId, block.timestamp));
        
        negotiations[id] = Negotiation({
            id: id,
            buyer: msg.sender,
            seller: _seller,
            serviceId: _serviceId,
            proposedPrice: _proposedPrice,
            agreedPrice: 0,
            status: NegotiationStatus.PROPOSED,
            createdAt: block.timestamp
        });

        emit NegotiationStarted(id, msg.sender, _seller);
        emit PriceProposed(id, _proposedPrice);
        return id;
    }

    /**
     * @dev 反向报价
     */
    function counterOffer(
        bytes32 _negotiationId,
        uint256 _newPrice
    ) external {
        Negotiation storage neg = negotiations[_negotiationId];
        require(neg.seller == msg.sender, "Not seller");
        require(neg.status == NegotiationStatus.PROPOSED, "Invalid status");
        
        neg.proposedPrice = _newPrice;
        neg.status = NegotiationStatus.COUNTER_OFFERED;
        
        emit PriceProposed(_negotiationId, _newPrice);
    }

    /**
     * @dev 接受报价
     */
    function acceptOffer(bytes32 _negotiationId) external {
        Negotiation storage neg = negotiations[_negotiationId];
        require(
            neg.buyer == msg.sender || neg.seller == msg.sender,
            "Not participant"
        );
        
        neg.agreedPrice = neg.proposedPrice;
        neg.status = NegotiationStatus.ACCEPTED;
        
        emit NegotiationAccepted(_negotiationId, neg.agreedPrice);
    }

    /**
     * @dev 拒绝报价
     */
    function rejectOffer(bytes32 _negotiationId) external {
        Negotiation storage neg = negotiations[_negotiationId];
        require(
            neg.buyer == msg.sender || neg.seller == msg.sender,
            "Not participant"
        );
        
        neg.status = NegotiationStatus.REJECTED;
    }

    /**
     * @dev 提交评分
     */
    function submitRating(address _agent, uint256 _score) external {
        require(_score >= 1 && _score <= 5, "Invalid score");
        
        Reputation storage rep = reputations[_agent];
        rep.totalRatings++;
        rep.totalScore += _score;
        rep.averageScore = rep.totalScore / rep.totalRatings;
        
        emit RatingSubmitted(_agent, _score);
    }

    /**
     * @dev 开启争议
     */
    function openDispute(
        uint256 _jobId,
        string calldata _reason
    ) external returns (uint256) {
        disputeCounter++;
        uint256 disputeId = disputeCounter;
        
        disputes[disputeId] = Dispute({
            id: disputeId,
            jobId: _jobId,
            initiator: msg.sender,
            reason: _reason,
            status: DisputeStatus.OPEN,
            createdAt: block.timestamp,
            resolvedAt: 0
        });

        emit DisputeOpened(disputeId, _jobId);
        return disputeId;
    }

    /**
     * @dev 解决争议（管理员）
     */
    function resolveDispute(
        uint256 _disputeId,
        DisputeStatus _outcome
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.OPEN, "Not open");
        
        dispute.status = _outcome;
        dispute.resolvedAt = block.timestamp;
        
        emit DisputeResolved(_disputeId, _outcome);
    }

    /**
     * @dev 获取信誉
     */
    function getReputation(address _agent) external view returns (Reputation memory) {
        return reputations[_agent];
    }

    /**
     * @dev 获取谈判信息
     */
    function getNegotiation(bytes32 _id) external view returns (Negotiation memory) {
        return negotiations[_id];
    }
}
