# Decentralized Crowdfunding Smart Contract

## Project Overview

This smart contract implements a decentralized crowdfunding platform for artists to raise funds transparently without intermediary fees. The contract ensures that funds are only released to the artist if the funding goal is met by the deadline. If the goal is not reached, all contributors can claim full refunds of their contributions.

The contract provides trust and transparency through blockchain technology, as all stakeholders can see the current status of the campaign and can keep a check on what is happening with their contribution.

---

## Core Components

### State Variables

| Variable | Type | Visibility | Description |
|----------|------|------------|-------------|
| artist | address | public | The campaign creator's Ethereum address |
| funding_goal | uint256 | private | Target amount to raise (in wei) |
| campaign_deadline_in_UNIX_timestamp | uint256 | public | Unix timestamp marking the end of the campaign |
| _contributed | uint256 | private | Total amount contributed so far  |
| is_withdrawn | bool | public | Flag variable indicating whether the creator has withdrawn funds |
| contributers_list | address[] | private | Array storing all contributor addresses |
| contributions_list | mapping | private | Maps each contributor address to their total contribution amount |
| locked | bool | private | Reentrancy guard to prevent reentrant attacks |

---

## Modifiers

### check_owner()
*Purpose*: When applied, it checks that the function can only be accessed by the campaign creator (artist).

*Usage*: Functions such as withdrawal of the funds on end of the campaign and viewing detailed contribution lists, which should only be done by the artist use this modifier.

*Error Message*: "Access denied: only the campaign creator(artist) can perform this action."

---

### check_before_deadline()
*Purpose*: This modifier ensures that the function can only be executed before the campaign deadline.

*Usage*: Applied to contribution functions to prevent contributions after the campaign ends.

*Error Message*: "This campaign has already ended."

---

### check_after_deadline()
*Purpose*: This modifier ensures that the function can only be executed after the campaign deadline has passed.

*Usage*: It is applied to functions such as withdrawal by owner and refund by contributers, as these actions are only valid after the campaign has ended, according to the logic.

*Error Message*: "Campaign is still active."

---

### check_lock()
*Purpose*: This modifier implements a re-entrancy guard to prevent re-entrant attacks.

*Mechanism*:Locked variable is set to true before function execution and reset to false afterward, preventing the same function from being called again while it's still executing.

*Error Message*: "function already in use, cant re-enter"

---

## Functions Used

### Constructor
solidity
constructor(uint256 _duration, uint256 _goal)

*Purpose*: This function enables the artist to initialize a new crowdfunding campaign.

*Parameters*:
- _duration: Campaign duration in seconds
- _goal: Funding goal in wei

*Logic*:
- Validates that both duration and goal are greater than zero
- Sets the caller as the artist
- Calculates campaign deadline as current timestamp plus duration
- Stores the funding goal
---

### receive()
solidity
receive() external payable

*Purpose*: This function allows the contract to accept direct ETH transfers.

*Mechanism*: Automatically calls user_contribute() when ETH is sent directly to the contract address.

---

### user_contribute()
solidity
function user_contribute() public payable check_before_deadline

*Purpose*: This function is a public function which means that any address can call it. It allows users to contribute funds in ETH or wei to the campaign.

*Logic*:
1. Validates that the campaign is still ongoing and contribution amount is positive.
2. If the contributer is contributing to the campaign for the first time, his address is added to the contributers_list.
3. It updates the contributor's total amount contributed in the contributions_list
4. The total amount contributed to the campaign is also updated.
5. Finally logging is done through the contribution_done event
---
### artist_see_all_contributions()
solidity
function artist_see_all_contributions() public view check_owner returns (address[] memory contributer_addresses, uint256[] memory contributions_in_wei)

*Purpose*: This function is restricted to be used by artist only using the check_owner modifier. It allows the artist to view all contributor addresses and their respective contribution amounts.

*Returns*:
- Array of contributor addresses
- Array of corresponding contribution amounts in wei
---
### see_all_contributions()

solidity
function see_all_contributions() public view returns (uint256[] memory contributions_in_wei)

*Purpose*: It’s a public function ( can be viewed by anyone). It allows any user to view all contribution amounts (without seeing contributor addresses). This has been done to preserve anonymity and maintain partial privacy as the specific addresses of the contributions are not shown to normal contributers.

