pragma solidity ^0.5.11;




library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {

    uint256 c = a + b;

    require(c >= a, "SafeMath: addition overflow");



    return c;

  }



  function sub(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b <= a, "SafeMath: subtraction overflow");

    uint256 c = a - b;



    return c;

  }



  function mul(uint256 a, uint256 b) internal pure returns (uint256) {

    if (a == 0) {

      return 0;

    }



    uint256 c = a * b;

    require(c / a == b, "SafeMath: multiplication overflow");



    return c;

  }



  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b > 0, "SafeMath: division by zero");

    uint256 c = a / b;



    return c;

  }



  function mod(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b != 0, "SafeMath: modulo by zero");

    return a % b;

  }

}





/**

 * @dev Contract module which provides a basic access control mechanism, where

 * there is an account (an owner) that can be granted exclusive access to

 * specific functions.

 *

 * This module is used through inheritance. It will make available the modifier

 * `onlyOwner`, which can be aplied to your functions to restrict their use to

 * the owner.

 *

 * In order to transfer ownership, a recipient must be specified, at which point

 * the specified recipient can call `acceptOwnership` and take ownership.

 */

contract TwoStepOwnable {

  address private _owner;



  address private _newPotentialOwner;



  event OwnershipTransferred(

    address indexed previousOwner,

    address indexed newOwner

  );



  /**

   * @dev Initialize contract by setting transaction submitter as initial owner.

   */

  constructor() internal {

    _owner = tx.origin;

    emit OwnershipTransferred(address(0), _owner);

  }



  /**

   * @dev Returns the address of the current owner.

   */

  function owner() public view returns (address) {

    return _owner;

  }



  /**

   * @dev Throws if called by any account other than the owner.

   */

  modifier onlyOwner() {

    require(isOwner(), "TwoStepOwnable: caller is not the owner.");

    _;

  }



  /**

   * @dev Returns true if the caller is the current owner.

   */

  function isOwner() public view returns (bool) {

    return msg.sender == _owner;

  }



  /**

   * @dev Allows a new account (`newOwner`) to accept ownership.

   * Can only be called by the current owner.

   */

  function transferOwnership(address newOwner) public onlyOwner {

    require(

      newOwner != address(0),

      "TwoStepOwnable: new potential owner is the zero address."

    );



    _newPotentialOwner = newOwner;

  }



  /**

   * @dev Cancel a transfer of ownership to a new account.

   * Can only be called by the current owner.

   */

  function cancelOwnershipTransfer() public onlyOwner {

    _newPotentialOwner = address(0);

  }



  /**

   * @dev Transfers ownership of the contract to the caller.

   * Can only be called by a new potential owner set by the current owner.

   */

  function acceptOwnership() public {

    require(

      msg.sender != _newPotentialOwner,

      "TwoStepOwnable: current owner must set caller as new potential owner."

    );



    delete _newPotentialOwner;



    emit OwnershipTransferred(_owner, msg.sender);



    _owner = msg.sender;

  }

}





/**

 * @title Timelocker

 * @author 0age

 * @notice This contract allows contracts that inherit it to implement timelocks

 * on functions, where the `setTimelock` function must first be called, with the

 * same arguments that the function will be supplied with. Then, a given time

 * interval must first fully transpire before the timelock functions can be

 * successfully called. It also includes a `modifyTimelockInterval` function

 * that is itself able to be timelocked, and that is given a function selector

 * and a new timelock interval for the function as arguments. To make a function

 * timelocked, use the `_enforceTimelock` internal function. To set initial

 * minimum timelock intervals, use the `_setInitialTimelockInterval` internal

 * function - it can only be used from within a constructor. Finally, there are

 * two public getters: `getTimelock` and `getTimelockInterval`.

 */

