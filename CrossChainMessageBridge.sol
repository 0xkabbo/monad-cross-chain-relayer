// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CrossChainMessageBridge
 * @dev Dispatches and executes authenticated cross-chain messages passing between independent consensus silos.
 */
contract CrossChainMessageBridge is Ownable {

    struct MessagePacket {
        bytes32 payloadHash;
        uint32 sourceChainId;
        address sender;
        bool processed;
    }

    mapping(bytes32 => MessagePacket) public inboundRegistry;
    mapping(address => bool) public trustedRelayers;

    event MessageDispatched(bytes32 indexed msgHash, uint32 indexed targetChainId, address indexed sender, bytes payload);
    event MessageExecuted(bytes32 indexed msgHash, bool indexed success);

    constructor() Ownable(msg.sender) {}

    function setRelayerStatus(address relayer, bool status) external onlyOwner {
        trustedRelayers[relayer] = status;
    }

    /**
     * @notice Emits arbitrary transaction logs targeted at an external network destination.
     */
    function dispatchMessage(uint32 targetChainId, bytes calldata payload) external {
        bytes32 msgHash = keccak256(abi.encodePacked(block.timestamp, msg.sender, targetChainId, payload));
        emit MessageDispatched(msgHash, targetChainId, msg.sender, payload);
    }

    /**
     * @notice Receives and unpacks authenticated transaction packets forwarded by trusted relayers.
     */
    function executeInboundMessage(
        bytes32 msgHash,
        uint32 sourceChain,
        address sender,
        bytes calldata payload
    ) external {
        require(trustedRelayers[msg.sender], "BridgeError: Caller is not an authorized relayer node");
        require(!inboundRegistry[msgHash].processed, "BridgeError: Message payload already executed");

        bytes32 computedCheck = keccak256(abi.encodePacked(payload));
        
        inboundRegistry[msgHash] = MessagePacket({
            payloadHash: computedCheck,
            sourceChainId: sourceChain,
            sender: sender,
            processed: true
        });

        // In a live production suite, invoke a low-level call payload execution route here
        emit MessageExecuted(msgHash, true);
    }
}
