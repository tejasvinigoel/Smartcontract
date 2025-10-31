# Decentralized Crowdfunding Smart Contract

## Project Overview

This smart contract implements a decentralized crowdfunding platform for artists and creators to raise funds transparently without intermediary fees. The contract ensures that funds are only released to the creator if the funding goal is met by the deadline. If the goal is not reached, all contributors can claim full refunds of their contributions.

The contract operates on an all-or-nothing funding model, providing trust and transparency through blockchain technology.

---

## Core Components

### State Variables

| Variable | Type | Visibility | Description |
|----------|------|------------|-------------|
| `artist` | address | public | The campaign creator's Ethereum address |
| `funding_goal` | uint256 | private | Target amount to raise (in wei) |
| `campaign_deadline_in_UNIX_timestamp` | uint256 | public | Unix timestamp marking the end of the campaign |
| `_contributed` | uint256 | private | Total amount contributed so far (in wei) |
| `is_withdrawn` | bool | public | Flag indicating whether the creator has withdrawn funds |
| `contributers_list` | address[] | private | Array storing all contributor addresses |
| `contributions_list` | mapping | private | Maps each contributor address to their total contribution amount |
| `locked` | bool | private | Reentrancy guard to prevent reentrant attacks |

---

## Modifiers

### check_owner()
**Purpose**: Restricts function access to only the campaign creator (artist).

**Usage**: Applied to functions that should only be callable by the artist, such as withdrawal and viewing detailed contribution lists.

**Error Message**: "Access denied: only the campaign creator(artist) can perform this action."

---

### check_before_deadline()
**Purpose**: Ensures the function can only be executed before the campaign deadline.

**Usage**: Applied to contribution functions to prevent contributions after the campaign ends.

**Error Message**: "This campaign has already ended."

---

### check_after_deadline()
**Purpose**: Ensures the function can only be executed after the campaign deadline has passed.

**Usage**: Applied to withdrawal and refund functions, as these actions are only valid after the campaign concludes.

**Error Message**: "Campaign is still active."

---

### check_lock()
**Purpose**: Implements a reentrancy guard to prevent reentrant attacks.

**Mechanism**: Sets `locked` to true before function execution and resets it to false afterward, preventing the same function from being called again while it's still executing.

**Error Message**: "function already in use, cant re-enter"

---

## Functions

### Constructor
```solidity
constructor(uint256 _duration, uint256 _goal)
```

**Purpose**: Initializes a new crowdfunding campaign.

**Parameters**:
- `_duration`: Campaign duration in seconds
- `_goal`: Funding goal in wei

**Logic**:
- Validates that both duration and goal are greater than zero
- Sets the caller as the artist
- Calculates deadline as current timestamp plus duration
- Stores the funding goal

**Example**: To create a campaign with a 10 ETH goal lasting 30 days:
```
_duration: 2592000 (30 days in seconds)
_goal: 10000000000000000000 (10 ETH in wei)
```

---

### receive()
```solidity
receive() external payable
```

**Purpose**: Allows the contract to accept direct ETH transfers.

**Mechanism**: Automatically calls `user_contribute()` when ETH is sent directly to the contract address.

---

### user_contribute()
```solidity
function user_contribute() public payable check_before_deadline
```

**Purpose**: Allows users to contribute ETH to the campaign.

**Requirements**:
- Campaign must be ongoing (before deadline)
- Contribution amount must be greater than zero

**Logic**:
1. Validates positive contribution amount
2. Adds contributor to `contributers_list` if first-time contributor
3. Updates the contributor's total in `contributions_list`
4. Increments total contributed amount
5. Emits `contribution_done` event

**Access**: Public - any address can contribute

---

### artist_see_all_contributions()
```solidity
function artist_see_all_contributions() public view check_owner 
    returns (address[] memory contributer_addresses, uint256[] memory contributions_in_wei)
```

**Purpose**: Allows the artist to view all contributor addresses and their respective contribution amounts.

**Returns**:
- Array of contributor addresses
- Array of corresponding contribution amounts in wei

**Access**: Restricted to artist only

---

### see_all_contributions()
```solidity
function see_all_contributions() public view 
    returns (uint256[] memory contributions_in_wei)
```

**Purpose**: Allows any user to view all contribution amounts (without seeing contributor addresses).

**Returns**: Array of contribution amounts in wei

