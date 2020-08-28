// File: contracts/SafeMath.sol

/**	
* MIT License	
*	
* Copyright (c) 2016-2019 zOS Global Limited	
*	
* Permission is hereby granted, free of charge, to any person obtaining a copy	
* of this software and associated documentation files (the "Software"), to deal	
* in the Software without restriction, including without limitation the rights	
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell	
* copies of the Software, and to permit persons to whom the Software is	
* furnished to do so, subject to the following conditions:	
*	
* The above copyright notice and this permission notice shall be included in all	
* copies or substantial portions of the Software.	
*	
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR	
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,	
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE	
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER	
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,	
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE	
* SOFTWARE.	
*/

pragma solidity 0.5.10;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/IERC20.sol

/**	
* MIT License	
*	
* Copyright (c) 2016-2019 zOS Global Limited	
*	
* Permission is hereby granted, free of charge, to any person obtaining a copy	
* of this software and associated documentation files (the "Software"), to deal	
* in the Software without restriction, including without limitation the rights	
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell	
* copies of the Software, and to permit persons to whom the Software is	
* furnished to do so, subject to the following conditions:	
*	
* The above copyright notice and this permission notice shall be included in all	
* copies or substantial portions of the Software.	
*	
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR	
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,	
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE	
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER	
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,	
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE	
* SOFTWARE.	
*/

pragma solidity 0.5.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/ERC20.sol

/**	
* MIT License	
*	
* Copyright (c) 2016-2019 zOS Global Limited	
*	
* Permission is hereby granted, free of charge, to any person obtaining a copy	
* of this software and associated documentation files (the "Software"), to deal	
* in the Software without restriction, including without limitation the rights	
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell	
* copies of the Software, and to permit persons to whom the Software is	
* furnished to do so, subject to the following conditions:	
*	
* The above copyright notice and this permission notice shall be included in all	
* copies or substantial portions of the Software.	
*	
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR	
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,	
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE	
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER	
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,	
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE	
* SOFTWARE.	
*/

pragma solidity 0.5.10;



/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

// File: contracts/ERC20Claimable.sol

/**
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2019 Equility AG (alethena.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity 0.5.10;




/**
 * @title Claimable
 * In case of tokens that represent real-world assets such as shares of a company, one needs a way
 * to handle lost private keys. With physical certificates, courts can declare share certificates as
 * invalid so the company can issue replacements. Here, we want a solution that does not depend on
 * third parties to resolve such cases. Instead, when someone has lost a private key, he can use the
 * declareLost function to post a deposit and claim that the shares assigned to a specific address are
 * lost. To prevent front running, a commit reveal scheme is used. If he actually is the owner of the shares,
 * he needs to wait for a certain period and can then reclaim the lost shares as well as the deposit.
 * If he is an attacker trying to claim shares belonging to someone else, he risks losing the deposit
 * as it can be claimed at anytime by the rightful owner.
 * Furthermore, if "getClaimDeleter" is defined in the subclass, the returned address is allowed to
 * delete claims, returning the collateral. This can help to prevent obvious cases of abuse of the claim
 * function.
 */

