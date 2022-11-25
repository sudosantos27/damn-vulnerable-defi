// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RewardToken.sol";
import "../DamnValuableToken.sol";
import "./AccountingToken.sol";

/**
 * @title TheRewarderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)

 */
contract TheRewarderPool {

    // Minimum duration of each round of rewards in seconds
    uint256 private constant REWARDS_ROUND_MIN_DURATION = 5 days;

    uint256 public lastSnapshotIdForRewards; // stores how many tokens have each person
    uint256 public lastRecordedSnapshotTimestamp; // stores in time when were distributed the last rewards 

    mapping(address => uint256) public lastRewardTimestamps; // stores in seconds when was the last time the person claimed rewards

    // Token deposited into the pool by users
    DamnValuableToken public immutable liquidityToken;

    // Token used for internal accounting and snapshots
    // Pegged 1:1 with the liquidity token
    AccountingToken public accToken;
    
    // Token in which rewards are issued
    RewardToken public immutable rewardToken;

    // Track number of rounds
    uint256 public roundNumber;

    constructor(address tokenAddress) {
        // Assuming all three tokens have 18 decimals
        liquidityToken = DamnValuableToken(tokenAddress);
        accToken = new AccountingToken();
        rewardToken = new RewardToken();

        _recordSnapshot();
    }

    /**
     * @notice sender must have approved `amountToDeposit` liquidity tokens in advance
     */
    function deposit(uint256 amountToDeposit) external {
        require(amountToDeposit > 0, "Must deposit tokens");
        
        accToken.mint(msg.sender, amountToDeposit);
        distributeRewards();

        require(
            liquidityToken.transferFrom(msg.sender, address(this), amountToDeposit)
        );
    }

    /**
     * @notice When somenone withdraws their DVT token, the accountToken is burned first based on the amount to withdraw.
     * @dev accToken is pegged 1:1 with the liquidity token
     */
    function withdraw(uint256 amountToWithdraw) external {
        accToken.burn(msg.sender, amountToWithdraw);
        require(liquidityToken.transfer(msg.sender, amountToWithdraw));
    }

    /**
     * @notice first checks if it's time for rewards, if it is, checks how many tokens has each person and the current time 
    the rewards are being distributed. 
     * @dev uint256 lastSnapshotIdForRewards; stores how many tokens have each person
     */
    function distributeRewards() public returns (uint256) {
        uint256 rewards = 0;

        if(isNewRewardsRound()) {   // checks that 5 days have passed
            _recordSnapshot();
        }        
        
        uint256 totalDeposits = accToken.totalSupplyAt(lastSnapshotIdForRewards);
        uint256 amountDeposited = accToken.balanceOfAt(msg.sender, lastSnapshotIdForRewards);

        if (amountDeposited > 0 && totalDeposits > 0) {
            rewards = (amountDeposited * 100 * 10 ** 18) / totalDeposits;

            if(rewards > 0 && !_hasRetrievedReward(msg.sender)) {
                rewardToken.mint(msg.sender, rewards);
                lastRewardTimestamps[msg.sender] = block.timestamp;
            }
        }

        return rewards;     
    }

    /**
     * @dev uint256 lastSnapshotIdForRewards; stores how many tokens have each person
            uint256 lastRecordedSnapshotTimestamp; stores in time when were distributed the last rewards
            uint256 public roundNumber; Tracks number of rounds
     */
    function _recordSnapshot() private {
        lastSnapshotIdForRewards = accToken.snapshot();
        lastRecordedSnapshotTimestamp = block.timestamp;
        roundNumber++;
    }

    /**
     * @notice checks if user has already retrieved rewards
     * @dev mapping(address => uint256) public lastRewardTimestamps; stores in seconds when was the last 
    time the person claimed rewards
            uint256 lastRecordedSnapshotTimestamp; stores in time when were distributed the last rewards 
     */
    function _hasRetrievedReward(address account) private view returns (bool) {
        return (
            lastRewardTimestamps[account] >= lastRecordedSnapshotTimestamp &&
            lastRewardTimestamps[account] <= lastRecordedSnapshotTimestamp + REWARDS_ROUND_MIN_DURATION
        );
    }

    /**
     * @notice checks if 5 days have passed and returns True or False
     * @dev REWARDS_ROUND_MIN_DURATION = 5 days;
     */
    function isNewRewardsRound() public view returns (bool) {
        return block.timestamp >= lastRecordedSnapshotTimestamp + REWARDS_ROUND_MIN_DURATION;
    }
}
