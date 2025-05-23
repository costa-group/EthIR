pragma solidity ^0.5.11;
/** Thanks to OpenZeppelin for the awesome Libraries. */



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



library Roles {

    struct Role {

        mapping (address => bool) bearer;

    }



    /**

     * @dev give an account access to this role

     */

    function add(Role storage role, address account) internal {

        require(account != address(0));

        require(!has(role, account));



        role.bearer[account] = true;

    }



    /**

     * @dev remove an account's access to this role

     */

    function remove(Role storage role, address account) internal {

        require(account != address(0));

        require(has(role, account));



        role.bearer[account] = false;

    }



    /**

     * @dev check if an account has this role

     * @return bool

     */

    function has(Role storage role, address account) internal view returns (bool) {

        require(account != address(0));

        return role.bearer[account];

    }

}



contract WhitelistAdminRole {

    using Roles for Roles.Role;



    event WhitelistAdminAdded(address indexed account);

    event WhitelistAdminRemoved(address indexed account);



    Roles.Role private _whitelistAdmins;



    constructor () internal {

        _addWhitelistAdmin(msg.sender);

    }



    modifier onlyWhitelistAdmin() {

        require(isWhitelistAdmin(msg.sender));

        _;

    }



    function isWhitelistAdmin(address account) public view returns (bool) {

        return _whitelistAdmins.has(account);

    }



    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {

        _addWhitelistAdmin(account);

    }



    function removeWhitelistAdmin(address account) public onlyWhitelistAdmin{

        _removeWhitelistAdmin(account);

    }



    function _addWhitelistAdmin(address account) internal {

        _whitelistAdmins.add(account);

        emit WhitelistAdminAdded(account);

    }



    function _removeWhitelistAdmin(address account) internal {

        _whitelistAdmins.remove(account);

        emit WhitelistAdminRemoved(account);

    }

}



contract BlackListedRole is WhitelistAdminRole{

    using Roles for Roles.Role;

    

    event BlacklistedAdded(address indexed account);

    event BlacklistedRemoved(address indexed account);



    Roles.Role private _blacklisteds;



    modifier onlyNotBlacklisted() {

        require(!isBlackListed(msg.sender),'You are Blacklisted');

        _;

    }

    

    modifier onlyBlackListed(address account){

        require(isBlackListed(account), 'Account is not Blacklisted');

        _;

    }

    function isBlackListed(address account) public view returns(bool) {

        return _blacklisteds.has(account);

    }



    function addBlacklisted(address account) public onlyWhitelistAdmin{

        _addBlacklisted(account);

    }



    function removeBlacklisted(address account) public onlyWhitelistAdmin{

        _removeBlacklisted(account);

    }



    function _addBlacklisted(address account) internal {

        _blacklisteds.add(account);

        emit BlacklistedAdded(account);

    }



    function _removeBlacklisted(address account) internal{

        _blacklisteds.remove(account);

        emit BlacklistedRemoved(account);

    }

}



contract Pausable is WhitelistAdminRole {

    event Paused(address account);

    event Unpaused(address account);



    bool private _paused;



    constructor () internal {

        _paused = false;

    }



    /**

     * @return true if the contract is paused, false otherwise.

     */

    function paused() public view returns (bool) {

        return _paused;

    }



    /**

     * @dev Modifier to make a function callable only when the contract is not paused.

     */

    modifier whenNotPaused() {

        require(!_paused,'Contract is Paused');

        _;

    }



    /**

     * @dev Modifier to make a function callable only when the contract is paused.

     */

    modifier whenPaused() {

        require(_paused,'Contract is not Paused');

        _;

    }



    /**

     * @dev called by the owner to pause, triggers stopped state

     */

    function pause() public onlyWhitelistAdmin whenNotPaused {

        _paused = true;

        emit Paused(msg.sender);

    }



    /**

     * @dev called by the owner to unpause, returns to normal state

     */

    function unpause() public onlyWhitelistAdmin whenPaused {

        _paused = false;

        emit Unpaused(msg.sender);

    }

}