contract Timelocker {

  using SafeMath for uint256;



  // Fire an event any time a timelock is initiated.

  event TimelockInitiated(

    bytes4 functionSelector, // selector of the function

    uint256 timeComplete,    // timestamp at which the function can be called

    bytes arguments,         // abi-encoded function arguments to call with

    uint256 timeExpired      // timestamp where function can no longer be called

  );



  // Fire an event any time a minimum timelock interval is modified.

  event TimelockIntervalModified(

    bytes4 functionSelector, // selector of the function

    uint256 oldInterval,     // old minimum timelock interval for the function

    uint256 newInterval      // new minimum timelock interval for the function

  );



  // Fire an event any time a default timelock expiration is modified.

  event TimelockExpirationModified(

    bytes4 functionSelector, // selector of the function

    uint256 oldExpiration,   // old default timelock expiration for the function

    uint256 newExpiration    // new default timelock expiration for the function

  );



  // Each timelock has timestamps for when it is complete and when it expires.

  struct Timelock {

    uint128 complete;

    uint128 expires;

  }



  // Implement a timelock for each function and set of arguments.

  mapping(bytes4 => mapping(bytes32 => Timelock)) private _timelocks;



  // Implement a default timelock interval for each timelocked function.

  mapping(bytes4 => uint256) private _timelockIntervals;



  // Implement a default timelock expiration for each timelocked function.

  mapping(bytes4 => uint256) private _timelockExpirations;



  bytes32 private constant _EMPTY_HASH = bytes32(

    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470

  );



  /**

   * @notice Public function for setting a new timelock interval for a given

   * function selector. The default for this function may also be modified, but

   * excessive values will cause the `modifyTimelockInterval` function to become

   * unusable.

   * @param functionSelector the selector of the function to set the timelock

   * interval for.

   * @param newTimelockInterval the new minimum timelock interval to set for the

   * given function.

   */

  function modifyTimelockInterval(

    bytes4 functionSelector,

    uint256 newTimelockInterval

  ) public {

    // Ensure that the new timelock interval will not cause an overflow error.

    require(

      newTimelockInterval < 365000000000000 days,

      "New timelock interval is too large."

    );



    // Ensure that the timelock has been set and is completed.

    _enforceTimelock(

      this.modifyTimelockInterval.selector, abi.encode()

    );



    // Set new timelock interval and emit a `TimelockIntervalModified` event.

    _setTimelockInterval(functionSelector, newTimelockInterval);

  }



  /**

   * @notice Public function for setting a new timelock expiration for a given

   * function selector. Once the minimum interval has elapsed, the timelock will

   * expire once the specified expiration time has elapsed. Setting this value

   * too low will result in timelocks that are very difficult to execute

   * correctly.

   * @param functionSelector the selector of the function to set the timelock

   * expiration for.

   * @param newTimelockExpiration the new minimum timelock expiration to set for

   * the given function.

   */

  function modifyTimelockExpiration(

    bytes4 functionSelector,

    uint256 newTimelockExpiration

  ) public {

    // Ensure that the new timelock expiration will not cause an overflow error.

    require(

      newTimelockExpiration < 365000000000000 days,

      "New timelock expiration is too large."

    );



    // Ensure that the new timelock expiration will not cause an overflow error.

    require(

      newTimelockExpiration > 1 minutes,

      "New timelock expiration is too short."

    );



    // Ensure that the timelock has been set and is completed.

    _enforceTimelock(

      this.modifyTimelockExpiration.selector, abi.encode()

    );



    // Set new default expiration and emit a `TimelockExpirationModified` event.

    _setTimelockExpiration(functionSelector, newTimelockExpiration);

  }



  /**

   * @notice View function to check if a timelock for the specified function and

   * arguments has completed.

   * @param functionSelector function to be called.

   * @param arguments The abi-encoded arguments of the function to be called.

   * @return A boolean indicating if the timelock exists or not and the time at

   * which the timelock completes if it does exist.

   */

  function getTimelock(

    bytes4 functionSelector,

    bytes memory arguments

  ) public view returns (

    bool exists,

    bool completed,

    bool expired,

    uint256 completionTime,

    uint256 expirationTime

  ) {

    // Get timelock ID using the supplied function arguments.

    bytes32 timelockID;

    if (

      functionSelector == this.modifyTimelockInterval.selector ||

      functionSelector == this.modifyTimelockExpiration.selector

    ) {

      timelockID = _EMPTY_HASH;

    } else {

      timelockID = keccak256(abi.encodePacked(arguments));

    }



    // Get information on the current timelock, if one exists.

    completionTime = uint256(_timelocks[functionSelector][timelockID].complete);

    exists = completionTime != 0;

    expirationTime = uint256(_timelocks[functionSelector][timelockID].expires);

    completed = exists && now > completionTime;

    expired = exists && now > expirationTime;

  }



  /**

   * @notice View function to check the current minimum timelock interval on a

   * given function.

   * @param functionSelector function to retrieve the timelock interval for.

   * @return The current minimum timelock interval for the given function.

   */

  function getTimelockInterval(

    bytes4 functionSelector

  ) public view returns (uint256 timelockInterval) {

    timelockInterval = _timelockIntervals[functionSelector];

  }



  /**

   * @notice View function to check the current default timelock expiration on a

   * given function.

   * @param functionSelector function to retrieve the timelock expiration for.

   * @return The current default timelock expiration for the given function.

   */

  function getTimelockExpiration(

    bytes4 functionSelector

  ) public view returns (uint256 timelockExpiration) {

    timelockExpiration = _timelockExpirations[functionSelector];

  }



  /**

   * @notice Internal function that sets a timelock so that the specified

   * function can be called with the specified arguments. Note that existing

   * timelocks may be extended, but not shortened - this can also be used as a

   * method for "cancelling" a function call by extending the timelock to an

   * arbitrarily long duration. Keep in mind that new timelocks may be created

   * with a shorter duration on functions that already have other timelocks on

   * them, but only if they have different arguments.

   * @param functionSelector selector of the function to be called.

   * @param arguments The abi-encoded arguments of the function to be called.

   * @param extraTime Additional time in seconds to add to the minimum timelock

   * interval for the given function.

   */

  function _setTimelock(

    bytes4 functionSelector,

    bytes memory arguments,

    uint256 extraTime

  ) internal {

    // Get timelock using current time, inverval for timelock ID, & extra time.

    uint256 timelock = _timelockIntervals[functionSelector].add(now).add(

      extraTime

    );



    // Get expiration time using timelock duration plus default expiration time.

    uint256 expiration = timelock.add(_timelockExpirations[functionSelector]);



    // Get timelock ID using the supplied function arguments.

    bytes32 timelockID;

    if (

      functionSelector == this.modifyTimelockInterval.selector ||

      functionSelector == this.modifyTimelockExpiration.selector

    ) {

      timelockID = _EMPTY_HASH;

    } else {

      timelockID = keccak256(abi.encodePacked(arguments));

    }



    // Get the current timelock, if one exists.

    Timelock storage timelockStorage = _timelocks[functionSelector][timelockID];



    uint256 currentTimelock = uint256(timelockStorage.complete);



    // Ensure that the timelock duration does not decrease. Note that a new,

    // shorter timelock may still be set up on the same function in the event

    // that it is provided with different arguments.

    require(

      currentTimelock == 0 || timelock > currentTimelock,

      "Existing timelocks may only be extended."

    );



    // Set timelock completion and expiration using timelock ID and extra time.

    timelockStorage.complete = uint128(timelock);

    timelockStorage.expires = uint128(expiration);



    // Emit an event with all of the relevant information.

    emit TimelockInitiated(functionSelector, timelock, arguments, expiration);

  }



  /**

   * @notice Internal function to set an initial timelock interval for a given

   * function selector. Only callable during contract creation.

   * @param functionSelector the selector of the function to set the timelock

   * interval for.

   * @param newTimelockInterval the new minimum timelock interval to set for the

   * given function.

   */

  function _setInitialTimelockInterval(

    bytes4 functionSelector,

    uint256 newTimelockInterval

  ) internal {

    // Ensure that this function is only callable during contract construction.

    assembly { if extcodesize(address) { revert(0, 0) } }



    // Set the timelock interval and emit a `TimelockIntervalModified` event.

    _setTimelockInterval(functionSelector, newTimelockInterval);

  }



  /**

   * @notice Internal function to set an initial timelock expiration for a given

   * function selector. Only callable during contract creation.

   * @param functionSelector the selector of the function to set the timelock

   * expiration for.

   * @param newTimelockExpiration the new minimum timelock expiration to set for

   * the given function.

   */

  function _setInitialTimelockExpiration(

    bytes4 functionSelector,

    uint256 newTimelockExpiration

  ) internal {

    // Ensure that this function is only callable during contract construction.

    assembly { if extcodesize(address) { revert(0, 0) } }



    // Set the timelock interval and emit a `TimelockExpirationModified` event.

    _setTimelockExpiration(functionSelector, newTimelockExpiration);

  }



  /**

   * @notice Internal function to ensure that a timelock is complete or expired

   * and to clear the existing timelock if it is complete so it cannot later be

   * reused.

   * @param functionSelector function to be called.

   * @param arguments The abi-encoded arguments of the function to be called.

   */

  function _enforceTimelock(

    bytes4 functionSelector,

    bytes memory arguments

  ) internal {

    // Get timelock ID using the supplied function arguments.

    bytes32 timelockID = keccak256(abi.encodePacked(arguments));



    // Get the current timelock, if one exists.

    Timelock memory timelock = _timelocks[functionSelector][timelockID];



    uint256 currentTimelock = uint256(timelock.complete);

    uint256 expiration = uint256(timelock.expires);



    // Ensure that the timelock is set and has completed.

    require(

      currentTimelock != 0 && currentTimelock <= now, "Timelock is incomplete."

    );



    // Ensure that the timelock has not expired.

    require(expiration > now, "Timelock has expired.");



    // Clear out the existing timelock so that it cannot be reused.

    delete _timelocks[functionSelector][timelockID];

  }



  /**

   * @notice Private function for setting a new timelock interval for a given

   * function selector.

   * @param functionSelector the selector of the function to set the timelock

   * interval for.

   * @param newTimelockInterval the new minimum timelock interval to set for the

   * given function.

   */

  function _setTimelockInterval(

    bytes4 functionSelector,

    uint256 newTimelockInterval

  ) private {

    // Get the existing timelock interval, if any.

    uint256 oldTimelockInterval = _timelockIntervals[functionSelector];



    // Update the timelock interval on the provided function.

    _timelockIntervals[functionSelector] = newTimelockInterval;



    // Emit a `TimelockIntervalModified` event with the appropriate arguments.

    emit TimelockIntervalModified(

      functionSelector, oldTimelockInterval, newTimelockInterval

    );

  }



  /**

   * @notice Private function for setting a new timelock expiration for a given

   * function selector.

   * @param functionSelector the selector of the function to set the timelock

   * interval for.

   * @param newTimelockExpiration the new default timelock expiration to set for

   * the given function.

   */

  function _setTimelockExpiration(

    bytes4 functionSelector,

    uint256 newTimelockExpiration

  ) private {

    // Get the existing timelock expiration, if any.

    uint256 oldTimelockExpiration = _timelockExpirations[functionSelector];



    // Update the timelock expiration on the provided function.

    _timelockExpirations[functionSelector] = newTimelockExpiration;



    // Emit a `TimelockExpirationModified` event with the appropriate arguments.

    emit TimelockExpirationModified(

      functionSelector, oldTimelockExpiration, newTimelockExpiration

    );

  }

}





