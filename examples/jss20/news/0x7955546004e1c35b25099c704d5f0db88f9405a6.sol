pragma solidity ^0.5.11;

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

        return c;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @dev Interface of ISKRA's contract.
 * https://etherscan.io/address/0xAab80423dAA0334aBA8f16726677c23619E38773
 */
interface ISKRA {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
}

contract Logic is Ownable {
    using SafeMath for uint256;

    struct Position {
        string name;
        string description;
        string imageUrl;
        string link;
        uint256 capInUSD;
        uint256 votePriceInTokens;
        uint256 voteYes;
        uint256 voteNo;
        bool archived;
        uint256 finishedAt;
        uint256 createdAt;
    }

    Position[] positions;
    ISKRA public iskraToken;
    mapping(address => mapping(uint256 => uint256)) private isVoted;

    /**
     * @dev Initializes the contract setting the iskra token.
     */
    constructor(address _token) public {
        iskraToken = ISKRA(_token);
    }

    /**
     * @dev Returns the result of converting bytes to two uint256 numbers.
     */
    function parse64BytesToTwoUint256(bytes memory data) public pure returns(uint256, uint256) {
        uint256 parsed1;
        uint256 parsed2;
        assembly {
	        parsed1 := mload(add(data, 32))
	        parsed2 := mload(add(data, 64))
        }
        return (parsed1, parsed2);
    }

    /**
     * @dev Returns the result of converting two uint256 numbers to bytes.
     */
    function parseTwoUint256ToBytes(uint256 x, uint256 y) public pure returns (bytes memory b) {
        b = new bytes(64);
        assembly {
            mstore(add(b, 32), x)
            mstore(add(b, 64), y)
        }
    }

    /**
     * @dev If all conditions are pass, this method transfers tokens(position price) from specific participant and records vote
     */
    function receiveApproval(address _from, uint256 _tokens, address _token, bytes memory _data) public {
        (uint256 toPosition, uint256 voteStatus) = parse64BytesToTwoUint256(_data);
        require(isVoted[_from][toPosition] == 0, "User has already voted");
        require(_tokens == positions[toPosition].votePriceInTokens, "Not enough tokens for this position");
        require(positions[toPosition].finishedAt > now, "Position time is expired");

        ISKRA(_token).transferFrom(_from, address(this), _tokens);
        _vote(toPosition, voteStatus, _from);
    }

    /**
     * @dev Implementation of voting logic
     */
    function _vote(uint256 toPosition, uint256 voteStatus, address _from) internal {
        require(voteStatus == 1 || voteStatus == 2, "Invalid vote status");
        if (voteStatus == 2) {
            positions[toPosition].voteYes = positions[toPosition].voteYes.add(1);
            isVoted[_from][toPosition] = voteStatus;
        } else {
            positions[toPosition].voteNo = positions[toPosition].voteNo.add(1);
            isVoted[_from][toPosition] = voteStatus;
        }
    }

    /**
     * @dev Allow contract's owner to create a new position
     */
    function addNewPostition(
        string memory _name,
        string memory _description,
        string memory _imageUrl,
        string memory _link,
        uint256 _capInUSD,
        uint256 _votePriceInTokens,
        uint256 _finishedAt
    ) public onlyOwner {
        Position memory newPosition = Position({
            name: _name,
            description: _description,
            imageUrl: _imageUrl,
            link: _link,
            capInUSD: _capInUSD,
            votePriceInTokens: _votePriceInTokens,
            finishedAt: _finishedAt,
            createdAt: block.timestamp,
            voteYes: 0,
            voteNo: 0,
            archived: false
        });
        positions.push(newPosition);
    }

    /**
     * @dev Allow contract's owner to edit specific position
     */
    function editPosition(
        uint256 _positionIndex,
        string memory _name,
        string memory _description,
        string memory _imageUrl,
        string memory _link,
        uint256 _capInUSD,
        uint256 _votePriceInTokens,
        uint256 _finishedAt
    ) public onlyOwner {
        positions[_positionIndex].name = _name;
        positions[_positionIndex].description = _description;
        positions[_positionIndex].imageUrl = _imageUrl;
        positions[_positionIndex].link = _link;
        positions[_positionIndex].capInUSD = _capInUSD;
        positions[_positionIndex].votePriceInTokens = _votePriceInTokens;
        positions[_positionIndex].finishedAt = _finishedAt;
    }

    /**
     * @dev Allow contract's owner to withdraw specific amount of ISKRA tokens from this contract
     */
    function withdrawTokens(address _wallet, uint256 _tokens) public onlyOwner {
        iskraToken.transfer(_wallet, _tokens);
    }

    /**
     * @dev Allow contract's owner to change archive status of specific position
     */
    function changeStatus(uint256 toPosition) public onlyOwner {
        positions[toPosition].archived = !positions[toPosition].archived;
    }

    /**
     * @dev Returns amount of all positions
     */
    function positionAmount() public view returns(uint256) {
        return positions.length;
    }

    /**
     * @dev Returns strings details of specific postions
     * This functionality is divided into two methods because solidity compiler has limit of returned values
     */
    function positionDetails(uint256 _index) public view returns(
        string memory name,
        string memory description,
        string memory imageUrl,
        string memory link,
        bool archived
    ) {
        return (
            positions[_index].name,
            positions[_index].description,
            positions[_index].imageUrl,
            positions[_index].link,
            positions[_index].archived
        );
    }

    /**
     * @dev Returns numbers details of specific postions
     * This functionality is divided into two methods because solidity compiler has limit of returned values
     */
    function postionNumbers(uint256 _index) public view returns(
        uint256 capInUSD,
        uint256 votePriceInTokens,
        uint256 finishedAt,
        uint256 createdAt,
        uint256 voteYes,
        uint256 voteNo
    ) {
        return (
            positions[_index].capInUSD,
            positions[_index].votePriceInTokens,
            positions[_index].finishedAt,
            positions[_index].createdAt,
            positions[_index].voteYes,
            positions[_index].voteNo
        );
    }

    /**
     * @dev Returns voting result of specific participant
     */
    function voterInfo(address _voter, uint256 _position) public view returns(uint256) {
        return isVoted[_voter][_position];
    }
}