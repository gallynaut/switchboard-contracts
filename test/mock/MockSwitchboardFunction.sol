// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ISwitchboard} from "../../src/ISwitchboard.sol";

/**
 * @title MockSwitchboard
 * @notice TBD
 */
contract MockSwitchboardFunctionV1 {
    //=========================================================================
    // Events
    //=========================================================================

    // [Function Calls]
    event FunctionCallFund(address indexed functionId, address indexed funder, uint256 indexed amount);
    event FunctionCallEvent(address indexed functionId, address indexed sender, address indexed callId, bytes params);

    // [Functions]
    event FunctionFund(address indexed functionId, address indexed funder, uint256 indexed amount);
    event FunctionWithdraw(address indexed functionId, address indexed withdrawer, uint256 indexed amount);
    event FunctionAccountInit(address indexed authority, address indexed accountId);

    // [Attestation Queues]
    event AttestationQueueAccountInit(address indexed authority, address indexed accountId);
    event AddMrEnclave(address indexed queueId, bytes32 mrEnclave);
    event RemoveMrEnclave(address indexed queueId, bytes32 mrEnclave);
    event AttestationQueueSetConfig(address indexed queueId, address indexed authority);
    event AttestationQueuePermissionUpdated(
        address indexed queueId, address indexed granter, address indexed grantee, uint256 permission
    );

    // [Enclaves]
    event EnclaveAccountInit(address indexed signer, address indexed accountId);
    event EnclaveHeartbeat(address indexed enclaveId, address indexed signer);
    event EnclaveGC(address indexed enclaveId, address indexed queue);
    event EnclavePayoutEvent(address indexed nodeId, address indexed enclaveId, uint256 indexed amount);
    event EnclaveVerifyRequest(address indexed queueId, address indexed verifier, address indexed verifiee);
    event EnclaveRotateSigner(address indexed queueId, address indexed oldSigner, address indexed newSigner);

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

    mapping(address => ISwitchboard.SbFunction) _funcs;

    error MissingFunctionId(address);

    struct MockSwitchboardConfig {
        address attestationQueueId;
        address queueAuthority;
        uint256 reward;
    }

    // TODO: requireEstimatedRunCostFee
    // TODO: minimumFee
    constructor(MockSwitchboardConfig memory config) {
        mockAttestationQueueId = config.attestationQueueId;
        mockAttestationQueueAuthority = config.queueAuthority;
        mockAttestationQueueReward = config.reward;
        mockAttestationQueueLastHeartbeat = block.timestamp;
    }

    function createFunctionWithId(
        address functionId,
        string memory name,
        address authority,
        address queueId,
        string memory containerRegistry,
        string memory container,
        string memory version,
        string memory schedule,
        string memory paramsSchema,
        address[] memory permittedCallers
    ) public payable {
        if (queueId != mockAttestationQueueId) {
            revert ISwitchboard.AttestationQueueDoesNotExist(queueId);
        }

        address functionEnclaveId = generateId();

        // setFunctionConfig
        ISwitchboard.FunctionConfig memory functionConfig = ISwitchboard.FunctionConfig({
            schedule: schedule,
            permittedCallers: permittedCallers,
            containerRegistry: containerRegistry,
            container: container,
            version: version,
            paramsSchema: paramsSchema,
            mrEnclaves: new bytes32[](0),
            allowAllFnCalls: false,
            useFnCallEscrow: false
        });

        // setFunctionState
        ISwitchboard.FunctionState memory functionState = ISwitchboard.FunctionState({
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

        _funcs[functionId] = ISwitchboard.SbFunction({
            name: name,
            authority: authority,
            enclaveId: functionEnclaveId,
            queueId: mockAttestationQueueId,
            balance: 0,
            status: ISwitchboard.FunctionStatus.NONE,
            config: functionConfig,
            state: functionState
        });
    }

    function funcExists(address functionId) internal view returns (bool) {
        ISwitchboard.SbFunction memory f = _funcs[functionId];
        if (f.authority == address(0)) {
            return false;
        }
        return true;
    }

    function funcs(address functionId) public view returns (ISwitchboard.SbFunction memory) {
        if (!funcExists(functionId)) {
            revert ISwitchboard.FunctionDoesNotExist(functionId);
        }
        ISwitchboard.SbFunction memory f = _funcs[functionId];

        return ISwitchboard.SbFunction({
            name: f.name,
            authority: f.authority,
            enclaveId: f.enclaveId,
            queueId: f.queueId,
            balance: f.balance,
            status: f.status,
            config: f.config,
            state: f.state
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

    function functionEscrowFund(address functionId) external payable {
        if (!funcExists(functionId)) {
            revert ISwitchboard.FunctionDoesNotExist(functionId);
        }

        ISwitchboard.SbFunction storage f = _funcs[functionId];

        if (f.status == ISwitchboard.FunctionStatus.OUT_OF_FUNDS) {
            f.status = ISwitchboard.FunctionStatus.NONE;
        }

        f.balance += msg.value;
        emit FunctionFund(functionId, msg.sender, msg.value);
    }

    function callFunction(address functionId, bytes memory params) external payable returns (address callId) {
        // address msgSender = getMsgSender();

        if (!funcExists(functionId)) {
            revert ISwitchboard.FunctionDoesNotExist(functionId);
        }

        ISwitchboard.SbFunction storage f = _funcs[functionId];

        // TODO: check estimateRunFee
        // Check permittedCallers

        callId = generateId();

        functionCallId = callId;
        emit FunctionCallEvent(functionId, msg.sender, callId, params);

        if (msg.value > 0) {
            f.balance += msg.value;
            emit FunctionCallFund(functionId, msg.sender, msg.value);
        }
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