interface IERC20 {

  function totalSupply() external view returns (uint256); //ERC20Basic

  function balanceOf(address account) external view returns (uint256); //ERC20Basic

  function transfer(address recipient, uint256 amount) external returns (bool);//ERC20Basic

  function allowance(address owner, address spender) external view returns (uint256);//ERC20

  function approve(address spender, uint256 amount) external returns (bool);//ERC20

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);//ERC20

  event Transfer(address indexed from, address indexed to, uint256 value);//ERC20Basic

  event Approval(address indexed owner, address indexed spender, uint256 value);//ERC20

}

/**

 * @title Standard ERC20 token

 *

 * @dev Implementation of the basic standard token.

 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md

 * Originally based on code by FirstBlood:

 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol

 *

 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for

 * all accounts just by listening to said events. Note that this isn't required by the specification, and other

 * compliant implementations may not do it.

 */

contract ERC20 is IERC20, WhitelistAdminRole,BlackListedRole,Pausable {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    uint public _basisPointsRate = 0;

    uint public _maximumFee = 0;

    address internal _feeWallet;

    /**

    * @dev Total number of tokens in existence

    */

    function totalSupply() public view returns (uint256) {

        return _totalSupply;

    }



    /**

    * @dev Gets the balance of the specified address.

    * @param owner The address to query the balance of.

    * @return An uint256 representing the amount owned by the passed address.

    */

    function balanceOf(address owner) public view returns (uint256) {

        return _balances[owner];

    }

    /**

    * @dev Fix for the ERC20 short address attack.

    */

    modifier onlyPayloadSize(uint size) {

        require(!(msg.data.length < size + 4));

        _;

    }

    /**

     * @dev Function to check the amount of tokens that an owner allowed to a spender.

     * @param owner address The address which owns the funds.

     * @param spender address The address which will spend the funds.

     * @return A uint256 specifying the amount of tokens still available for the spender.

     */

    function allowance(address owner, address spender) public view returns (uint256) {

        return _allowed[owner][spender];

    }



    /**

    * @dev Transfer token for a specified address

    * @param to The address to transfer to.

    * @param value The amount to be transferred.

    */

    function transfer(address to, uint256 value) public onlyNotBlacklisted onlyPayloadSize(2 * 32) returns (bool) {

        _transfer(msg.sender, to, value);

        return true;

    }



    /**

     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.

     * Beware that changing an allowance with this method brings the risk that someone may use both the old

     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this

     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:

     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

     * @param spender The address which will spend the funds.

     * @param value The amount of tokens to be spent.

     */

    function approve(address spender, uint256 value) public returns (bool) {

        require(spender != address(0));



        _allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;

    }



    /**

     * @dev Transfer tokens from one address to another.

     * Note that while this function emits an Approval event, this is not required as per the specification,

     * and other compliant implementations may not emit the event.

     * @param from address The address which you want to send tokens from

     * @param to address The address which you want to transfer to

     * @param value uint256 the amount of tokens to be transferred

     */

    function transferFrom(address from, address to, uint256 value) public onlyNotBlacklisted returns (bool) {

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

        _transfer(from, to, value);

        emit Approval(from, msg.sender, _allowed[from][msg.sender]);

        return true;

    }



    /**

     * @dev Increase the amount of tokens that an owner allowed to a spender.

     * approve should be called when allowed_[_spender] == 0. To increment

     * allowed value is better to use this function to avoid 2 calls (and wait until

     * the first transaction is mined)

     * From MonolithDAO Token.sol

     * Emits an Approval event.

     * @param spender The address which will spend the funds.

     * @param addedValue The amount of tokens to increase the allowance by.

     */

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {

        require(spender != address(0));



        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

        return true;

    }



    /**

     * @dev Decrease the amount of tokens that an owner allowed to a spender.

     * approve should be called when allowed_[_spender] == 0. To decrement

     * allowed value is better to use this function to avoid 2 calls (and wait until

     * the first transaction is mined)

     * From MonolithDAO Token.sol

     * Emits an Approval event.

     * @param spender The address which will spend the funds.

     * @param subtractedValue The amount of tokens to decrease the allowance by.

     */

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {

        require(spender != address(0));



        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

        return true;

    }



    /**

    * @dev Transfer token for a specified addresses

    * @param from The address to transfer from.

    * @param to The address to transfer to.

    * @param value The amount to be transferred.

    */

    function _transfer(address from, address to, uint256 value) internal  {

        require(to != address(0));

        uint256 fee = (value.mul(_basisPointsRate)).div(1000);

        if (fee > _maximumFee){

            fee = _maximumFee;

        }

        uint256 sendAmount = value.sub(fee);



        _balances[from] = _balances[from].sub(value);

        _balances[to] = _balances[to].add(sendAmount);

        if (fee > 0 ){

             _balances[_feeWallet] = _balances[_feeWallet].add(fee);

            emit Transfer(from, _feeWallet, fee);

        }

        emit Transfer(from, to, sendAmount);

    }





    /**

     * @dev Internal function that mints an amount of the token and assigns it to

     * an account. This encapsulates the modification of balances such that the

     * proper events are emitted.

     * @param account The account that will receive the created tokens.

     * @param value The amount that will be created.

     */

    function _mint(address account, uint256 value) internal onlyWhitelistAdmin whenNotPaused{

        require(account != address(0));

        _totalSupply = _totalSupply.add(value);

        _balances[account] = _balances[account].add(value);

        emit Transfer(address(0), account, value);

    }



    /**

     * @dev Internal function that burns an amount of the token of a given

     * account.

     * @param account The account whose tokens will be burnt.

     * @param value The amount that will be burnt.

     */

    function _burn(address account, uint256 value) internal onlyBlackListed(account) onlyWhitelistAdmin {

        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);

        _balances[account] = _balances[account].sub(value);

        emit Transfer(account, address(0), value);

    }

}