contract ERC20Claimable is ERC20 {

    using SafeMath for uint256;
    using SafeMath for uint32;

    // A struct that represents a claim made
    struct Claim {
        address claimant; // the person who created the claim
        uint256 collateral; // the amount of collateral deposited
        uint32 timestamp;  // the timestamp of the block in which the claim was made
        address currencyUsed; // The currency (XCHF) can be updated, we record the currency used for every request
    }

    // Every claim must be preceded by an obscured preclaim in order to prevent front-running
    struct PreClaim {
        bytes32 msghash; // the hash of nonce + address to be claimed
        uint256 timestamp;  // the timestamp of the block in which the preclaim was made
    }

    uint256 public claimPeriod = 180 days; // Default of 180 days;
    uint256 public preClaimPeriod = 1 days; // One day. Minimum waiting period between preClaim and Claim;
    uint256 public preClaimPeriodEnd = 2 days; // Two days. Maximum waiting period between preClaim and Claim;

    mapping(address => Claim) public claims; // there can be at most one claim per address, here address is claimed address
    mapping(address => PreClaim) public preClaims; // there can be at most one preclaim per address, here address is claimer
    mapping(address => bool) public claimingDisabled; // disable claimability (e.g. for long term storage)

    // ERC-20 token that can be used as collateral or 0x0 if disabled
    address public customCollateralAddress;
    uint256 public customCollateralRate;

    /**
     * Returns the collateral rate for the given collateral type and 0 if that type
     * of collateral is not accepted. By default, only the token itself is accepted at
     * a rate of 1:1.
     *
     * Subclasses should override this method if they want to add additional types of
     * collateral.
     */
    function getCollateralRate(address collateralType) public view returns (uint256) {
        if (collateralType == address(this)) {
            return 1;
        } else if (collateralType == customCollateralAddress) {
            return customCollateralRate;
        } else {
            return 0;
        }
    }

    /**
     * Allows subclasses to set a custom collateral besides the token itself.
     * The collateral must be an ERC-20 token that returns true on successful transfers and
     * throws an exception or returns false on failure.
     * Also, do not forget to multiply the rate in accordance with the number of decimals of the collateral.
     * For example, rate should be 7*10**18 for 7 units of a collateral with 18 decimals.
     */
    function _setCustomClaimCollateral(address collateral, uint256 rate) internal {
        customCollateralAddress = collateral;
        if (customCollateralAddress == address(0)) {
            customCollateralRate = 0; // disabled
        } else {
            require(rate > 0, "Collateral rate can't be zero");
            customCollateralRate = rate;
        }
        emit CustomClaimCollateralChanged(collateral, rate);
    }

    function getClaimDeleter() public returns (address);

    /**
     * Allows subclasses to change the claim period, but not to fewer than 90 days.
     */
    function _setClaimPeriod(uint256 claimPeriodInDays) internal {
        require(claimPeriodInDays > 90, "Claim period must be at least 90 days"); // must be at least 90 days
        uint256 claimPeriodInSeconds = claimPeriodInDays.mul(1 days);
        claimPeriod = claimPeriodInSeconds;
        emit ClaimPeriodChanged(claimPeriod);
    }

    function setClaimable(bool enabled) public {
        claimingDisabled[msg.sender] = !enabled;
    }

    /**
     * Some users might want to disable claims for their address completely.
     * For example if they use a deep cold storage solution or paper wallet.
     */
    function isClaimsEnabled(address target) public view returns (bool) {
        return !claimingDisabled[target];
    }

    event ClaimMade(address indexed lostAddress, address indexed claimant, uint256 balance);
    event ClaimPrepared(address indexed claimer);
    event ClaimCleared(address indexed lostAddress, uint256 collateral);
    event ClaimDeleted(address indexed lostAddress, address indexed claimant, uint256 collateral);
    event ClaimResolved(address indexed lostAddress, address indexed claimant, uint256 collateral);
    event ClaimPeriodChanged(uint256 newClaimPeriodInDays);
    event CustomClaimCollateralChanged(address newCustomCollateralAddress, uint256 newCustomCollareralRate);

  /** Anyone can declare that the private key to a certain address was lost by calling declareLost
    * providing a deposit/collateral. There are three possibilities of what can happen with the claim:
    * 1) The claim period expires and the claimant can get the deposit and the shares back by calling resolveClaim
    * 2) The "lost" private key is used at any time to call clearClaim. In that case, the claim is deleted and
    *    the deposit sent to the shareholder (the owner of the private key). It is recommended to call resolveClaim
    *    whenever someone transfers funds to let claims be resolved automatically when the "lost" private key is
    *    used again.
    * 3) The owner deletes the claim and assigns the deposit to the claimant. This is intended to be used to resolve
    *    disputes. Generally, using this function implies that you have to trust the issuer of the tokens to handle
    *    the situation well. As a rule of thumb, the contract owner should assume the owner of the lost address to be the
    *    rightful owner of the deposit.
    * It is highly recommended that the owner observes the claims made and informs the owners of the claimed addresses
    * whenever a claim is made for their address (this of course is only possible if they are known to the owner, e.g.
    * through a shareholder register).
    * To prevent frontrunning attacks, a claim can only be made if the information revealed when calling "declareLost"
    * was previously commited using the "prepareClaim" function.
    */
    function prepareClaim(bytes32 hashedpackage) public {
        preClaims[msg.sender] = PreClaim({
            msghash: hashedpackage,
            timestamp: block.timestamp
        });
        emit ClaimPrepared(msg.sender);
    }

    function validateClaim(address lostAddress, bytes32 nonce) private view {
        PreClaim memory preClaim = preClaims[msg.sender];
        require(preClaim.msghash != 0, "Message hash can't be zero");
        require(preClaim.timestamp.add(preClaimPeriod) <= block.timestamp, "Preclaim period violated. Claimed too early");
        require(preClaim.timestamp.add(preClaimPeriodEnd) >= block.timestamp, "Preclaim period end. Claimed too late");
        require(preClaim.msghash == keccak256(abi.encodePacked(nonce, msg.sender, lostAddress)),"Package could not be validated");
    }

    function declareLost(address collateralType, address lostAddress, bytes32 nonce) public {
        require(lostAddress != address(0), "Can't claim zero address");
        require(isClaimsEnabled(lostAddress), "Claims disabled for this address");
        uint256 collateralRate = getCollateralRate(collateralType);
        require(collateralRate > 0, "Unsupported collateral type");
        address claimant = msg.sender;
        uint256 balance = balanceOf(lostAddress);
        uint256 collateral = balance.mul(collateralRate);
        IERC20 currency = IERC20(collateralType);
        require(balance > 0, "Claimed address holds no shares");
        require(currency.allowance(claimant, address(this)) >= collateral, "Currency allowance insufficient");
        require(currency.balanceOf(claimant) >= collateral, "Currency balance insufficient");
        require(claims[lostAddress].collateral == 0, "Address already claimed");
        validateClaim(lostAddress, nonce);
        require(currency.transferFrom(claimant, address(this), collateral), "Collateral transfer failed");

        claims[lostAddress] = Claim({
            claimant: claimant,
            collateral: collateral,
            timestamp: uint32(block.timestamp), // block timestamp is in seconds --> Should not overflow
            currencyUsed: collateralType
        });

        delete preClaims[claimant];
        emit ClaimMade(lostAddress, claimant, balance);
    }

    function getClaimant(address lostAddress) public view returns (address) {
        return claims[lostAddress].claimant;
    }

    function getCollateral(address lostAddress) public view returns (uint256) {
        return claims[lostAddress].collateral;
    }

    function getCollateralType(address lostAddress) public view returns (address) {
        return claims[lostAddress].currencyUsed;
    }

    function getTimeStamp(address lostAddress) public view returns (uint256) {
        return claims[lostAddress].timestamp;
    }

    function getPreClaimTimeStamp(address claimerAddress) public view returns (uint256) {
        return preClaims[claimerAddress].timestamp;
    }

    function getMsgHash(address claimerAddress) public view returns (bytes32) {
        return preClaims[claimerAddress].msghash;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(super.transfer(recipient, amount), "Transfer failed");
        clearClaim();
        return true;
    }

    /**
     * Clears a claim after the key has been found again and assigns the collateral to the "lost" address.
     * This is the price an adverse claimer pays for filing a false claim and makes it risky to do so.
     */
    function clearClaim() public {
        if (claims[msg.sender].collateral != 0) {
            uint256 collateral = claims[msg.sender].collateral;
            IERC20 currency = IERC20(claims[msg.sender].currencyUsed);
            delete claims[msg.sender];
            require(currency.transfer(msg.sender, collateral), "Collateral transfer failed");
            emit ClaimCleared(msg.sender, collateral);
        }
    }

   /**
    * After the claim period has passed, the claimant can call this function to send the
    * tokens on the lost address as well as the collateral to himself.
    */
    function resolveClaim(address lostAddress) public {
        Claim memory claim = claims[lostAddress];
        uint256 collateral = claim.collateral;
        IERC20 currency = IERC20(claim.currencyUsed);
        require(collateral != 0, "No claim found");
        require(claim.claimant == msg.sender, "Only claimant can resolve claim");
        require(claim.timestamp.add(uint32(claimPeriod)) <= block.timestamp, "Claim period not over yet");
        address claimant = claim.claimant;
        delete claims[lostAddress];
        require(currency.transfer(claimant, collateral), "Collateral transfer failed");
        _transfer(lostAddress, claimant, balanceOf(lostAddress));
        emit ClaimResolved(lostAddress, claimant, collateral);
    }

    /**
     * This function is to be executed by the owner only in case a dispute needs to be resolved manually.
     */
    function deleteClaim(address lostAddress) public {
        require(msg.sender == getClaimDeleter(), "You cannot delete claims");
        Claim memory claim = claims[lostAddress];
        IERC20 currency = IERC20(claim.currencyUsed);
        require(claim.collateral != 0, "No claim found");
        delete claims[lostAddress];
        require(currency.transfer(claim.claimant, claim.collateral), "Collateral transfer failed");
        emit ClaimDeleted(lostAddress, claim.claimant, claim.collateral);
    }

}

