// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/governance/dmg/SafeBitMath.sol

pragma solidity ^0.5.0;

library SafeBitMath {

    function safe64(uint n, string memory errorMessage) internal pure returns (uint64) {
        require(n < 2 ** 64, errorMessage);
        return uint64(n);
    }

    function safe128(uint n, string memory errorMessage) internal pure returns (uint128) {
        require(n < 2 ** 128, errorMessage);
        return uint128(n);
    }

    function add128(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub128(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b <= a, errorMessage);
        return a - b;
    }

}

// File: contracts/utils/EvmUtil.sol

pragma solidity ^0.5.13;

library EvmUtil {

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

}

// File: contracts/governance/dmg/DMGToken.sol

pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;




/**
 * This contract is mainly based on Compound's COMP token
 * (https://etherscan.io/address/0xc00e94cb662c3520282e6f5717214004a7f26888). Unfortunately, no license was found on
 * Etherscan for the token and the code for the token cannot be found on their GitHub, so the proper attribution to the
 * Compound team cannot be made.
 *
 * Changes made to the token contract include modifying internal storage of balances/allowances to use 128 bits instead
 * of 96, increasing the number of bits for a checkpoint to 64, adding a burn function, and creating an initial
 * totalSupply of 250mm.
 */
contract DMGToken is IERC20 {

    string public constant name = "DMM: Governance";

    string public constant symbol = "DMG";

    uint8 public constant decimals = 18;

    uint public totalSupply;

    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint128)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping(address => uint128) internal balances;

    /// @notice A record of each account's delegate
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint64 fromBlock;
        uint128 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint64 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint64) public numCheckpoints;

    bytes32 public domainSeparator;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPE_HASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPE_HASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for the transfer struct used by the contract
    bytes32 public constant TRANSFER_TYPE_HASH = keccak256("Transfer(address recipient,uint256 rawAmount,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for the approve struct used by the contract
    bytes32 public constant APPROVE_TYPE_HASH = keccak256("Approve(address spender,uint256 rawAmount,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Construct the DMG token
     * @param account The initial account to receive all of the tokens
     */
    constructor(address account) public {
        // 250mm
        totalSupply = 250000000e18;
        require(totalSupply == uint128(totalSupply), "DMG: total supply exceeds 128 bits");

        domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPE_HASH, keccak256(bytes(name)), EvmUtil.getChainId(), address(this))
        );

        balances[account] = uint128(totalSupply);
        emit Transfer(address(0), account, totalSupply);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint rawAmount) external returns (bool) {
        uint128 amount;
        if (rawAmount == uint(- 1)) {
            amount = uint128(- 1);
        } else {
            amount = SafeBitMath.safe128(rawAmount, "DMG::approve: amount exceeds 128 bits");
        }

        _approveTokens(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint128 amount = SafeBitMath.safe128(rawAmount, "DMG::transfer: amount exceeds 128 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfers `amount` tokens from `msg.sender` to the zero address
     * @param rawAmount The number of tokens to burn
     * @return Whether or not the transfer succeeded
    */
    function burn(uint rawAmount) external returns (bool) {
        uint128 amount = SafeBitMath.safe128(rawAmount, "DMG::burn: amount exceeds 128 bits");
        _burnTokens(msg.sender, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint128 spenderAllowance = allowances[src][spender];
        uint128 amount = SafeBitMath.safe128(rawAmount, "DMG::allowances: amount exceeds 128 bits");

        if (spender != src && spenderAllowance != uint128(- 1)) {
            uint128 newAllowance = SafeBitMath.sub128(spenderAllowance, amount, "DMG::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    function nonceOf(address signer) public view returns (uint) {
        return nonces[signer];
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPE_HASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "DMG::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "DMG::delegateBySig: invalid nonce");
        require(now <= expiry, "DMG::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Transfers tokens from signatory to `recipient`
     * @param recipient The address to receive the tokens
     * @param rawAmount The amount of tokens to be sent to recipient
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function transferBySig(address recipient, uint rawAmount, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 structHash = keccak256(abi.encode(TRANSFER_TYPE_HASH, recipient, rawAmount, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "DMG::transferBySig: invalid signature");
        require(nonce == nonces[signatory]++, "DMG::transferBySig: invalid nonce");
        require(now <= expiry, "DMG::transferBySig: signature expired");

        uint128 amount = SafeBitMath.safe128(rawAmount, "DMG::transferBySig: amount exceeds 128 bits");
        return _transferTokens(signatory, recipient, amount);
    }

    /**
     * @notice Approves tokens from signatory to be spent by `spender`
     * @param spender The address to receive the tokens
     * @param rawAmount The amount of tokens to be sent to spender
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function approveBySig(address spender, uint rawAmount, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 structHash = keccak256(abi.encode(APPROVE_TYPE_HASH, spender, rawAmount, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "DMG::approveBySig: invalid signature");
        require(nonce == nonces[signatory]++, "DMG::approveBySig: invalid nonce");
        require(now <= expiry, "DMG::approveBySig: signature expired");

        uint128 amount;
        if (rawAmount == uint(- 1)) {
            amount = uint128(- 1);
        } else {
            amount = SafeBitMath.safe128(rawAmount, "DMG::approveBySig: amount exceeds 128 bits");
        }
        _approveTokens(signatory, spender, amount);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint128) {
        uint64 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint128) {
        require(blockNumber < block.number, "DMG::getPriorVotes: not yet determined");

        uint64 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint64 lower = 0;
        uint64 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint64 center = upper - (upper - lower) / 2;
            // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint128 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint128 amount) internal {
        require(src != address(0), "DMG::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "DMG::_transferTokens: cannot transfer to the zero address");

        balances[src] = SafeBitMath.sub128(balances[src], amount, "DMG::_transferTokens: transfer amount exceeds balance");
        balances[dst] = SafeBitMath.add128(balances[dst], amount, "DMG::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _approveTokens(address owner, address spender, uint128 amount) internal {
        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _burnTokens(address src, uint128 amount) internal {
        require(src != address(0), "DMG::_burnTokens: cannot burn from the zero address");

        balances[src] = SafeBitMath.sub128(balances[src], amount, "DMG::_burnTokens: burn amount exceeds balance");
        emit Transfer(src, address(0), amount);

        totalSupply = SafeBitMath.sub128(uint128(totalSupply), amount, "DMG::_burnTokens: burn amount exceeds total supply");

        _moveDelegates(delegates[src], address(0), amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint128 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint64 srcRepNum = numCheckpoints[srcRep];
                uint128 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint128 srcRepNew = SafeBitMath.sub128(srcRepOld, amount, "DMG::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint64 dstRepNum = numCheckpoints[dstRep];
                uint128 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint128 dstRepNew = SafeBitMath.add128(dstRepOld, amount, "DMG::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint64 nCheckpoints, uint128 oldVotes, uint128 newVotes) internal {
        uint64 blockNumber = SafeBitMath.safe64(block.number, "DMG::_writeCheckpoint: block number exceeds 64 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

}