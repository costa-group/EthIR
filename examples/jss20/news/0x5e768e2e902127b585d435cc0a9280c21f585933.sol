/**

 *Submitted for verification at Etherscan.io on 2020-03-11

*/



pragma solidity ^0.5.7;


/**

 * @title SafeMath

 * @dev Unsigned math operations with safety checks that revert on error

 */

library SafeMath {

    /**

    * @dev Multiplies two unsigned integers, reverts on overflow.

    */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the

        // benefit is lost if 'b' is also tested.

        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522

        if (a == 0) {

            return 0;

        }



        uint256 c = a * b;

        require(c / a == b);



        return c;

    }



    /**

    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.

    */

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        // Solidity only automatically asserts when dividing by 0

        require(b > 0);

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold



        return c;

    }



    /**

    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).

    */

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b <= a);

        uint256 c = a - b;



        return c;

    }



    /**

    * @dev Adds two unsigned integers, reverts on overflow.

    */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a + b;

        require(c >= a);



        return c;

    }



    /**

    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),

    * reverts when dividing by zero.

    */

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b != 0);

        return a % b;

    }

}



/**

 * @title Ownable

 * @dev The Ownable contract has an owner address, and provides basic authorization control

 * functions, this simplifies the implementation of "user permissions".

 */

contract Ownable {

    address private _owner;



    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



    /**

     * @dev The Ownable constructor sets the original `owner` of the contract to the sender

     * account.

     */

    constructor () internal {

        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);

    }



    /**

     * @return the address of the owner.

     */

    function owner() public view returns (address) {

        return _owner;

    }



    /**

     * @dev Throws if called by any account other than the owner.

     */

    modifier onlyOwner() {

        require(isOwner());

        _;

    }



    /**

     * @return true if `msg.sender` is the owner of the contract.

     */

    function isOwner() public view returns (bool) {

        return msg.sender == _owner;

    }



    /**

     * @dev Allows the current owner to relinquish control of the contract.

     * @notice Renouncing to ownership will leave the contract without an owner.

     * It will not be possible to call the functions with the `onlyOwner`

     * modifier anymore.

     */

    function renounceOwnership() public onlyOwner {

        emit OwnershipTransferred(_owner, address(0));

        _owner = address(0);

    }



    /**

     * @dev Allows the current owner to transfer control of the contract to a newOwner.

     * @param newOwner The address to transfer ownership to.

     */

    function transferOwnership(address newOwner) public onlyOwner {

        _transferOwnership(newOwner);

    }



    /**

     * @dev Transfers control of the contract to a newOwner.

     * @param newOwner The address to transfer ownership to.

     */

    function _transferOwnership(address newOwner) internal {

        require(newOwner != address(0));

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;

    }

}



/**

 * @title ERC20 interface

 * @dev see https://github.com/ethereum/EIPs/issues/20

 */

interface IERC20 {

    function transfer(address to, uint256 value) external returns (bool);



    function approve(address spender, uint256 value) external returns (bool);



    function transferFrom(address from, address to, uint256 value) external returns (bool);



    function totalSupply() external view returns (uint256);



    function balanceOf(address who) external view returns (uint256);



    function allowance(address owner, address spender) external view returns (uint256);



    event Transfer(address indexed from, address indexed to, uint256 value);



    event Approval(address indexed owner, address indexed spender, uint256 value);

}



/* ERC-20 Airdrop */

contract Airdrop is Ownable{

    using SafeMath for uint256;

    address private _tokenAddress;



    event TokenAddressChanged(address indexed previousTokenAddress, address indexed newTokenAddress);

    event ClaimedTokens(address indexed owner, address indexed _token, uint256 claimedBalance);



    constructor (address tokenAddress) public {

        _tokenAddress = tokenAddress;

    }



    function tokenAddress() public view returns (address) {

        return _tokenAddress;

    }



    function setTokenAddress(address newTokenAddress) public onlyOwner {

        require(newTokenAddress != address(0));

        emit TokenAddressChanged(_tokenAddress, newTokenAddress);

        _tokenAddress = newTokenAddress;

    }



    function airdrop(address[] memory _addrs, uint256[] memory _values) public onlyOwner {

        require(_addrs.length == _values.length);

        IERC20 token = IERC20(_tokenAddress);



        for(uint256 i = 0; i < _addrs.length; i++) {

            require(token.transfer(_addrs[i], _values[i]));

        }

    }



    function airdropAfterVerification(address[] memory _addrs, uint256[] memory _values, uint256 totalValue) public onlyOwner {

        require(_addrs.length == _values.length);

        uint256 verificationValue = 0;



        for(uint256 i = 0; i < _values.length; i++) {

            verificationValue = verificationValue.add(_values[i]);

        }



        require(verificationValue == totalValue);

        IERC20 token = IERC20(_tokenAddress);



        for(uint256 i = 0; i < _addrs.length; i++) {

            require(token.transfer(_addrs[i], _values[i]));

        }

    }



    function claimTokens(address _token, uint256 _claimedBalance) public onlyOwner {

        IERC20 token = IERC20(_token);

        address thisAddress = address(this);

        uint256 tokenBalance = token.balanceOf(thisAddress);

        require(tokenBalance >= _claimedBalance);



        address owner = msg.sender;

        token.transfer(owner, _claimedBalance);

        emit ClaimedTokens(owner, _token, _claimedBalance);

    }

}