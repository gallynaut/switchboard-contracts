//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title SwitchboardCallbackHandler
/// @author
/// @notice This contract provides modifiers which can optionally be overridden to allow Switchboard Function consumers to validate whether a instruction was invoked from the Switchboard program and corresponds to an expected functionId.
abstract contract SwitchboardCallbackHandler {
    error SwitchboardCallbackHandler__MissingFunctionId();
    error SwitchboardCallbackHandler__InvalidSender(address expected, address received);
    error SwitchboardCallbackHandler__InvalidFunction(address expected, address received);

    function getSwithboardAddress() internal view virtual returns (address);
    function getSwitchboardFunctionId() internal view virtual returns (address);

    modifier isSwitchboardCaller() virtual {
        address expectedSbAddress = getSwithboardAddress();
        address payable receivedCaller = payable(msg.sender);
        if (receivedCaller != expectedSbAddress) {
            revert SwitchboardCallbackHandler__InvalidSender(expectedSbAddress, receivedCaller);
        }
        _;
    }

    modifier isFunctionId() virtual {
        address expectedFunctionId = getSwitchboardFunctionId();

        if (msg.data.length < 20) {
            revert SwitchboardCallbackHandler__MissingFunctionId();
        }

        address receivedFunctionId;
        assembly {
            receivedFunctionId := shr(96, calldataload(sub(calldatasize(), 20)))
        }

        if (receivedFunctionId != expectedFunctionId) {
            revert SwitchboardCallbackHandler__InvalidFunction(expectedFunctionId, receivedFunctionId);
        }
        _;
    }
}
