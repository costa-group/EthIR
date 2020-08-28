pragma solidity 0.5.12;



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/**
 * @title Blocklock
 * @author Brendan Asselstine
 * @notice A time lock with a cooldown period.  When locked, the contract will remain locked until it is unlocked manually
 * or the lock duration expires.  After the contract is unlocked, it cannot be locked until the cooldown duration expires.
 */
library Blocklock {
  using SafeMath for uint256;

  struct State {
    uint256 lockedAt;
    uint256 unlockedAt;
    uint256 lockDuration;
    uint256 cooldownDuration;
  }

  /**
   * @notice Sets the duration of the lock.  This how long the lock lasts before it expires and automatically unlocks.
   * @param self The Blocklock state
   * @param lockDuration The duration, in blocks, that the lock should last.
   */
  function setLockDuration(State storage self, uint256 lockDuration) public {
    require(lockDuration > 0, "Blocklock/lock-min");
    self.lockDuration = lockDuration;
  }

  /**
   * @notice Sets the cooldown duration in blocks.  This is the number of blocks that must pass before being able to
   * lock again.  The cooldown duration begins when the lock duration expires, or when it is unlocked manually.
   * @param self The Blocklock state
   * @param cooldownDuration The duration of the cooldown, in blocks.
   */
  function setCooldownDuration(State storage self, uint256 cooldownDuration) public {
    require(cooldownDuration > 0, "Blocklock/cool-min");
    self.cooldownDuration = cooldownDuration;
  }

  /**
   * @notice Returns whether the state is locked at the given block number.
   * @param self The Blocklock state
   * @param blockNumber The current block number.
   */
  function isLocked(State storage self, uint256 blockNumber) public view returns (bool) {
    uint256 endAt = lockEndAt(self);
    return (
      self.lockedAt != 0 &&
      blockNumber >= self.lockedAt &&
      blockNumber < endAt
    );
  }

  /**
   * @notice Locks the state at the given block number.
   * @param self The Blocklock state
   * @param blockNumber The block number to use as the lock start time
   */
  function lock(State storage self, uint256 blockNumber) public {
    require(canLock(self, blockNumber), "Blocklock/no-lock");
    self.lockedAt = blockNumber;
  }

  /**
   * @notice Manually unlocks the lock.
   * @param self The Blocklock state
   * @param blockNumber The block number at which the lock is being unlocked.
   */
  function unlock(State storage self, uint256 blockNumber) public {
    self.unlockedAt = blockNumber;
  }

  /**
   * @notice Returns whether the Blocklock can be locked at the given block number
   * @param self The Blocklock state
   * @param blockNumber The block number to check against
   * @return True if we can lock at the given block number, false otherwise.
   */
  function canLock(State storage self, uint256 blockNumber) public view returns (bool) {
    uint256 endAt = lockEndAt(self);
    return (
      self.lockedAt == 0 ||
      blockNumber >= endAt.add(self.cooldownDuration)
    );
  }

  function cooldownEndAt(State storage self) internal view returns (uint256) {
    return lockEndAt(self).add(self.cooldownDuration);
  }

  function lockEndAt(State storage self) internal view returns (uint256) {
    uint256 endAt = self.lockedAt.add(self.lockDuration);
    // if we unlocked early
    if (self.unlockedAt >= self.lockedAt && self.unlockedAt < endAt) {
      endAt = self.unlockedAt;
    }
    return endAt;
  }
}