**Access**: Public - anyone can view

**Privacy Note**: This maintains partial privacy by showing amounts but not linking them to specific addresses for non-artist viewers.

---

### get_contribution()
```solidity
function get_contribution(address _add) public view 
    returns (uint256 in_wei, uint in_ether)
```

**Purpose**: Returns the contribution amount for a specific address.

**Parameters**:
- `_add`: Address to query

**Returns**:
- Contribution amount in wei
- Contribution amount in ether (for convenience)

**Access**: Public - anyone can query any address

---

### remainingtime()
```solidity
function remainingtime() public view returns (uint256 in_seconds)
```

**Purpose**: Calculates and returns the time remaining until the campaign deadline.

**Returns**: 
- Seconds remaining if campaign is active
- 0 if deadline has passed

**Access**: Public view function

---

### withdraw()
```solidity
function withdraw() public check_owner check_after_deadline check_lock
```

**Purpose**: Allows the artist to withdraw all funds if the campaign was successful.

**Requirements**:
- Caller must be the artist
- Deadline must have passed
- Total contributions must meet or exceed the funding goal
- Funds must not have been previously withdrawn

**Logic**:
1. Verifies goal was reached
2. Checks that withdrawal hasn't already occurred
3. Sets `is_withdrawn` flag to true
4. Retrieves contract's full balance
5. Transfers all funds to the artist using low-level call
6. Emits `withdrawal_done` event

**Security**: Protected by reentrancy guard (`check_lock`) and withdrawal flag

---

### refund()
```solidity
function refund() public check_after_deadline check_lock
```

**Purpose**: Allows contributors to claim refunds if the campaign failed to reach its goal.

**Requirements**:
- Deadline must have passed
- Total contributions must be less than the funding goal
- Caller must have made a contribution

**Logic**:
1. Verifies campaign failed (goal not reached)
2. Retrieves caller's contribution amount
3. Validates caller has contributions to refund
4. Sets caller's contribution to zero (prevents re-claiming)
5. Transfers refund amount back to caller using low-level call
6. Emits `refund_done` event

**Security**: Protected by reentrancy guard and checks-effects-interactions pattern

---

### get_summary()
```solidity
function get_summary() public view returns (
    address _artist, 
    uint256 _goal, 
    uint256 _deadline, 
    uint256 _total_contribution_in_wei, 
    uint _total_contribution_in_ether,
    bool _is_withdrawn, 
    uint256 _contract_balance
)
```

**Purpose**: Provides a comprehensive overview of the campaign status.

**Returns**:
- Artist's address
- Funding goal (in ether)
- Campaign deadline (Unix timestamp)
- Total contributions in wei
- Total contributions in ether
- Withdrawal status
- Current contract balance (in ether)

**Access**: Public view function

---

### get_Current_Time()
```solidity
function get_Current_Time() public view returns (uint256 in_UNIX_timestamp)
```

**Purpose**: Returns the current block timestamp.

**Returns**: Current Unix timestamp

**Use Case**: Helpful for testing and verifying deadline calculations

---

### total_contributed()
```solidity
function total_contributed() public view returns (uint256 in_wei, uint256 in_ether)
```

**Purpose**: Returns the total amount contributed to the campaign.

**Returns**:
- Total contributions in wei
- Total contributions in ether

**Access**: Public view function

---

### campaign_goal()
```solidity
function campaign_goal() public view returns (uint256 in_wei, uint256 in_ether)
```

**Purpose**: Returns the campaign's funding goal.

**Returns**:
- Funding goal in wei
- Funding goal in ether

**Access**: Public view function

---

## Events

### contribution_done
```solidity
event contribution_done(address indexed contributor, uint256 amount)
```
Emitted when a contribution is successfully made. Logs the contributor's address and amount contributed.

### withdrawal_done
```solidity
event withdrawal_done(address indexed owner, uint256 amount)
```
Emitted when the artist successfully withdraws funds. Logs the artist's address and total amount withdrawn.

### refund_done
```solidity
event refund_done(address indexed contributor, uint256 amount)
```
Emitted when a contributor successfully claims a refund. Logs the contributor's address and refund amount.

---

## Campaign Flow

### Successful Campaign Scenario

