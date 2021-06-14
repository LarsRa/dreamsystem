// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DreamToken.sol";
import "./TaxPool.sol";

/// @title Dream government
/// @author Lars Raschke
/// @notice This government contract allows users to vote on three different options for collecting taxes in 
/// the dream system on transfering dream tokens - 10%, 20%, or 30% tax on all simple transfers. 
/// In addition the stakers have the option to choose the proportion of the collected taxes in each government
/// cycle, which is send to a lottery contract. The lottery contract should have an external random oracle
/// which is generating a random number. The stakers can participate on the lottery in proportion to their stake.
/// The lottery contract is not implemented yet.
contract DreamGovernment is Ownable {
    using SafeMath for uint256;

    // used ERC20 token
    DreamToken public dreamToken;
    
    // reference to tax pool contract
    TaxPool public taxPool;

    // votable government types and laws
    mapping(uint8 => uint8) public taxRates;
    mapping(uint8 => uint8) public lotteryRates;

    // current set type and laws. holds index for mappings above
    uint8 public taxRateType;
    uint8 public lotteryType;

    // balances of staked tokens by users
    uint256 public totalStakedAmount;
    
    // struct for tracking users available votes
    struct votes {
        uint256 lastVoted;
        uint256 numberOfVotes;
    }
    mapping(address => votes) public usersVotes;
    
    // votes for the two categories
    mapping(uint8 => uint256) public taxRateVotes;
    mapping(uint8 => uint256) public lotteryRateVotes;

    // time periods for one cycle
    uint256 public cycleStartTime;
    uint256 public governmentTenure = 1 hours; //period voted laws lasting
    uint256 public stakingPeriod = 20 minutes; //staking period on the beginning of each cycle
    uint256 public electionPeriod = 30 minutes; //election period on the end of each cycle

    // defining events
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event Voted(address indexed voter, uint256 votes);


    /// @notice Setting initial voting options for the dream system
    constructor() {
        // defining tax rate types for DreamToken transfers
        taxRates[0] = 10; //10% tax rate on every transfer
        taxRates[1] = 20; //20% tax rate on every transfer
        taxRates[2] = 30; //30% tax rate on every transfer

        // defining rate types for lottery pool in the cycle
        lotteryRates[0] = 25; //25% of the collected taxes going to the lottery pool
        lotteryRates[1] = 50; //50% of the collected taxes going to the lottery pool
        lotteryRates[2] = 75; //75% of the collected taxes going to the lottery pool

        // setting default variables
        cycleStartTime = block.timestamp;
        taxRateType = 0;
        lotteryType = 0;
    }

    /// @notice By staking dream tokens the stakers are gaining votes
    /// @param amount The amount a user wants to stake
    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        require(
            block.timestamp > cycleStartTime &&
                block.timestamp < cycleStartTime + stakingPeriod,
            "Staking only during staking period."
        );

        // transfering staked tokens from user to contract
        require(dreamToken.transferFrom(msg.sender, address(this), amount));

        // adding staking amount for voting 
        usersVotes[msg.sender].numberOfVotes = usersVotes[msg.sender].numberOfVotes.add(amount);
        totalStakedAmount = totalStakedAmount.add(amount);

        emit Staked(msg.sender, amount);
    }

    /// @notice By unstaking dream tokens the stakers are loosing votes
    /// @param amount The amount a user wants to unstake
    function unstake(uint256 amount) external {
        require(amount > 0, "Cannot unstake 0");
        require(
            amount >= usersVotes[msg.sender].numberOfVotes,
            "Cannot unstake more then your current stake."
        );
        require(
            block.timestamp > cycleStartTime &&
                block.timestamp < cycleStartTime.add(stakingPeriod),
            "Unstaking only during staking period."
        );

        // transfering staked tokens from contract to user
        require(dreamToken.transferFrom(address(this), msg.sender, amount));
        
        // decreasing available votes for user
        usersVotes[msg.sender].numberOfVotes = usersVotes[msg.sender].numberOfVotes.sub(amount);
        totalStakedAmount = totalStakedAmount.sub(amount);

        emit Unstaked(msg.sender, amount);
    }

    /// @notice The stakers can vote for each option type of the system
    /// @param _taxRateType The option type for tax rates (0 for 10%, 1 for 20%, 2 for 30%)
    /// @param _lotteryRateType The option type for lottery propertion of tax pool (0 for 25%, 1 for 50%, 2 for 75%)
    function voteForGovernment(uint8 _taxRateType, uint8 _lotteryRateType, uint8 _votes) external{
        require(cycleStartTime.add(governmentTenure).sub(electionPeriod) > block.timestamp, "Election period has not started yet.");
        require(cycleStartTime > usersVotes[msg.sender].lastVoted, "You already voted this cycle.");
        require(_taxRateType < 3, "Selected tax rate type has to be 0, 1 or 2.");
        require(_lotteryRateType < 3, "Selected lottery rate type has to be 0, 1 or 2.");
        require(_votes >= usersVotes[msg.sender].numberOfVotes, "You do not have enough available votes.");
        
        // increase the voted laws with users votes
        taxRateVotes[_taxRateType] = taxRateVotes[_taxRateType].add(_votes);
        lotteryRateVotes[_lotteryRateType] = lotteryRateVotes[_lotteryRateType].add(_votes);
        
        emit Voted(msg.sender, _votes);
    }

    /// @notice Finishing the election by setting the laws to the option with the most votes.
    /// resetting the start time restarts a new cycle with the voted laws.
    function finishElection() external {
        require(block.timestamp > cycleStartTime.add(governmentTenure) );
        
        // set voted tax laws
        if (taxRateVotes[0] > taxRateVotes[1] && taxRateVotes[0] > taxRateVotes[2]){
            taxRateType = 0;
        }else if (taxRateVotes[1] > taxRateVotes[2]){
            taxRateType = 1;
        }else{
            taxRateType = 2;
        }
        
        // set voted lottery laws
        if (lotteryRates[0] > lotteryRates[1] && lotteryRates[0] > lotteryRates[2]){
            lotteryType = 0;
        }else if (lotteryRates[1] > lotteryRates[2]){
            taxRateType = 1;
        }else{
            lotteryType = 2;
        }
        
        // set new tax rate for transfers
        dreamToken.setTaxRate(taxRates[taxRateType]);
        
        // start new cycle
        cycleStartTime = block.timestamp;
    }

    /// @notice setting the reference to the dream token
    /// @param tokenAddress The address of the dream token
    function setDreamToken(address tokenAddress) external onlyOwner {
        dreamToken = DreamToken(tokenAddress);
    }
    
    /// @notice Setting the tax pool address by government.
    /// @param _taxPoolAddress The address of the tax pool.
    function setTaxPoolAddress(address _taxPoolAddress) external onlyOwner {
        taxPool = TaxPool(_taxPoolAddress);
    }
    
    /// @notice Getting current lottery rate for sending correct amount from tax pool to lottery.
    function getLotteryRate() external view returns(uint8){
        return lotteryRates[lotteryType];
    }
    
    /// @return address of lottery contract (not implemented yet)
    function getLotteryAddress() external pure returns(address){
        return address(0);
    }
}
