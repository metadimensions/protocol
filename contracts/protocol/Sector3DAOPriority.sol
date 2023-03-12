// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IPriority.sol";
import "./Structs.sol";

contract Sector3DAOPriority is IPriority {
  using SafeERC20 for IERC20;

  address public immutable dao;
  string public title;
  IERC20 public immutable rewardToken;
  uint256 public immutable startTime;
  uint16 public immutable epochDuration;
  uint256 public immutable epochBudget;
  IERC721 public immutable gatingNFT;
  Contribution[] contributions;

  event ContributionAdded(Contribution contribution);
  event RewardClaimed(uint16 epochNumber, address contributor, uint256 amount);

  error EpochNotYetEnded();
  error NoRewardForEpoch();
  error NoGatingNFTOwnership();

  constructor(address dao_, string memory title_, address rewardToken_, uint16 epochDurationInDays, uint256 epochBudget_, address gatingNFT_) {
    dao = dao_;
    title = title_;
    rewardToken = IERC20(rewardToken_);
    startTime = block.timestamp;
    epochDuration = epochDurationInDays;
    epochBudget = epochBudget_;
    gatingNFT = IERC721(gatingNFT_);
  }

  /**
   * Calculates the current epoch index based on the `Priority`'s start time and epoch duration.
   */
  function getepochNumber() public view returns (uint16) {
    uint256 timePassedSinceStart = block.timestamp - startTime;
    uint256 epochDurationInSeconds = epochDuration * 1 days;
    return uint16(timePassedSinceStart / epochDurationInSeconds);
  }

  function addContribution(string memory description, string memory proofURL, uint8 hoursSpent, uint8 alignmentPercentage) public {
    if (address(gatingNFT) != address(0x0)) {
      if (gatingNFT.balanceOf(msg.sender) == 0) {
        revert NoGatingNFTOwnership();
      }
    }
    Contribution memory contribution = Contribution({
      timestamp: block.timestamp,
      epochNumber: getepochNumber(),
      contributor: msg.sender,
      description: description,
      proofURL: proofURL,
      hoursSpent: hoursSpent,
      alignmentPercentage: alignmentPercentage
    });
    contributions.push(contribution);
    emit ContributionAdded(contribution);
  }

  function getContributions() public view returns (Contribution[] memory) {
    return contributions;
  }

  /**
   * Claims a contributor's reward for contributions made in a given epoch.
   * 
   * @param epochNumber The index of an epoch that has ended.
   */
  function claimReward(uint16 epochNumber) public {
    if (epochNumber >= getepochNumber()) {
      revert EpochNotYetEnded();
    }
    uint256 epochReward = getEpochReward(epochNumber, msg.sender);
    if (epochReward == 0) {
      revert NoRewardForEpoch();
    }
    rewardToken.transfer(msg.sender, epochReward);
    emit RewardClaimed(epochNumber, msg.sender, epochReward);
  }

  /**
   * Calculates a contributor's token allocation of the budget for a given epoch.
   * 
   * @param epochNumber The index of an epoch.
   */
  function getEpochReward(uint16 epochNumber, address contributor) public view returns (uint256) {
    uint8 allocationPercentage = getAllocationPercentage(epochNumber, contributor);
    return epochBudget * allocationPercentage / 100;
  }

  /**
   * Calculates a contributor's percentage allocation of the budget for a given epoch.
   * 
   * @param epochNumber The index of an epoch.
   */
  function getAllocationPercentage(uint16 epochNumber, address contributor) public view returns (uint8) {
    uint16 hoursSpentContributor = 0;
    uint16 hoursSpentAllContributors = 0;
    for (uint16 i = 0; i < contributions.length; i++) {
      Contribution memory contribution = contributions[i];
      if (contribution.epochNumber == epochNumber) {
        if (contribution.contributor == contributor) {
          hoursSpentContributor += contribution.hoursSpent;
        }
        hoursSpentAllContributors += contribution.hoursSpent;
      }
    }
    if (hoursSpentAllContributors == 0) {
      return 0;
    } else {
      return uint8(hoursSpentContributor * 100 / hoursSpentAllContributors);
    }
  }
}
