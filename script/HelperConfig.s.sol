// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {MockSwitchboardFunctionV1} from "../test/mock/MockSwitchboardFunction.sol";

interface ISwitchboardConfig {}

contract SwitchboardHelperConfig is Script {
    NetworkConfig public activeNetworkConfig;
    uint256 chainid;

    struct NetworkConfig {
        address switchboardAddr;
        address attestationQueueId;
    }

    event HelperConfig__CreatedMockSwitchboardFunction(address mockAddress);

    constructor() {
        chainid = block.chainid;
        // CoreDAO
        if (block.chainid == 1116) {
            activeNetworkConfig = getCoreDaoMainnetConfig();
        } else if (block.chainid == 1115) {
            activeNetworkConfig = getCoreDaoTestnetConfig();
        }
        // Arbitrum
        else if (block.chainid == 42161) {
            activeNetworkConfig = getArbitrumMainnetConfig();
        } else if (block.chainid == 421613) {
            activeNetworkConfig = getArbitrumTestnetConfig();
        }
        // Base
        else if (block.chainid == 8453) {
            activeNetworkConfig = getBaseMainnetConfig();
        } else if (block.chainid == 84531) {
            activeNetworkConfig = getBaseTestnetConfig();
        }
        // Optimism
        else if (block.chainid == 10) {
            activeNetworkConfig = getOptimismMainnetConfig();
        } else if (block.chainid == 420) {
            activeNetworkConfig = getOptimismTestnetConfig();
        }
        // Localnet/Anvil
        else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSwitchboardAddress() public view returns (address) {
        return activeNetworkConfig.switchboardAddr;
    }

    function getAttestationQueueId() public view returns (address) {
        return activeNetworkConfig.attestationQueueId;
    }

    function getCoreDaoMainnetConfig() public pure returns (NetworkConfig memory coreDaoMainnetNetworkConfig) {
        coreDaoMainnetNetworkConfig = NetworkConfig({
            switchboardAddr: 0xE30582eBD4A678065a61975Da113bD2e7aE38679,
            attestationQueueId: 0x929b24A47F87819Be9f210F667C0CF655622453d
        });
    }

    function getCoreDaoTestnetConfig() public pure returns (NetworkConfig memory coreDaoTestnetNetworkConfig) {
        coreDaoTestnetNetworkConfig = NetworkConfig({
            switchboardAddr: 0xf9BD4FA5152b029576F33565Afb676da98Dd0563,
            attestationQueueId: 0x928e9c71007514393bFff60b58D072dEb1309328
        });
    }

    function getArbitrumMainnetConfig() public pure returns (NetworkConfig memory arbitrumMainnetNetworkConfig) {
        arbitrumMainnetNetworkConfig = NetworkConfig({
            switchboardAddr: 0xE30582eBD4A678065a61975Da113bD2e7aE38679,
            attestationQueueId: 0x2D3385BFF20b3EEBA91caEA535569F2dc55c2980
        });
    }

    function getArbitrumTestnetConfig() public pure returns (NetworkConfig memory arbitrumTestnetNetworkConfig) {
        arbitrumTestnetNetworkConfig = NetworkConfig({
            switchboardAddr: 0xA3c9F9F6E40282e1366bdC01C1D30F7F7F58888e,
            attestationQueueId: 0x54f8A91bE5baAD3E2368b00A11bF4012EA6b031F
        });
    }

    function getBaseMainnetConfig() public pure returns (NetworkConfig memory baseMainnetNetworkConfig) {
        baseMainnetNetworkConfig = NetworkConfig({
            switchboardAddr: address(0), // TODO: update
            attestationQueueId: address(0) // TODO: update
        });
    }

    function getBaseTestnetConfig() public pure returns (NetworkConfig memory baseTestnetNetworkConfig) {
        baseTestnetNetworkConfig = NetworkConfig({
            switchboardAddr: 0x9640b33Ef3CB1a8b1f943Fb20FB6ff70d5F4DE96,
            attestationQueueId: 0x80391284b2C81a2E11696EFb8825412c8D0d2a4d
        });
    }

    function getOptimismMainnetConfig() public pure returns (NetworkConfig memory optimismMainnetNetworkConfig) {
        optimismMainnetNetworkConfig = NetworkConfig({
            switchboardAddr: address(0), // TODO: update
            attestationQueueId: address(0) // TODO: update
        });
    }

    function getOptimismTestnetConfig() public pure returns (NetworkConfig memory optimismTestnetNetworkConfig) {
        optimismTestnetNetworkConfig = NetworkConfig({
            switchboardAddr: 0x7d05d5745499D8cc68FA4Eb5dbd45df53E9c3f1f,
            attestationQueueId: 0x455c706AF00af9fCFDA04746Be34c3051aAAD1d4
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory anvilNetworkConfig) {
        // Check to see if we set an active network config
        if (activeNetworkConfig.switchboardAddr != address(0)) {
            return activeNetworkConfig;
        }

        address myQueueId = makeAddr("mySbAttestationQueue");
        // TODO: fix this, should be passed as a param
        // The mock contract needs way more functionality to be useful
        address myFunctionId = makeAddr("mySbFunction");

        vm.startBroadcast();
        MockSwitchboardFunctionV1 mockSwitchboard = new MockSwitchboardFunctionV1(
            MockSwitchboardFunctionV1.MockSwitchboardConfig({
                attestationQueueId: myQueueId,
                queueAuthority: msg.sender,
                reward: 10 gwei,
                functionId: myFunctionId,
                functionAuthority: msg.sender,
                permittedCallers: new address[](0)
            })

        );
        emit HelperConfig__CreatedMockSwitchboardFunction(address(mockSwitchboard));
        vm.stopBroadcast();

        anvilNetworkConfig = NetworkConfig({switchboardAddr: address(mockSwitchboard), attestationQueueId: myQueueId});
    }
}
