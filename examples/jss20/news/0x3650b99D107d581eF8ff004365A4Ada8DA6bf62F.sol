pragma solidity ^0.5.16;

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


/**
 * Abstract contract, requires implementation to specify who can commit blocks and what
 *   happens when a successful proof is presented
 * Verifies Merkle-tree inclusion proofs that show that certain address has
 *   certain earnings balance, according to hash published ("signed") by a
 *   sidechain operator or similar authority
 *
 * ABOUT Merkle-tree inclusion proof: Merkle-tree inclusion proof is an algorithm to prove memebership
 * in a set using minimal [ie log(N)] inputs. The hashes of the items are arranged by hash value in a binary Merkle tree where
 * each node contains a hash of the hashes of nodes below. The root node (ie "root hash") contains hash information
 * about the entire set, and that is the data that BalanceVerifier posts to the blockchain. To prove membership, you walk up the
 * tree from the node in question, and use the supplied hashes (the "proof") to fill in the hashes from the adjacent nodes. The proof
 * succeeds iff you end up with the known root hash when you get to the top of the tree.
 * See https://medium.com/crypto-0-nite/merkle-proofs-explained-6dd429623dc5
 *
 * Merkle-tree inclusion proof is a related concept to the blockchain Merkle tree, but a somewhat different application.
 * BalanceVerifier posts the root hash of the current ledger only, and this does not depend on the hash of previous ledgers.
 * This is different from the blockchain, where each block contains the hash of the previous block.
 *
 * TODO: see if it could be turned into a library, so many contracts could use it
 */