// File: contracts/Ownable.sol

/**	
* MIT License	
*	
* Copyright (c) 2016-2019 zOS Global Limited	
*	
* Permission is hereby granted, free of charge, to any person obtaining a copy	
* of this software and associated documentation files (the "Software"), to deal	
* in the Software without restriction, including without limitation the rights	
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell	
* copies of the Software, and to permit persons to whom the Software is	
* furnished to do so, subject to the following conditions:	
*	
* The above copyright notice and this permission notice shall be included in all	
* copies or substantial portions of the Software.	
*	
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR	
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,	
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE	
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER	
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,	
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE	
* SOFTWARE.	
*/

pragma solidity 0.5.10;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * A special address 'master' can transfer ownership.
 */

contract Ownable {

    address public owner;
    address constant master = 0xAB29B69b60D9186C9a3f254cC6982360787D24A6;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


  /**
   * @dev The Ownable constructor sets the original 'owner' of the contract to the sender
   * account.
   */
    constructor() public {
        owner = msg.sender;
    }

  /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner of this contract");
        _;
    }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

  /**
   * @dev Allows the master to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
    function transferOwnership(address _newOwner) public {
        require(msg.sender == master, "You are not the master of this contract");
        _transferOwnership(_newOwner);
    }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Zero address can't own the contract");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// File: contracts/Pausable.sol

/**	
* MIT License	
*	
* Copyright (c) 2016-2019 zOS Global Limited	
*	
* Permission is hereby granted, free of charge, to any person obtaining a copy	
* of this software and associated documentation files (the "Software"), to deal	
* in the Software without restriction, including without limitation the rights	
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell	
* copies of the Software, and to permit persons to whom the Software is	
* furnished to do so, subject to the following conditions:	
*	
* The above copyright notice and this permission notice shall be included in all	
* copies or substantial portions of the Software.	
*	
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR	
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,	
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE	
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER	
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,	
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE	
* SOFTWARE.	
*/

