// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract Timelock {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 public _token;

    struct LockupDetails {
        uint256 releaseTime;
        uint256 amount;
    }

    mapping(address => LockupDetails[]) public _lockups;

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(address token_) {
        _token = IERC20(token_);
    }

    /**
     * @dev Locks up tokens
     *
     */
    function lockup(uint256 amount, uint256 releaseTime) external {
        require(block.timestamp < releaseTime, "TokenTimelock: current time must be before release time");
        require(
            _token.allowance(msg.sender, address(this)) > amount - 1,
            "TokenTimelock: must approve ERC20 transfer of desired amount"
        );
        _beforeLockup(msg.sender, amount, releaseTime);
        _token.safeTransferFrom(msg.sender, address(this), amount);
        _lockups[msg.sender].push(LockupDetails(releaseTime, amount));
    }

    function _beforeLockup(
        address staker,
        uint256 amount,
        uint256 releaseTime
    ) internal virtual {
        // do stuff
    }

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function release(uint256 index) external {
        LockupDetails memory lockupInfo = _lockups[msg.sender][index];
        require(block.timestamp > lockupInfo.releaseTime - 1, "TokenTimelock: current time is before release time");
        _beforeRelease(msg.sender, lockupInfo);
        _token.safeTransfer(msg.sender, lockupInfo.amount);
    }

    function _beforeRelease(address staker, LockupDetails memory info) internal virtual {
        // do stuff
    }

    /**
     * @dev Returns the total amount locked up
     */
    function getTotalLockedUp(address beneficiary) public view returns (uint256) {
        uint256 total;
        for (uint256 i; i < _lockups[beneficiary].length; i++) {
            total += _lockups[beneficiary][i].amount;
        }
        return total;
    }

    /**
     * @dev Returns the total amount locked up
     */
    function getLockupDetails(address beneficiary, uint256 index) public view returns (uint256, uint256) {
        require(index < _lockups[beneficiary].length);
        return (_lockups[beneficiary][index].releaseTime, _lockups[beneficiary][index].amount);
    }
}