contract BalanceVerifier {
    event NewCommit(uint blockNumber, bytes32 rootHash, string ipfsHash);

    /**
     * Root hashes of merkle-trees constructed from its balances
     * @param uint root-chain block number after which the balances were committed
     * @return bytes32 root of the balances merkle-tree at that time
     */
    mapping (uint => bytes32) public committedHash;

    /**
     * Handler for proof of off-chain balances
     * It is up to the implementing contract to actually distribute out the balances
     * @param blockNumber the block whose hash was used for verification
     * @param account whose balances were successfully verified
     * @param balance the off-chain account balance
     */
    function onVerifySuccess(uint blockNumber, address account, uint balance) internal;

    /**
     * Implementing contract should should do access controls for committing
     */
    function onCommit(uint blockNumber, bytes32 rootHash, string memory ipfsHash) internal;

    /**
     * Monoplasma operator submits commitments to root-chain.
     * For convenience, also publish the ipfsHash of the balance book JSON object
     * @param blockNumber the root-chain block after which the balances were recorded
     * @param rootHash root of the balances merkle-tree
     * @param ipfsHash where the whole balances object can be retrieved in JSON format
     */
    function commit(uint blockNumber, bytes32 rootHash, string calldata ipfsHash) external {
        require(committedHash[blockNumber] == 0, "error_overwrite");
        string memory _hash = ipfsHash;
        onCommit(blockNumber, rootHash, _hash); // Access control delegated to implementing class
        committedHash[blockNumber] = rootHash;
        emit NewCommit(blockNumber, rootHash, _hash);
    }

    /**
     * Proving can be used to record the sidechain balances permanently into root chain
     * @param blockNumber the block after which the balances were recorded
     * @param account whose balances will be verified
     * @param balance off-chain account balance
     * @param proof list of hashes to prove the totalEarnings
     */
    function prove(uint blockNumber, address account, uint balance, bytes32[] memory proof) public {
        require(proofIsCorrect(blockNumber, account, balance, proof), "error_proof");
        onVerifySuccess(blockNumber, account, balance);
    }

    /**
     * Check the merkle proof of balance in the given commit (after blockNumber in root-chain) for given account
     * @param blockNumber the block after which the balances were recorded
     * @param account whose balances will be verified
     * @param balance off-chain account balance
     * @param proof list of hashes to prove the totalEarnings
     */
    function proofIsCorrect(uint blockNumber, address account, uint balance, bytes32[] memory proof) public view returns(bool) {
        bytes32 leafHash = keccak256(abi.encodePacked(account, balance, blockNumber));
        bytes32 rootHash = committedHash[blockNumber];
        require(rootHash != 0x0, "error_blockNotFound");
        return rootHash == calculateRootHash(leafHash, proof);
    }

    /**
     * Calculate root hash of a Merkle tree, given
     * @param leafHash of the member whose balances are being be verified
     * @param others list of hashes of "other" branches
     */
    function calculateRootHash(bytes32 leafHash, bytes32[] memory others) public pure returns (bytes32 root) {
        root = leafHash;
        for (uint8 i = 0; i < others.length; i++) {
            bytes32 other = others[i];
            if (root < other) {
                // TODO: consider hashing in i to defend from https://en.wikipedia.org/wiki/Merkle_tree#Second_preimage_attack
                root = keccak256(abi.encodePacked(root, other));
            } else {
                root = keccak256(abi.encodePacked(other, root));
            }
        }
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "error_onlyOwner");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public {
        require(msg.sender == pendingOwner, "error_onlyPendingOwner");
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}




/**
 * Monoplasma that is managed by an owner, who also appoints a trusted (but verifiable) operator.
 * Owner should be able to add and remove recipients through an off-chain mechanism not specified here.
 */
contract Monoplasma is BalanceVerifier, Ownable {
    using SafeMath for uint256;

    event OperatorChanged(address indexed newOperator);
    event AdminFeeChanged(uint adminFee);

    /**
     * Freeze period during which all participants should be able to
     *   acquire the whole balance book from IPFS (or HTTP server, or elsewhere)
     *   and validate that the published rootHash is correct.
     * In case of incorrect rootHash, all members should issue withdrawals from the
     *   latest block they have validated (that is older than blockFreezeSeconds).
     * So: too short freeze period `+` bad availability `=>` ether (needlessly) spent withdrawing earnings.
     *     Long freeze period `==` lag between purchase and withdrawal `=>` bad UX.
     * Blocks older than blockFreezeSeconds can be used to withdraw funds.
     */
    uint public blockFreezeSeconds;

    /**
     * Block number => timestamp
     * Publish time of a block, where the block freeze period starts from.
     * Note that block number points to the block after which the root hash is calculated,
     *   not the block where NewCommit was emitted (event must come later)
     */
    mapping (uint => uint) public blockTimestamp;

    /// operator is the address who is allowed to commit the earnings
    address public operator;

    /// fee fraction = adminFee/10^18
    uint public adminFee;

    IERC20 public token;

    /// track lifetime total of tokens withdrawn from contract
    uint public totalWithdrawn;

    /**
     * Track lifetime total of earnings proven, as extra protection from malicious operator.
     * The difference of what CAN be withdrawn and what HAS been withdrawn must be covered with tokens in contract,
     *   in other words: `totalProven - totalWithdrawn <= token.balanceOf(this)`.
     * This is to prevent a "bank run" situation where more earnings have been proven in the contract than there are tokens to cover them.
     * Of course this only moves the "bank run" outside the contract, to a race to prove earnings,
     *   but at least the contract should never go into a state where it couldn't cover what's been proven.
     */
    uint public totalProven;

    /// earnings for which proof has been submitted
    mapping (address => uint) public earnings;

    /// earnings that have been sent out already
    mapping (address => uint) public withdrawn;

    constructor(address tokenAddress, uint blockFreezePeriodSeconds, uint initialAdminFee) public {
        blockFreezeSeconds = blockFreezePeriodSeconds;
        token = IERC20(tokenAddress);
        operator = msg.sender;
        setAdminFee(initialAdminFee);
    }

    /**
     * Admin can appoint the operator.
     * @param newOperator that is allowed to commit the off-chain balances
     */
    function setOperator(address newOperator) public onlyOwner {
        operator = newOperator;
        emit OperatorChanged(newOperator);
    }

    /**
     * Admin fee as a fraction of revenue.
     * Smart contract doesn't use it, it's here just for storing purposes.
     * @param newAdminFee fixed-point decimal in the same way as ether: 50% === 0.5 ether === "500000000000000000"
     */
    function setAdminFee(uint newAdminFee) public onlyOwner {
        require(newAdminFee <= 1 ether, "error_adminFee");
        adminFee = newAdminFee;
        emit AdminFeeChanged(adminFee);
    }

    /**
     * Operator commits the off-chain balances.
     * This starts the freeze period (measured from block.timestamp).
     * See README under "Threat model" for discussion on safety of using "now".
     * @param blockNumber after which balances were submitted
     */
    function onCommit(uint blockNumber, bytes32, string memory) internal {
        require(msg.sender == operator, "error_notPermitted");
        blockTimestamp[blockNumber] = now; // solium-disable-line security/no-block-members
    }

    /**
     * Called from BalanceVerifier.prove.
     * Prove can be called directly to withdraw less than the whole share,
     *   or just "cement" the earnings so far into root chain even without withdrawing.
     * Missing balance test is an extra layer of defense against fraudulent operator who tries to steal ALL tokens.
     * If any member can exit within freeze period, that fraudulent commit will fail.
     * Only earnings that have been committed longer than blockFreezeSeconds ago can be proven, see `onCommit`.
     * See README under "Threat model" for discussion on safety of using "now".
     * @param blockNumber after which balances were submitted in {onCommit}
     * @param account whose earnings were successfully proven and updated
     * @param newEarnings the updated total lifetime earnings
     */
    function onVerifySuccess(uint blockNumber, address account, uint newEarnings) internal {
        uint blockFreezeStart = blockTimestamp[blockNumber];
        require(now > blockFreezeStart + blockFreezeSeconds, "error_frozen"); // solium-disable-line security/no-block-members
        require(earnings[account] < newEarnings, "error_oldEarnings");
        totalProven = totalProven.add(newEarnings).sub(earnings[account]);
        require(totalProven.sub(totalWithdrawn) <= token.balanceOf(address(this)), "error_missingBalance");
        earnings[account] = newEarnings;
    }

    /**
     * Prove and withdraw the whole revenue share from sidechain in one transaction.
     * @param blockNumber of the commit that contains the earnings to verify
     * @param totalEarnings in the off-chain balance book
     * @param proof list of hashes to prove the totalEarnings
     */
    function withdrawAll(uint blockNumber, uint totalEarnings, bytes32[] calldata proof) external {
        withdrawAllFor(msg.sender, blockNumber, totalEarnings, proof);
    }

    /**
     * Prove and withdraw the whole revenue share on behalf of someone else.
     * Validator needs to exit those it's watching out for, in case
     *   it detects Operator malfunctioning.
     * @param recipient the address we're proving and withdrawing to
     * @param blockNumber of the commit that contains the earnings to verify
     * @param totalEarnings in the off-chain balance book
     * @param proof list of hashes to prove the totalEarnings
     */
    function withdrawAllFor(address recipient, uint blockNumber, uint totalEarnings, bytes32[] memory proof) public {
        prove(blockNumber, recipient, totalEarnings, proof);
        uint withdrawable = totalEarnings.sub(withdrawn[recipient]);
        withdrawFor(recipient, withdrawable);
    }

    /**
     * Prove and "donate withdraw" function that allows you to prove and transfer
     *   your earnings to a another address in one transaction.
     * @param recipient the address the tokens will be sent to (instead of msg.sender)
     * @param blockNumber of the commit that contains the earnings to verify
     * @param totalEarnings in the off-chain balance book
     * @param proof list of hashes to prove the totalEarnings
     */
    function withdrawAllTo(address recipient, uint blockNumber, uint totalEarnings, bytes32[] calldata proof) external {
        prove(blockNumber, msg.sender, totalEarnings, proof);
        uint withdrawable = totalEarnings.sub(withdrawn[msg.sender]);
        withdrawTo(recipient, withdrawable);
    }

    /**
     * Prove and do an "unlimited donate withdraw" on behalf of someone else, to an address they've specified.
     * Sponsored withdraw is paid by e.g. admin, but target account could be whatever the member specifies.
     * The signature gives a "blank cheque" for admin to withdraw all tokens to `recipient` in the future,
     *   and it's valid until next withdraw (and so can be nullified by withdrawing any amount).
     * A new signature needs to be obtained for each subsequent future withdraw.
     * @param recipient the address the tokens will be sent to (instead of `msg.sender`)
     * @param signer whose earnings are being withdrawn
     * @param signature from the community member, see `signatureIsValid` how signature generated for unlimited amount
     * @param blockNumber of the commit that contains the earnings to verify
     * @param totalEarnings in the off-chain balance book
     * @param proof list of hashes to prove the totalEarnings
     */
    function withdrawAllToSigned(
        address recipient,
        address signer, bytes calldata signature,                       // signature arguments
        uint blockNumber, uint totalEarnings, bytes32[] calldata proof  // proof arguments
    )
        external
    {
        require(signatureIsValid(recipient, signer, 0, signature), "error_badSignature");
        prove(blockNumber, signer, totalEarnings, proof);
        uint withdrawable = totalEarnings.sub(withdrawn[signer]);
        _withdraw(recipient, signer, withdrawable);
    }

    /**
     * Prove and do a "donate withdraw" on behalf of someone else, to an address they've specified.
     * Sponsored withdraw is paid by e.g. admin, but target account could be whatever the member specifies.
     * The signature is valid only for given amount of tokens that may be different from maximum withdrawable tokens.
     * @param recipient the address the tokens will be sent to (instead of msg.sender)
     * @param signer whose earnings are being withdrawn
     * @param amount of tokens to withdraw
     * @param signature from the community member, see `signatureIsValid` how it's generated
     * @param blockNumber of the commit that contains the earnings to verify
     * @param totalEarnings in the off-chain balance book
     * @param proof list of hashes to prove the totalEarnings
     */
    function proveAndWithdrawToSigned(
        address recipient,
        address signer, uint amount, bytes calldata signature,          // signature arguments
        uint blockNumber, uint totalEarnings, bytes32[] calldata proof  // proof arguments
    )
        external
    {
        require(signatureIsValid(recipient, signer, amount, signature), "error_badSignature");
        prove(blockNumber, signer, totalEarnings, proof);
        _withdraw(recipient, signer, amount);
    }

    /**
     * Withdraw a specified amount of your own proven earnings (see `function prove`).
     * @param amount of tokens to withdraw
     */
    function withdraw(uint amount) public {
        _withdraw(msg.sender, msg.sender, amount);
    }

    /**
     * Withdraw a specified amount on behalf of someone else.
     * Validator needs to exit those it's watching out for, in case it detects Operator malfunctioning.
     * @param recipient whose tokens will be withdrawn (instead of msg.sender)
     * @param amount of tokens to withdraw
     */
    function withdrawFor(address recipient, uint amount) public {
        _withdraw(recipient, recipient, amount);
    }

    /**
     * "Donate withdraw":
     * Withdraw and transfer proven earnings to a another address in one transaction,
     *   instead of withdrawing and then transfering the tokens.
     * @param recipient the address the tokens will be sent to (instead of `msg.sender`)
     * @param amount of tokens to withdraw
     */
    function withdrawTo(address recipient, uint amount) public {
        _withdraw(recipient, msg.sender, amount);
    }

    /**
     * Signed "donate withdraw":
     * Withdraw and transfer proven earnings to a third address on behalf of someone else.
     * Sponsored withdraw is paid by e.g. admin, but target account could be whatever the member specifies.
     * @param recipient of the tokens
     * @param signer whose earnings are being withdrawn
     * @param amount how much is authorized for withdrawing by the signature
     * @param signature from the community member, see `signatureIsValid` how it's generated
     */
    function withdrawToSigned(address recipient, address signer, uint amount, bytes memory signature) public {
        require(signatureIsValid(recipient, signer, amount, signature), "error_badSignature");
        _withdraw(recipient, signer, amount);
    }

    /**
     * Execute token withdrawal into specified recipient address from specified member account.
     * To prevent "bank runs", it is up to the sidechain implementation to make sure that always:
     * `sum of committed earnings <= token.balanceOf(this) + totalWithdrawn`.
     * Smart contract can't verify that, because it can't see inside the commit hash.
     * @param recipient of the tokens
     * @param account whose earnings are being debited
     * @param amount of tokens that is sent out
     */
    function _withdraw(address recipient, address account, uint amount) internal {
        require(amount > 0, "error_zeroWithdraw");
        uint w = withdrawn[account].add(amount);
        require(w <= earnings[account], "error_overdraft");
        withdrawn[account] = w;
        totalWithdrawn = totalWithdrawn.add(amount);
        require(token.transfer(recipient, amount), "error_transfer");
    }

    /**
     * Check signature from a member authorizing withdrawing its earnings to another account.
     * Throws if the signature is badly formatted or doesn't match the given signer and amount.
     * Signature has parts the act as replay protection:
     * 1) `address(this)`: signature can't be used for other contracts;
     * 2) `withdrawn[signer]`: signature only works once (for unspecified amount), and can be "cancelled" by sending a withdraw tx.
     * Generated in Javascript with: `web3.eth.accounts.sign(recipientAddress + amount.toString(16, 64) + contractAddress.slice(2) + withdrawnTokens.toString(16, 64), signerPrivateKey)`,
     * or for unlimited amount: `web3.eth.accounts.sign(recipientAddress + "0".repeat(64) + contractAddress.slice(2) + withdrawnTokens.toString(16, 64), signerPrivateKey)`.
     * @param recipient of the tokens
     * @param signer whose earnings are being withdrawn
     * @param amount how much is authorized for withdraw, or zero for unlimited (withdrawAll)
     * @param signature byte array from `web3.eth.accounts.sign`
     * @return true iff signer of the authorization (member whose earnings are going to be withdrawn) matches the signature
     */
    function signatureIsValid(address recipient, address signer, uint amount, bytes memory signature) public view returns (bool isValid) {
        require(signature.length == 65, "error_badSignatureLength");

        bytes32 r; bytes32 s; uint8 v;
        assembly {      // solium-disable-line security/no-inline-assembly
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "error_badSignatureVersion");

        // When changing the message, remember to double-check that message length is correct!
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n104", recipient, amount, address(this), withdrawn[signer]));
        address calculatedSigner = ecrecover(messageHash, v, r, s);

        return calculatedSigner == signer;
    }
}


contract DataunionVault is Monoplasma {

    string public joinPartStream;

    /** Server version. This must be kept in sync with src/server.js */
    uint public version = 1;

    constructor(address operator, string memory joinPartStreamId, address tokenAddress, uint blockFreezePeriodSeconds, uint adminFeeFraction)
    Monoplasma(tokenAddress, blockFreezePeriodSeconds, adminFeeFraction) public {
        setOperator(operator);
        joinPartStream = joinPartStreamId;
    }
}