interface DharmaSmartWalletRecovery {

  function recover(address newUserSigningKey) external;

}





/**

 * @title DharmaAccountRecoveryManager

 * @author 0age

 * @notice This contract will be owned by DharmaAccountRecoveryMultisig and will

 * manage resets to the user's signing key. It implements a set of timelocked

 * functions, where the `setTimelock` function must first be called, with the

 * same arguments that the function will be supplied with. Then, a given time

 * interval must first fully transpire before the timelock functions can be

 * successfully called.

 *

 * The timelocked functions currently implemented include:

 *  recover(address wallet, address newUserSigningKey)

 *  disableAccountRecovery(address wallet)

 *  modifyTimelockInterval(bytes4 functionSelector, uint256 newTimelockInterval)

 *  modifyTimelockExpiration(

 *    bytes4 functionSelector, uint256 newTimelockExpiration

 *  )

 *

 * Note that special care should be taken to differentiate between lost keys and

 * compromised keys, and that the danger of a user being impersonated is

 * extremely high. Account recovery should progress to a system where the user

 * builds their preferred account recovery procedure into a "key ring" smart

 * contract at their signing address, reserving this "hard reset" for extremely

 * unusual circumstances and eventually sunsetting it entirely.

 */

contract DharmaAccountRecoveryManager is TwoStepOwnable, Timelocker {

  using SafeMath for uint256;



  // Maintain mapping of smart wallets that have opted out of account recovery.

  mapping(address => bool) private _accountRecoveryDisabled;



  /**

   * @notice In the constructor, set the initial owner to the transaction

   * submitter and initial minimum timelock interval and default timelock

   * expiration values.

   */

  constructor() public {

    // Set initial minimum timelock interval values.

    _setInitialTimelockInterval(this.modifyTimelockInterval.selector, 4 weeks);

    _setInitialTimelockInterval(

      this.modifyTimelockExpiration.selector, 4 weeks

    );

    _setInitialTimelockInterval(this.recover.selector, 7 days);

    _setInitialTimelockInterval(this.disableAccountRecovery.selector, 3 days);



    // Set initial default timelock expiration values.

    _setInitialTimelockExpiration(this.modifyTimelockInterval.selector, 7 days);

    _setInitialTimelockExpiration(

      this.modifyTimelockExpiration.selector, 7 days

    );

    _setInitialTimelockExpiration(this.recover.selector, 7 days);

    _setInitialTimelockExpiration(this.disableAccountRecovery.selector, 7 days);

  }



  /**

   * @notice Initiates a timelocked account recovery process for a smart wallet

   * user signing key. Only the owner may call this function. Once the timelock

   * period is complete (and before it has expired) the owner may call `recover`

   * to complete the process and reset the user's signing key.

   * @param smartWallet the smart wallet address.

   * @param userSigningKey the new user signing key.

   * @param extraTime Additional time in seconds to add to the timelock.

   */

  function initiateAccountRecovery(

    address smartWallet, address userSigningKey, uint256 extraTime

  ) external onlyOwner {

    // Set the timelock and emit a `TimelockInitiated` event.

    _setTimelock(

      this.recover.selector, abi.encode(smartWallet, userSigningKey), extraTime

    );

  }



  /**

   * @notice Initiates a timelocked account recovery disablement process for a

   * smart wallet. Only the owner may call this function. Once the timelock

   * period is complete (and before it has expired) the owner may call

   * `disableAccountRecovery` to complete the process and opt a smart wallet out

   * of account recovery. Once account recovery has been disabled, it cannot be

   * reenabled - the process is irreversible.

   * @param smartWallet the smart wallet address.

   * @param extraTime Additional time in seconds to add to the timelock.

   */

  function initiateAccountRecoveryDisablement(

    address smartWallet, uint256 extraTime

  ) external onlyOwner {

    // Set the timelock and emit a `TimelockInitiated` event.

    _setTimelock(

      this.disableAccountRecovery.selector, abi.encode(smartWallet), extraTime

    );

  }



  /**

   * @notice Timelocked function to set a new user signing key on a smart

   * wallet. Only the owner may call this function.

   * @param wallet Address of the smart wallet to recover a key on.

   * @param newUserSigningKey Address of the new signing key for the user.

   */

  function recover(

    address wallet,

    address newUserSigningKey

  ) external onlyOwner {

    // Ensure that the timelock has been set and is completed.

    _enforceTimelock(

      this.recover.selector, abi.encode(wallet, newUserSigningKey)

    );



    // Ensure that the wallet in question has not opted out of account recovery.

    require(

      !_accountRecoveryDisabled[wallet],

      "This wallet has elected to opt out of account recovery functionality."

    );



    // Call the specified smart wallet and supply the new user signing key.

    DharmaSmartWalletRecovery(wallet).recover(newUserSigningKey);

  }



  /**

   * @notice Timelocked function to opt a given wallet out of account recovery.

   * This action cannot be undone - any future account recovery would require an

   * upgrade to the smart wallet implementation itself and is not likely to be

   * supported. Only the owner may call this function.

   * @param wallet Address of the smart wallet to disable account recovery for.

   */

  function disableAccountRecovery(address wallet) external onlyOwner {

    // Ensure that the timelock has been set and is completed.

    _enforceTimelock(this.disableAccountRecovery.selector, abi.encode(wallet));



    // Register the specified wallet as having opted out of account recovery.

    _accountRecoveryDisabled[wallet] = true;

  }



  /**

   * @notice External function check whether a given smart wallet has disabled

   * account recovery by opting out.

   * @param wallet Address of the smart wallet to check.

   * @return A boolean indicating if account recovery has been disabled for the

   * wallet in question.

   */

  function accountRecoveryDisabled(

    address wallet

  ) external view returns (bool hasDisabledAccountRecovery) {

    // Determine if the wallet in question has opted out of account recovery.

    hasDisabledAccountRecovery = _accountRecoveryDisabled[wallet];

  }



  /**

   * @notice Sets a new timelock interval for a given function selector. The

   * default for this function may also be modified, but has a maximum allowable

   * value of eight weeks. Only the owner may call this function.

   * @param functionSelector the selector of the function to set the timelock

   * interval for.

   * @param newTimelockInterval The new timelock interval to set for the given

   * function selector.

   */

  function modifyTimelockInterval(

    bytes4 functionSelector,

    uint256 newTimelockInterval

  ) public onlyOwner {

    // Ensure that a function selector is specified (no 0x00000000 selector).

    require(

      functionSelector != bytes4(0),

      "Function selector cannot be empty."

    );



    // Ensure a timelock interval over eight weeks is not set on this function.

    if (functionSelector == this.modifyTimelockInterval.selector) {

      require(

        newTimelockInterval <= 8 weeks,

        "Timelock interval of modifyTimelockInterval cannot exceed eight weeks."

      );

    }



    // Continue via logic in the inherited `modifyTimelockInterval` function.

    Timelocker.modifyTimelockInterval(functionSelector, newTimelockInterval);

  }

}