pragma solidity 0.5.10;


contract Pausable is Ownable {

    /** This contract is pausable.  */
    bool public paused = false;

    /** @dev Function to set pause.
     * This could for example be used in case of a fork of the network, in which case all
     * "wrong" forked contracts should be paused in their respective fork. Deciding which
     * fork is the "right" one is up to the owner of the contract.
     */
    function pause(bool _pause, string calldata _message, address _newAddress, uint256 _fromBlock) external onlyOwner() {
        paused = _pause;
        emit Pause(_pause, _message, _newAddress, _fromBlock);
    }

    event Pause(bool paused, string message, address newAddress, uint256 fromBlock);
}

// File: contracts/AlethenaShares.sol

/**
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2019 Equility AG (alethena.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity 0.5.10;




/**
 * @title LEXR Shares
 * @author Benjamin Rickenbacher, benjamin@alethena.com
 * @author Luzius Meisser, luzius@meissereconomics.com
 * @dev These tokens are based on the ERC20 standard and the open-zeppelin library.
 *
 * These tokens are uncertified shares (Wertrechte according to the Swiss code of obligations),
 * with this smart contract serving as onwership registry (Wertrechtebuch), but not as shareholder
 * registry, which is kept separate and run by the company. This is equivalent to the traditional system
 * of having physical share certificates kept at home by the shareholders and a shareholder registry run by
 * the company. Just like with physical certificates, the owners of the tokens are the owners of the shares.
 * However, in order to exercise their rights (for example receive a dividend), shareholders must register
 * with the company. For example, in case the company pays out a dividend to a previous shareholder because
 * the current shareholder did not register, the company cannot be held liable for paying the dividend to
 * the "wrong" shareholder. In relation to the company, only the registered shareholders count as such.
 * Registration requires setting up an account with ledgy.com providing your name and address and proving
 * ownership over your addresses.
 * @notice The main addition is a functionality that allows the user to claim that the key for a certain address is lost.
 * @notice In order to prevent malicious attempts, a collateral needs to be posted.
 * @notice The contract owner can delete claims in case of disputes.
 *
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */

contract AlethenaShares is ERC20Claimable, Pausable {

    using SafeMath for uint256;

    string public constant symbol = "LXR";
    string public constant name = "LEXR Equity";
    string public constant terms = "shares.lexr.ch";

    uint8 public constant decimals = 0; // legally, shares are not divisible

    uint256 public totalShares = 13 * 10 ** 6; // total number of shares, maybe not all tokenized
    uint256 public invalidTokens = 0;

    address[] public subregisters;

    event Announcement(string message);
    event TokensDeclaredInvalid(address holder, uint256 amount, string message);
    event ShareNumberingEvent(address holder, uint256 firstInclusive, uint256 lastInclusive);
    event SubRegisterAdded(address contractAddress);
    event SubRegisterRemoved(address contractAddress);

    /**
     * Declares the number of total shares, including those that have not been tokenized and those
     * that are held by the company itself. This number can be substiantially higher than totalSupply()
     * in case not all shares have been tokenized. Also, it can be lower than totalSupply() in case some
     * tokens have become invalid.
     */
    function setTotalShares(uint256 _newTotalShares) public onlyOwner() {
        require(_newTotalShares >= totalValidSupply(), "There can't be fewer tokens than shares");
        totalShares = _newTotalShares;
    }

    /**
     * Under some use-cases, tokens are held by smart contracts that are ERC20 contracts themselves.
     * A popular example are Uniswap contracts that hold traded coins and that are owned by various
     * liquidity providers. For such cases, having a list of recognized such subregisters might
     * be helpful with the automated registration and tracking of shareholders.
     * We assume that the number of sub registers stays limited, such that they are safe to iterate.
     * Subregisters should always have the same number of decimals as the main register.
     * To add subregisters with a different number of decimals, adapter contracts are needed.
     */
    function recognizeSubRegister(address contractAddress) public onlyOwner () {
        subregisters.push(contractAddress);
        emit SubRegisterAdded(contractAddress);
    }

    function removeSubRegister(address contractAddress) public onlyOwner() {
        for (uint256 i = 0; i<subregisters.length; i++) {
            if (subregisters[i] == contractAddress) {
                subregisters[i] = subregisters[subregisters.length - 1];
                subregisters.pop();
                emit SubRegisterRemoved(contractAddress);
            }
        }
    }

    /**
     * A deep balanceOf operator that also considers indirectly held tokens in
     * recognized sub registers.
     */
    function balanceOfDeep(address holder) public view returns (uint256) {
        uint256 balance = balanceOf(holder);
        for (uint256 i = 0; i<subregisters.length; i++) {
            IERC20 subERC = IERC20(subregisters[i]);
            balance = balance.add(subERC.balanceOf(holder));
        }
        return balance;
    }

    /**
     * Allows the issuer to make public announcements that are visible on the blockchain.
     */
    function announcement(string calldata message) external onlyOwner() {
        emit Announcement(message);
    }

    function setClaimPeriod(uint256 claimPeriodInDays) public onlyOwner() {
        super._setClaimPeriod(claimPeriodInDays);
    }

    /**
     * See parent method for collateral requirements.
     */
    function setCustomClaimCollateral(address collateral, uint256 rate) public onlyOwner() {
        super._setCustomClaimCollateral(collateral, rate);
    }

    function getClaimDeleter() public returns (address) {
        return owner;
    }

    /**
     * Signals that the indicated tokens have been declared invalid (e.g. by a court ruling in accordance
     * with article 973g of the planned adjustments to the Swiss Code of Obligations) and got detached from
     * the underlying shares. Invalid tokens do not carry any shareholder rights any more.
     */
    function declareInvalid(address holder, uint256 amount, string calldata message) external onlyOwner() {
        uint256 holderBalance = balanceOf(holder);
        require(amount <= holderBalance, "Cannot invalidate more tokens than held by address");
        invalidTokens = invalidTokens.add(amount);
        emit TokensDeclaredInvalid(holder, amount, message);
    }

    /**
     * The total number of valid tokens in circulation. In case some tokens have been declared invalid, this
     * number might be lower than totalSupply(). Also, it will always be lower than or equal to totalShares().
     */
    function totalValidSupply() public view returns (uint256) {
        return totalSupply().sub(invalidTokens);
    }

    /**
     * Allows the company to tokenize shares. If these shares are newly created, setTotalShares must be
     * called first in order to adjust the total number of shares.
     */
    function mint(address shareholder, uint256 _amount) public onlyOwner() {
        require(totalValidSupply().add(_amount) <= totalShares, "There can't be fewer shares than valid tokens");
        _mint(shareholder, _amount);
    }

    /**
     * Some companies like to number their shares so they can refer to them more explicitely in legal contracts.
     * A minority of Swiss lawyers even believes that numbering shares is compulsory (which is not true).
     * Nonetheless, this function allows to signal the numbers of freshly tokenized shares.
     * In case the shares ever get de-tokenized again, this information might help in deducing their
     * numbers again - although there might be some room for interpretation of what went where.
     * By convention, transfers should be considered FIFO (first in, first out) and transactions in
     * recognized subregisters be taken into account.
     */
    function mintNumbered(address shareholder, uint256 firstShareNumber, uint256 lastShareNumber) public onlyOwner() {
        mint(shareholder, lastShareNumber.sub(firstShareNumber).add(1));
        emit ShareNumberingEvent(shareholder, firstShareNumber, lastShareNumber);
    }

    /**
     * Transfers _amount tokens to the company and burns them.
     * The meaning of this operation depends on the circumstances and the fate of the shares does
     * not necessarily follow the fate of the tokens. For example, the company itself might call
     * this function to implement a formal decision to destroy some of the outstanding shares.
     * Also, this function might be called by an owner to return the shares to the company and
     * get them back in another form under an according agreement (e.g. printed certificates or
     * tokens on a different blockchain). It is not recommended to call this function without
     * having agreed with the company on the further fate of the shares in question.
     */
    function burn(uint256 _amount) public {
        require(_amount <= balanceOf(msg.sender), "Not enough shares available");
        _transfer(msg.sender, address(this), _amount);
        _burn(address(this), _amount);
    }

    function _transfer(address from, address _to, uint256 _value) internal {
        require(!paused, "Contract is paused");
        super._transfer(from, _to, _value);
    }

}