*Returns*: Array of contribution amounts in wei
---
### get_contribution()

solidity
function get_contribution(address _add) public view returns (uint256 in_wei, uint in_ether)

*Purpose*: It’s a public function where the owner can query a particular address and then it returns the contribution amount for that specific address.

*Parameters*:
- _add: Address to query

*Returns*:
- Contribution amount in wei
- Contribution amount in ether
---

### remainingtime()
solidity
function remainingtime() public view returns (uint256 in_seconds)

*Purpose*: It’s a public function that calculates and returns the time remaining until the campaign deadline.


*Returns*: 
- Seconds remaining if campaign is active
- 0 if deadline has passed
---

### withdraw()

solidity
function withdraw() public check_owner check_after_deadline check_lock

*Purpose*: It’s access is only provided to the artist. It allows the artist to withdraw all funds only if the campaign was successful.

*Requirements for the function to be executed*:
- Caller must be the artist
- The campaign must have ended.
- The total contributions must meet or exceed the funding goal.
- The funds must not have been previously withdrawn by the artist in which case the ‘is_withdrawn’ variable will be true.


*Logic*:
1. The function first verifies if the goal has been reached or not.
2. It ensures that the withdrawal shouldn’t have already occurred.
3. Once these conditions are met, the is_withdrawn flag is set to true.
4. The artist can then retrieve the contract's full balance.
5. All funds are transferred to the artist using low-level call.
6. The logging is done through the withdrawal_done event.

*Security*: The function is protected by the reentrancy guard (check_lock) and withdrawal flag. 
---

### refund()

solidity
function refund() public check_after_deadline check_lock

*Purpose*: Allows contributors to claim refunds if the campaign failed to reach its goal.

*Requirements*:
- The campaign deadline must have passed
- The campaign should have failed, i.e. the total contributions must be less than the funding goal
- The caller of the function must have made a contribution.
*Logic*:
1. The function first verifies whether the campaign has failed (goal not reached)
2. It then retrieves the caller's contribution amount.
3. It then validates that the caller has contributions which are to be refunded.
4. The caller's contribution is set to zero (prevents re-claiming). This ensures re-entrancy attack doesn’t happen.
5. The refund amount is transferred back to the caller using low-level call.
6. Logging of the event done through refund_done event.

*Security*: The event is protected by the re-entrancy guard.
---

### get_summary()
solidity
function get_summary() public view returns (
    address _artist, 
    uint256 _goal, 
    uint256 _deadline, 
    uint256 _total_contribution_in_wei, 
    uint _total_contribution_in_ether,
    bool _is_withdrawn, 
    uint256 _contract_balance
)
*Purpose*: This function is a public function and it provides a comprehensive overview of the campaign status.

*Returns*:
- Artist's address
- Funding goal 
- Campaign deadline (Unix timestamp)
- Total contributions in wei
- Total contributions in ether
- Withdrawal status
- Current contract balance 
---

### get_Current_Time()
solidity
function get_Current_Time() public view returns (uint256 in_UNIX_timestamp)

*Purpose*: The function returns the current block timestamp in UNIX.
---

### total_contributed()
solidity
function total_contributed() public view returns (uint256 in_wei, uint256 in_ether)

*Purpose*: This is a public function which returns the total amount contributed to the campaign at any point.

*Returns*:
- Total contributions in wei
- Total contributions in ether
---

### campaign_goal()
solidity
function campaign_goal() public view returns (uint256 in_wei, uint256 in_ether)

*Purpose*:This public function returns the campaign's original funding goal set by the artist in both wei and ether units.
---

## Events

### contribution_done
solidity
event contribution_done(address indexed contributor, uint256 amount)

Emitted when a contribution is successfully made. Logs the contributor's address and amount contributed.

### withdrawal_done
solidity
event withdrawal_done(address indexed owner, uint256 amount)

Emitted when the artist successfully withdraws funds. Logs the artist's address and total amount withdrawn.

### refund_done
solidity
event refund_done(address indexed contributor, uint256 amount)

Emitted when a contributor successfully claims a refund. Logs the contributor's address and refund amount.

---

## Campaign Flow

### Successful Campaign Scenario

