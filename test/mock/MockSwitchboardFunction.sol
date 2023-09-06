// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISwitchboard} from "../../src/ISwitchboard.sol";

/**
 * @title MockSwitchboard
 * @notice TBD
 */
contract MockSwitchboardFunctionV1 {
    address public mockFunctionId;
    address public functionAuthority;
    address public functionQueueId;
    address public functionEnclaveId;
    address[] public functionPermittedCallers;
    uint256 public functionBalance = 0;
    bytes32[] public functionMrEnclaves;
    ISwitchboard.FunctionStatus public functionStatus = ISwitchboard.FunctionStatus.NONE;
    ISwitchboard.FunctionConfig public functionConfig;
    ISwitchboard.FunctionState public functionState;

    address public mockAttestationQueueId;
    address public mockAttestationQueueAuthority;
    address[] public mockAttestationQueueData = new address[](32);
    uint256 public mockAttestationQueueMaxSize = 32;
    uint256 public mockAttestationQueueReward = 10 gwei;
    uint256 public mockAttestationQueueLastHeartbeat;
    bytes32[] public mockAttestationQueueMrEnclaves = new bytes32[](32);
    uint256 public mockAttestationQueueMaxEnclaveVerificationAge = 7 days;
    uint256 public mockAttestationQueueAllowAuthorityOverrideAfter = 7 days;
    uint256 public mockAttestationQueueMaxConsecutiveFunctionFailures = 10000;
    bool public mockAttestationQueueRequireAuthorityHeartbeatPermission = false;
    bool public mockAttestationQueueRequireUsagePermissions = false;
    uint256 public mockAttestationQueueEnclaveTimeout = 7 days;
    uint256 public mockAttestationQueueGcIdx = 0;
    uint256 public currIdx = 0;

    address private functionCallId; // should this be an array?

    uint256 public nonce = 0;

    error MissingFunctionId(address);

    struct MockSwitchboardConfig {
        address attestationQueueId;
        address queueAuthority;
        uint256 reward;
        address functionId;
        address functionAuthority;
        address[] permittedCallers;
    }

    // TODO: requireEstimatedRunCostFee
    // TODO: minimumFee
    constructor(MockSwitchboardConfig memory config) {
        mockAttestationQueueId = config.attestationQueueId;
        mockAttestationQueueAuthority = config.queueAuthority;
        mockAttestationQueueReward = config.reward;
        mockAttestationQueueLastHeartbeat = block.timestamp;

        mockFunctionId = config.functionId;
        functionAuthority = config.functionAuthority;
        functionQueueId = config.attestationQueueId;
        functionPermittedCallers = config.permittedCallers;
        functionEnclaveId = generateId();

        functionConfig = ISwitchboard.FunctionConfig({
            schedule: "",
            permittedCallers: functionPermittedCallers,
            containerRegistry: "dockerhub",
            container: "",
            version: "latest",
            paramsSchema: "",
            mrEnclaves: functionMrEnclaves,
            allowAllFnCalls: false,
            useFnCallEscrow: false
        });

        functionState = ISwitchboard.FunctionState({
            consecutiveFailures: 0,
            lastExecutionTimestamp: 0,
            nextAllowedTimestamp: block.timestamp,
            lastExecutionGasCost: 0,
            triggeredSince: 0,
            triggerCount: 0,
            queueIdx: 0,
            triggered: false,
            createdAt: block.timestamp
        });
    }

    function funcs(address functionId) public view returns (ISwitchboard.SbFunction memory) {
        if (mockFunctionId != functionId) {
            revert ISwitchboard.FunctionDoesNotExist(functionId);
        }

        return ISwitchboard.SbFunction({
            name: "",
            authority: functionAuthority,
            enclaveId: functionEnclaveId,
            queueId: functionQueueId,
            balance: functionBalance,
            status: functionStatus,
            config: functionConfig,
            state: functionState
        });
    }

    function attestationQueues(address attestationQueueId) public view returns (ISwitchboard.AttestationQueue memory) {
        if (attestationQueueId != mockAttestationQueueId) {
            revert ISwitchboard.AttestationQueueDoesNotExist(attestationQueueId);
        }

        return ISwitchboard.AttestationQueue({
            authority: mockAttestationQueueAuthority,
            data: mockAttestationQueueData,
            maxSize: mockAttestationQueueMaxSize,
            reward: mockAttestationQueueReward,
            lastHeartbeat: mockAttestationQueueLastHeartbeat,
            mrEnclaves: mockAttestationQueueMrEnclaves,
            maxEnclaveVerificationAge: mockAttestationQueueMaxEnclaveVerificationAge,
            allowAuthorityOverrideAfter: mockAttestationQueueAllowAuthorityOverrideAfter,
            maxConsecutiveFunctionFailures: mockAttestationQueueMaxConsecutiveFunctionFailures,
            requireAuthorityHeartbeatPermission: mockAttestationQueueRequireAuthorityHeartbeatPermission,
            requireUsagePermissions: mockAttestationQueueRequireUsagePermissions,
            enclaveTimeout: mockAttestationQueueEnclaveTimeout,
            gcIdx: mockAttestationQueueGcIdx,
            currIdx: currIdx
        });
    }

    function callFunction(address functionId, bytes memory params) external payable returns (address callId) {
        // address msgSender = getMsgSender();

        if (functionId != mockFunctionId) {
            revert ISwitchboard.FunctionDoesNotExist(functionId);
        }

        // TODO: check estimateRunFee
        // Check permittedCallers

        callId = generateId();

        functionCallId = callId;
        // Emit FunctionCallEvent
        functionBalance += msg.value;
        // emit FunctionCallFund
    }

    function generateId() internal returns (address) {
        uint256 blockNumber = block.number;
        if (blockNumber > 0) {
            blockNumber -= 1;
        }
        bytes32 h = keccak256(abi.encodePacked(++nonce, blockhash(blockNumber)));
        return address(uint160(uint256(h)));
    }

    function getMsgSender() internal view returns (address payable signer) {
        signer = payable(msg.sender);
        if (msg.data.length >= 20 && signer == address(this)) {
            assembly {
                signer := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        }
    }
}