/**

 * @title ERC20Detailed token

 * @dev The decimals are only for visualization purposes.

 * All the operations are done using the smallest and indivisible token unit,

 * just as on Ethereum all the operations are done in wei.

 */

contract ERC20Detailed is IERC20 {

    string private _name;

    string private _symbol;

    uint8 private _decimals;



    constructor (string memory name, string memory symbol, uint8 decimals) public {

        _name = name;

        _symbol = symbol;

        _decimals = decimals;

    }



    /**

     * @return the name of the token.

     */

    function name() public view returns (string memory) {

        return _name;

    }



    /**

     * @return the symbol of the token.

     */

    function symbol() public view returns (string memory) {

        return _symbol;

    }



    /**

     * @return the number of decimals of the token.

     */

    function decimals() public view returns (uint8) {

        return _decimals;

    }

}



contract BRLSToken is ERC20, ERC20Detailed {

    event FeeParams(uint256 feeBasisPoints, uint256 maxFee);



    uint8 public constant DECIMALS = 2;

    uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(DECIMALS));



    /**

     * @dev Constructor that gives msg.sender all of existing tokens.

     */

    constructor () public ERC20Detailed("Brazilian Real Stable", "BRLS", DECIMALS) {

        

    }



    function mint(address account, uint256 value) public{

        _mint(account,value);

    }



    function burn(address account, uint256 value) public{

        _burn(account, value);

    }



    function setFeeParams(uint newBasisPoints, uint newMaxFee) public onlyWhitelistAdmin{

      require(newBasisPoints < 20,"Exceeded Max BasisPoint");

      require(newMaxFee < 50,"Exceeded MaxFee");

      _basisPointsRate = newBasisPoints;

      _maximumFee = newMaxFee.mul(10 ** uint256(DECIMALS));

      emit FeeParams(_basisPointsRate, _maximumFee);

    }



    function setFeeWallet(address account) public onlyWhitelistAdmin{

        _feeWallet = account;

    }

}