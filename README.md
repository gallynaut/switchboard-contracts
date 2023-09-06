# Switchboard Contracts

Switchboard EVM contracts for use with Foundry.

<https://book.getfoundry.sh/>

## Install

Add the gitsubmodule to your foundry project

```bash
forge install --no-commit switchboard-xyz/switchboard-contracts
```

Then add the following to your `remappings.txt`

```txt
switchboard-contracts/=lib/switchboard-contracts/
switchboard/=lib/switchboard-contracts/src/
```

**NOTE**: Run `forge remappings > remappings.txt` to generate this file.

## Usage

You can import the Switchboard contracts into your Solidity files like so:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ISwitchboard} from "switchboard/ISwitchboard.sol";
import {SwitchboardHelperConfig} from "switchboard-contracts/script/HelperConfig.s.sol";

contract MyContract {}
```