1. *Deployment*: Artist deploys contract with funding goal and duration
2. *Contribution Phase*: Multiple contributors send ETH to the contract
3. *Goal Achievement*: Total contributions meet or exceed funding goal
4. *Deadline Passes*: Campaign duration expires
5. *Withdrawal*: Artist calls withdraw() and receives all contributed funds
6. *Result*: Campaign complete, funds transferred to artist

### Failed Campaign Scenario

1. *Deployment*: Artist deploys contract with funding goal and duration
2. *Contribution Phase*: Contributors send ETH to the contract
3. *Goal Not Met*: Total contributions remain below funding goal
4. *Deadline Passes*: Campaign duration expires
5. *Refund Phase*: Each contributor individually calls refund() to recover their contribution
6. *Result*: All contributors receive full refunds, contract balance returns to zero

---

## Security Features

### Reentrancy Protection
The contract implements a reentrancy guard using the locked boolean variable. The check_lock modifier prevents functions from being called again while they are still executing, protecting against reentrancy attacks during fund transfers.

### Checks-Effects-Interactions Pattern
In the refund() function, the contract follows this security pattern:
1. *Checks*: Verifies all conditions (deadline passed, goal not met, contribution exists)
2. *Effects*: Updates state (sets contribution to zero)
3. *Interactions*: Performs external call (sends refund)

This ordering prevents reentrancy vulnerabilities.

### Access Control
Critical functions are protected by modifiers:
- Only the artist can withdraw funds or view detailed contributor information
- Functions can only be called during appropriate time windows (before/after deadline)

### Single Withdrawal Prevention
The is_withdrawn boolean flag ensures the artist can only withdraw funds once, even if called multiple times.

---

## Testing Guide

### Test Case 1: Successful Campaign
1. Deploy contract with goal of 5 ETH and duration of 3600 seconds.
2. Have multiple accounts contribute totaling 5 ETH or more.
3. Wait for deadline to pass.
4. When the artist calls withdraw(), the transaction is successful and the entire funds collected is transferred to artist's account successfully. If the button was clicked before deadline, an error message displaying that the deadline hasn't reached would be given. Also only the owner can do this function.
5. Verify artist received funds and contract balance is zero.

### Test Case 2: Failed Campaign
1. Deploy contract with goal of 10 ETH and duration of 3600 seconds.
2. Have accounts contribute totaling less than 10 ETH (e.g., 6 ETH)
3. Wait for deadline to pass.
4. Each contributor calls refund() and receives their exact contribution back.
5. In this case, the artist clicking withdraw option gives an error.
6. Verify all refunds processed and contract balance is zero.

### Test Case 3: Security Tests
1. Attempt to contribute after deadline (should fail)
2. Attempt to withdraw before deadline (should fail)
3. Non-artist attempts to withdraw (should fail)
4. Attempt to refund when goal was met (should fail)
5. Attempt to withdraw twice (should fail on second attempt)
6. Attempt to claim refund twice (should fail on second attempt)

---

## Known Limitations

1. *Manual Refunds*: Contributors must individually claim refunds; there is no automatic refund distribution mechanism.
2. *Gas Costs*: Contributors bear gas costs for both contributions and refunds
3. *No Partial Refunds*: The contract does not support partial withdrawals or milestone-based funding, the whole amount must be refunded once by the contributer.
4. *Fixed Parameters*: Campaign goal and deadline cannot be modified after deployment.
---

## Deployment Instructions

### Using Remix IDE

1. Open Remix at https://remix.ethereum.org
2. Create a new file named funding.sol
3. Paste the contract code
4. Select Solidity compiler version 0.8.20
5. Compile the contract
6. In Deploy & Run Transactions, select "Remix VM" environment
7. Enter constructor parameters:
   - _duration: Campaign duration in seconds (e.g., 2592000 for 30 days)
   - _goal: Funding goal in wei (e.g., 10000000000000000000 for 10 ETH)
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
- block.timestamp provides the current block's timestamp
- Deadlines are calculated as deployment time plus duration

### Low-Level Calls
The contract uses call() for ETH transfers instead of transfer() or send() because:
- call() forwards all available gas
- It returns a boolean success indicator
- It is the recommended method for sending ETH in modern Solidity
