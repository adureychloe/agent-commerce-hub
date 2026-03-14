// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title MultiChainBridge
 * @dev 多链桥接合约 - Phase 2
 */
contract MultiChainBridge is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // 支持的链
    struct Chain {
        uint256 chainId;
        string name;
        address bridgeAddress;
        bool active;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 fee;
    }

    // 跨链消息
    struct CrossChainMessage {
        bytes32 id;
        uint256 sourceChain;
        uint256 targetChain;
        address sender;
        address recipient;
        uint256 amount;
        address token;
        bytes data;
        MessageStatus status;
        uint256 timestamp;
    }

    enum MessageStatus {
        NONE,
        PENDING,
        DELIVERED,
        EXECUTED,
        FAILED
    }

    // 状态变量
    mapping(uint256 => Chain) public chains;
    mapping(bytes32 => CrossChainMessage) public messages;
    mapping(address => uint256) public userNonces;

    uint256 public constant MIN_CONFIRMATIONS = 3;
    uint256 public protocolFee = 10; // 0.1%

    // 事件
    event ChainAdded(uint256 indexed chainId, string name);
    event ChainDeactivated(uint256 indexed chainId);
    event MessageSent(bytes32 indexed messageId, uint256 targetChain, address recipient);
    event MessageDelivered(bytes32 indexed messageId, uint256 sourceChain);
    event MessageExecuted(bytes32 indexed messageId, bool success);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(BRIDGE_ROLE, admin);
    }

    /**
     * @dev 添加支持的链
     */
    function addChain(
        uint256 _chainId,
        string calldata _name,
        address _bridgeAddress,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _fee
    ) external onlyRole(ADMIN_ROLE) {
        chains[_chainId] = Chain({
            chainId: _chainId,
            name: _name,
            bridgeAddress: _bridgeAddress,
            active: true,
            minAmount: _minAmount,
            maxAmount: _maxAmount,
            fee: _fee
        });

        emit ChainAdded(_chainId, _name);
    }

    /**
     * @dev 发送跨链消息
     */
    function sendMessage(
        uint256 _targetChainId,
        address _recipient,
        uint256 _amount,
        address _token,
        bytes calldata _data
    ) external payable returns (bytes32) {
        Chain storage targetChain = chains[_targetChainId];
        require(targetChain.active, "Chain not active");
        require(_amount >= targetChain.minAmount, "Below minimum");
        require(_amount <= targetChain.maxAmount, "Above maximum");

        // 计算费用
        uint256 fee = (_amount * protocolFee) / 10000;
        uint256 amountAfterFee = _amount - fee;

        // 转移代币
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        // 生成消息 ID
        uint256 nonce = userNonces[msg.sender]++;
        bytes32 messageId = keccak256(abi.encodePacked(
            block.chainid,
            _targetChainId,
            msg.sender,
            _recipient,
            _amount,
            nonce,
            block.timestamp
        ));

        // 记录消息
        messages[messageId] = CrossChainMessage({
            id: messageId,
            sourceChain: block.chainid,
            targetChain: _targetChainId,
            sender: msg.sender,
            recipient: _recipient,
            amount: amountAfterFee,
            token: _token,
            data: _data,
            status: MessageStatus.PENDING,
            timestamp: block.timestamp
        });

        emit MessageSent(messageId, _targetChainId, _recipient);

        return messageId;
    }

    /**
     * @dev 接收跨链消息
     */
    function receiveMessage(
        uint256 _sourceChainId,
        bytes32 _messageId,
        address _sender,
        address _recipient,
        uint256 _amount,
        address _token,
        bytes calldata _data,
        bytes calldata _signature
    ) external onlyRole(BRIDGE_ROLE) {
        require(chains[_sourceChainId].active, "Source chain not active");
        require(messages[_messageId].status == MessageStatus.NONE, "Message exists");

        // 验证签名
        require(_verifySignature(_messageId, _signature), "Invalid signature");

        // 记录消息
        messages[_messageId] = CrossChainMessage({
            id: _messageId,
            sourceChain: _sourceChainId,
            targetChain: block.chainid,
            sender: _sender,
            recipient: _recipient,
            amount: _amount,
            token: _token,
            data: _data,
            status: MessageStatus.DELIVERED,
            timestamp: block.timestamp
        });

        emit MessageDelivered(_messageId, _sourceChainId);

        // 执行消息
        _executeMessage(_messageId, _recipient, _amount, _token, _data);
    }

    /**
     * @dev 执行消息
     */
    function _executeMessage(
        bytes32 _messageId,
        address _recipient,
        uint256 _amount,
        address _token,
        bytes calldata _data
    ) internal {
        CrossChainMessage storage message = messages[_messageId];

        // 转移代币
        IERC20(_token).safeTransfer(_recipient, _amount);

        // 如果有数据，调用接收者
        if (_data.length > 0) {
            (bool success, ) = _recipient.call(_data);
            message.status = success ? MessageStatus.EXECUTED : MessageStatus.FAILED;
        } else {
            message.status = MessageStatus.EXECUTED;
        }

        emit MessageExecuted(_messageId, message.status == MessageStatus.EXECUTED);
    }

    /**
     * @dev 验证签名
     */
    function _verifySignature(
        bytes32 _messageId,
        bytes calldata _signature
    ) internal pure returns (bool) {
        // 简化实现，实际需要 ECDSA 验证
        return _signature.length > 0;
    }

    /**
     * @dev 获取消息状态
     */
    function getMessageStatus(bytes32 _messageId) external view returns (MessageStatus) {
        return messages[_messageId].status;
    }

    /**
     * @dev 获取链信息
     */
    function getChain(uint256 _chainId) external view returns (Chain memory) {
        return chains[_chainId];
    }

    /**
     * @dev 获取活跃链列表
     */
    function getActiveChains() external view returns (uint256[] memory) {
        uint256[] memory activeChains = new uint256[](10);
        uint256 count = 0;

        // 检查常见链
        uint256[10] memory knownChains = [
            uint256(1),      // Ethereum
            uint256(137),    // Polygon
            uint256(42161),  // Arbitrum
            uint256(10),     // Optimism
            uint256(8453),   // Base
            uint256(56),     // BSC
            uint256(43114),  // Avalanche
            uint256(250),    // Fantom
            uint256(100),    // Gnosis
            uint256(0)       // placeholder
        ];

        for (uint256 i = 0; i < knownChains.length; i++) {
            if (chains[knownChains[i]].active) {
                activeChains[count] = knownChains[i];
                count++;
            }
        }

        // 调整数组大小
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeChains[i];
        }

        return result;
    }

    // 管理函数
    function deactivateChain(uint256 _chainId) external onlyRole(ADMIN_ROLE) {
        chains[_chainId].active = false;
        emit ChainDeactivated(_chainId);
    }

    function setProtocolFee(uint256 _fee) external onlyRole(ADMIN_ROLE) {
        require(_fee <= 1000, "Fee too high"); // max 10%
        protocolFee = _fee;
    }
}