1. **Deployment**: Artist deploys contract with funding goal and duration
2. **Contribution Phase**: Multiple contributors send ETH to the contract
3. **Goal Achievement**: Total contributions meet or exceed funding goal
4. **Deadline Passes**: Campaign duration expires
5. **Withdrawal**: Artist calls `withdraw()` and receives all contributed funds
6. **Result**: Campaign complete, funds transferred to artist

### Failed Campaign Scenario

1. **Deployment**: Artist deploys contract with funding goal and duration
2. **Contribution Phase**: Contributors send ETH to the contract
3. **Goal Not Met**: Total contributions remain below funding goal
4. **Deadline Passes**: Campaign duration expires
5. **Refund Phase**: Each contributor individually calls `refund()` to recover their contribution
6. **Result**: All contributors receive full refunds, contract balance returns to zero

---

## Security Features

### Reentrancy Protection
The contract implements a reentrancy guard using the `locked` boolean variable. The `check_lock` modifier prevents functions from being called again while they are still executing, protecting against reentrancy attacks during fund transfers.

### Checks-Effects-Interactions Pattern
In the `refund()` function, the contract follows this security pattern:
1. **Checks**: Verifies all conditions (deadline passed, goal not met, contribution exists)
2. **Effects**: Updates state (sets contribution to zero)
3. **Interactions**: Performs external call (sends refund)

This ordering prevents reentrancy vulnerabilities.

### Access Control
Critical functions are protected by modifiers:
- Only the artist can withdraw funds or view detailed contributor information
- Functions can only be called during appropriate time windows (before/after deadline)

### Single Withdrawal Prevention
The `is_withdrawn` boolean flag ensures the artist can only withdraw funds once, even if called multiple times.

---

## Testing Guide

### Test Case 1: Successful Campaign
1. Deploy contract with goal of 5 ETH and duration of 3600 seconds
2. Have multiple accounts contribute totaling 5 ETH or more
3. Wait for deadline to pass (or use time manipulation in test environment)
4. Artist calls `withdraw()` successfully
5. Verify artist received funds and contract balance is zero

### Test Case 2: Failed Campaign
1. Deploy contract with goal of 10 ETH and duration of 3600 seconds
2. Have accounts contribute totaling less than 10 ETH (e.g., 6 ETH)
3. Wait for deadline to pass
4. Each contributor calls `refund()` and receives their exact contribution back
5. Verify all refunds processed and contract balance is zero

### Test Case 3: Security Tests
1. Attempt to contribute after deadline (should fail)
2. Attempt to withdraw before deadline (should fail)
3. Non-artist attempts to withdraw (should fail)
4. Attempt to refund when goal was met (should fail)
5. Attempt to withdraw twice (should fail on second attempt)
6. Attempt to claim refund twice (should fail on second attempt)

---

## Known Limitations

1. **Manual Refunds**: Contributors must individually claim refunds; there is no automatic refund distribution mechanism
2. **Gas Costs**: Contributors bear gas costs for both contributions and refunds
3. **No Partial Refunds**: The contract does not support partial withdrawals or milestone-based funding
4. **Fixed Parameters**: Campaign goal and deadline cannot be modified after deployment
5. **Privacy**: While `see_all_contributions()` hides addresses from non-artists, contribution amounts are publicly visible

---

## Deployment Instructions

### Using Remix IDE

1. Open Remix at https://remix.ethereum.org
2. Create a new file named `funding.sol`
3. Paste the contract code
4. Select Solidity compiler version 0.8.20
5. Compile the contract
6. In Deploy & Run Transactions, select "Remix VM" environment
7. Enter constructor parameters:
   - `_duration`: Campaign duration in seconds (e.g., 2592000 for 30 days)
   - `_goal`: Funding goal in wei (e.g., 10000000000000000000 for 10 ETH)
8. Click Deploy
9. Interact with the deployed contract using the function buttons

---

## Technical Notes

### Wei and Ether Conversions
- 1 ETH = 1,000,000,000,000,000,000 wei (10^18)
- The contract stores values in wei for precision
- Many view functions return both wei and ether values for convenience

### Unix Timestamps
- Solidity uses Unix timestamps (seconds since January 1, 1970)
- `block.timestamp` provides the current block's timestamp
- Deadlines are calculated as deployment time plus duration

### Low-Level Calls
The contract uses `call()` for ETH transfers instead of `transfer()` or `send()` because:
- `call()` forwards all available gas
- It returns a boolean success indicator
- It is the recommended method for sending ETH in modern Solidity
