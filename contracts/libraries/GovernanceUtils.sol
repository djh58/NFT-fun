pragma solidity ^0.8.9;

library GovernanceUtils {
    uint256 public constant MAX_VESTING_TIME = 4 * 365 days;

    function calculateVotes(uint256 amount, uint256 lockupPeriod) internal view returns (uint256) {
        // the longer the lockup period, the more votes per amount tokens
        return (amount * lockupPeriod) / MAX_VESTING_TIME;
    }

    function stringify(uint256 amount, uint256 votes) internal pure returns (string memory) {
        return string(abi.encode(amount, votes));
    }

    function getDetails(string memory _details) internal pure returns (uint256 amount, uint256 votes) {
        (amount, votes) = abi.decode(bytes(_details), (uint256, uint256));
        return (amount, votes);
    }

    function resetVotes(string memory _details) internal pure returns (string memory) {
        (uint256 amount, ) = abi.decode(bytes(_details), (uint256, uint256));
        return stringify(amount, 0);
    }
}
