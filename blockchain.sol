// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;
// @title Decentralized Crowdfunding contract

contract funding { 
   
    address public artist; // project creator (artist) 
    uint256 private funding_goal; // funding goal in wei 
    uint256 public campaign_deadline_in_UNIX_timestamp; // timestamp (seconds) after which campaign ends 
    uint256 private _contributed; // total wei contributed 
    bool public is_withdrawn; // whether owner already withdrew (only relevant if goal met) 
    
    address [] private contributers_list;
    mapping(address => uint256) private contributions_list; // each backer's contribution in wei 
    bool private locked; // Reentrancy guard 
    
    // Events for logging 
    event contribution_done(address indexed contributor, uint256 amount); 
    event withdrawal_done(address indexed owner, uint256 amount); 
    event refund_done(address indexed contributor, uint256 amount); 
    
    // Modifiers for most common checks  
    modifier check_owner() 
    { require(msg.sender == artist, "Access denied: only the campaign creator(artist) can perform this action."); 
    _; 
    } 

    modifier check_before_deadline() 
    { 
        require(block.timestamp < campaign_deadline_in_UNIX_timestamp, "This campaign has already ended."); 
    _; 
    } 

    modifier check_after_deadline() 
    { 
        require(block.timestamp >= campaign_deadline_in_UNIX_timestamp, "Campaign is still active."); 
        _; 
    } 

    modifier check_lock() 
    { require(!locked, "function already in use, cant re-enter"); 
    locked = true;
     _; 
     locked = false; 
     } 


    //at the beginning, the artist specifies the deadline and goal for campiagning 
    //The deadline is the current time + duration in seconds
    constructor(uint256 _duration, uint256 _goal) 
    { 
    require(_duration > 0, "Duration must be > 0"); //goal and time must be positive
    require(_goal > 0, "Goal must be > 0"); 
    artist = msg.sender; 
    campaign_deadline_in_UNIX_timestamp = block.timestamp + _duration; 
    funding_goal = _goal; 
    } 
    
    //to contribute by users 
    function user_contribute() public payable check_before_deadline {
        require (msg.value>0 ,"You must send a positive amount of Ether to contribute.");
        if (contributions_list[msg.sender]==0) // added to contributers list
        {
            contributers_list.push(msg.sender);
        }
        contributions_list[msg.sender]= contributions_list[msg.sender]+msg.value;
        _contributed=(_contributed+msg.value);
        emit contribution_done(msg.sender, msg.value);
    }

    //get contributer+contributions list by OWNER ONLY 
    function artist_see_all_contributions() public view check_owner returns (address[] memory contributer_addresses, uint256[] memory contributions_in_wei)
    { 
    uint256 length = contributers_list.length;
    uint256[] memory individual_amounts=new uint256[](length);
    for (uint256 i=0; i<length;i++)
    {
        individual_amounts[i]=contributions_list[contributers_list[i]];
    }
        return (contributers_list, individual_amounts);
    }

    //see all contributers by normal users 
    function see_all_contributions() public view returns (uint256[] memory contributions_in_wei)
    {
    uint256 length = contributers_list.length;
    uint256[] memory individual_amounts=new uint256[](length);
    for (uint256 i=0; i<length;i++)
    {
        individual_amounts[i]=contributions_list[contributers_list[i]];
    }
        return (individual_amounts);
    }

    //see user's contribution
    function get_contribution(address _add) public view check_owner returns (uint256 in_wei, uint in_ether){
        return (contributions_list[_add], contributions_list[_add]/1 ether);
    }

    //see deadline left
    //if remaining time is 0 that means the deadline has reached
    function remainingtime() public view returns (uint256 in_seconds) {
    if (block.timestamp >= campaign_deadline_in_UNIX_timestamp) {
        return 0; // campaign over
    }
    return campaign_deadline_in_UNIX_timestamp - block.timestamp;
}

    //withdraw funds by owner after deadline and goal reached
    function withdraw() public check_owner check_after_deadline check_lock{
        require(_contributed>=funding_goal, "Withdrawal denied: funding goal is not reached.");
        require (!is_withdrawn, "Funds have already been withdrawn.");

        is_withdrawn=true;
        uint256 amount_withdrawn = address(this).balance;//contracts full money right now
        (bool sent, )=payable(artist).call{value: amount_withdrawn}("");
        require(sent, "Transaction failed: unable to transfer funds to the creator.");
        emit withdrawal_done (artist, amount_withdrawn);
    }


    //refund for users 
    function refund () public check_after_deadline check_lock{
        require(_contributed<funding_goal, "Refund unavailable: funding goal was reached.");
        uint256 individual_contri=contributions_list[msg.sender];
        require(individual_contri>0 , "No contributions found for refund.");

        contributions_list[msg.sender]=0;//make that persons contri zero as refunded
        (bool sent, )=payable(msg.sender).call{value:individual_contri}("");
        require(sent, "Refund failed: unable to send funds back to contributor.");
        emit refund_done(msg.sender, individual_contri);
    }

    function get_summary() public view returns (address _artist, uint256 _goal, uint256 _deadline, uint256 _total_contribution_in_wei, uint _total_contribution_in_ether,bool _is_withdrawn, uint256 _contract_balance)
    {
        return (artist, funding_goal/1 ether, campaign_deadline_in_UNIX_timestamp, _contributed, _contributed/1 ether ,is_withdrawn, (address(this).balance)/1 ether);
    }

    function get_Current_Time() public view returns (uint256 in_UNIX_timestamp) {
    return block.timestamp;
    }

    function total_contributed() public view returns (uint256 in_wei, uint256 in_ether){
     return (_contributed, _contributed / 1 ether);
   }
     function campaign_goal() public view returns (uint256 in_wei, uint256 in_ether) {
        return (funding_goal, funding_goal/1 ether);
}
}
