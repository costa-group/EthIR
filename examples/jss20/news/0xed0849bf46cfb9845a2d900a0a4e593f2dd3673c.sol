pragma solidity ^0.4.25;


// File: contracts/saga/interfaces/IPaymentHandler.sol



/**

 * @title Payment Handler Interface.

 */

interface IPaymentHandler {

    /**

     * @dev Get the amount of available ETH.

     * @return The amount of available ETH.

     */

    function getEthBalance() external view returns (uint256);



    /**

     * @dev Transfer ETH to an SGA holder.

     * @param _to The address of the SGA holder.

     * @param _value The amount of ETH to transfer.

     */

    function transferEthToSgaHolder(address _to, uint256 _value) external;

}



// File: contracts/saga/interfaces/IMintListener.sol



/**

 * @title Mint Listener Interface.

 */

interface IMintListener {

    /**

     * @dev Mint SGA for SGN holders.

     * @param _value The amount of SGA to mint.

     */

    function mintSgaForSgnHolders(uint256 _value) external;

}



// File: contracts/saga/interfaces/ISGATokenManager.sol



/**

 * @title SGA Token Manager Interface.

 */

interface ISGATokenManager {

    /**

     * @dev Exchange ETH for SGA.

     * @param _sender The address of the sender.

     * @param _ethAmount The amount of ETH received.

     * @return The amount of SGA that the sender is entitled to.

     */

    function exchangeEthForSga(address _sender, uint256 _ethAmount) external returns (uint256);



    /**

     * @dev Exchange SGA for ETH.

     * @param _sender The address of the sender.

     * @param _sgaAmount The amount of SGA received.

     * @return The amount of ETH that the sender is entitled to.

     */

    function exchangeSgaForEth(address _sender, uint256 _sgaAmount) external returns (uint256);



    /**

     * @dev Handle direct SGA transfer.

     * @param _sender The address of the sender.

     * @param _to The address of the destination account.

     * @param _value The amount of SGA to be transferred.

     */

    function uponTransfer(address _sender, address _to, uint256 _value) external;



    /**

     * @dev Handle custodian SGA transfer.

     * @param _sender The address of the sender.

     * @param _from The address of the source account.

     * @param _to The address of the destination account.

     * @param _value The amount of SGA to be transferred.

     */

    function uponTransferFrom(address _sender, address _from, address _to, uint256 _value) external;



    /**

     * @dev Handle the operation of ETH deposit into the SGAToken contract.

     * @param _sender The address of the account which has issued the operation.

     * @param _balance The amount of ETH in the SGAToken contract.

     * @param _amount The deposited ETH amount.

     * @return The address of the reserve-wallet and the deficient amount of ETH in the SGAToken contract.

     */

    function uponDeposit(address _sender, uint256 _balance, uint256 _amount) external returns (address, uint256);



    /**

     * @dev Handle the operation of ETH withdrawal from the SGAToken contract.

     * @param _sender The address of the account which has issued the operation.

     * @param _balance The amount of ETH in the SGAToken contract prior the withdrawal.

     * @return The address of the reserve-wallet and the excessive amount of ETH in the SGAToken contract.

     */

    function uponWithdraw(address _sender, uint256 _balance) external returns (address, uint256);



    /** 

     * @dev Upon SGA mint for SGN holders.

     * @param _value The amount of SGA to mint.

     */

    function uponMintSgaForSgnHolders(uint256 _value) external;



    /**

     * @dev Upon SGA transfer to an SGN holder.

     * @param _to The address of the SGN holder.

     * @param _value The amount of SGA to transfer.

     */

    function uponTransferSgaToSgnHolder(address _to, uint256 _value) external;



    /**

     * @dev Upon ETH transfer to an SGA holder.

     * @param _to The address of the SGA holder.

     * @param _value The amount of ETH to transfer.

     * @param _status The operation's completion-status.

     */

    function postTransferEthToSgaHolder(address _to, uint256 _value, bool _status) external;



    /**

     * @dev Get the address of the reserve-wallet and the deficient amount of ETH in the SGAToken contract.

     * @return The address of the reserve-wallet and the deficient amount of ETH in the SGAToken contract.

     */

    function getDepositParams() external view returns (address, uint256);



    /**

     * @dev Get the address of the reserve-wallet and the excessive amount of ETH in the SGAToken contract.

     * @return The address of the reserve-wallet and the excessive amount of ETH in the SGAToken contract.

     */

    function getWithdrawParams() external view returns (address, uint256);

}



// File: contracts/contract_address_locator/interfaces/IContractAddressLocator.sol



/**

 * @title Contract Address Locator Interface.

 */

interface IContractAddressLocator {

    /**

     * @dev Get the contract address mapped to a given identifier.

     * @param _identifier The identifier.

     * @return The contract address.

     */

    function getContractAddress(bytes32 _identifier) external view returns (address);



    /**

     * @dev Determine whether or not a contract address relates to one of the identifiers.

     * @param _contractAddress The contract address to look for.

     * @param _identifiers The identifiers.

     * @return A boolean indicating if the contract address relates to one of the identifiers.

     */

    function isContractAddressRelates(address _contractAddress, bytes32[] _identifiers) external view returns (bool);

}



// File: contracts/contract_address_locator/ContractAddressLocatorHolder.sol



/**

 * @title Contract Address Locator Holder.

 * @dev Hold a contract address locator, which maps a unique identifier to every contract address in the system.

 * @dev Any contract which inherits from this contract can retrieve the address of any contract in the system.

 * @dev Thus, any contract can remain "oblivious" to the replacement of any other contract in the system.

 * @dev In addition to that, any function in any contract can be restricted to a specific caller.

 */

contract ContractAddressLocatorHolder {

    bytes32 internal constant _IAuthorizationDataSource_ = "IAuthorizationDataSource";

    bytes32 internal constant _ISGNConversionManager_    = "ISGNConversionManager"      ;

    bytes32 internal constant _IModelDataSource_         = "IModelDataSource"        ;

    bytes32 internal constant _IPaymentHandler_          = "IPaymentHandler"            ;

    bytes32 internal constant _IPaymentManager_          = "IPaymentManager"            ;

    bytes32 internal constant _IPaymentQueue_            = "IPaymentQueue"              ;

    bytes32 internal constant _IReconciliationAdjuster_  = "IReconciliationAdjuster"      ;

    bytes32 internal constant _IIntervalIterator_        = "IIntervalIterator"       ;

    bytes32 internal constant _IMintHandler_             = "IMintHandler"            ;

    bytes32 internal constant _IMintListener_            = "IMintListener"           ;

    bytes32 internal constant _IMintManager_             = "IMintManager"            ;

    bytes32 internal constant _IPriceBandCalculator_     = "IPriceBandCalculator"       ;

    bytes32 internal constant _IModelCalculator_         = "IModelCalculator"        ;

    bytes32 internal constant _IRedButton_               = "IRedButton"              ;

    bytes32 internal constant _IReserveManager_          = "IReserveManager"         ;

    bytes32 internal constant _ISagaExchanger_           = "ISagaExchanger"          ;

    bytes32 internal constant _IMonetaryModel_               = "IMonetaryModel"              ;

    bytes32 internal constant _IMonetaryModelState_          = "IMonetaryModelState"         ;

    bytes32 internal constant _ISGAAuthorizationManager_ = "ISGAAuthorizationManager";

    bytes32 internal constant _ISGAToken_                = "ISGAToken"               ;

    bytes32 internal constant _ISGATokenManager_         = "ISGATokenManager"        ;

    bytes32 internal constant _ISGNAuthorizationManager_ = "ISGNAuthorizationManager";

    bytes32 internal constant _ISGNToken_                = "ISGNToken"               ;

    bytes32 internal constant _ISGNTokenManager_         = "ISGNTokenManager"        ;

    bytes32 internal constant _IMintingPointTimersManager_             = "IMintingPointTimersManager"            ;

    bytes32 internal constant _ITradingClasses_          = "ITradingClasses"         ;

    bytes32 internal constant _IWalletsTradingLimiterValueConverter_        = "IWalletsTLValueConverter"       ;

    bytes32 internal constant _IWalletsTradingDataSource_       = "IWalletsTradingDataSource"      ;

    bytes32 internal constant _WalletsTradingLimiter_SGNTokenManager_          = "WalletsTLSGNTokenManager"         ;

    bytes32 internal constant _WalletsTradingLimiter_SGATokenManager_          = "WalletsTLSGATokenManager"         ;

    bytes32 internal constant _IETHConverter_             = "IETHConverter"   ;

    bytes32 internal constant _ITransactionLimiter_      = "ITransactionLimiter"     ;

    bytes32 internal constant _ITransactionManager_      = "ITransactionManager"     ;

    bytes32 internal constant _IRateApprover_      = "IRateApprover"     ;



    IContractAddressLocator private contractAddressLocator;



    /**

     * @dev Create the contract.

     * @param _contractAddressLocator The contract address locator.

     */

    constructor(IContractAddressLocator _contractAddressLocator) internal {

        require(_contractAddressLocator != address(0), "locator is illegal");

        contractAddressLocator = _contractAddressLocator;

    }



    /**

     * @dev Get the contract address locator.

     * @return The contract address locator.

     */

    function getContractAddressLocator() external view returns (IContractAddressLocator) {

        return contractAddressLocator;

    }



    /**

     * @dev Get the contract address mapped to a given identifier.

     * @param _identifier The identifier.

     * @return The contract address.

     */

    function getContractAddress(bytes32 _identifier) internal view returns (address) {

        return contractAddressLocator.getContractAddress(_identifier);

    }







    /**

     * @dev Determine whether or not the sender relates to one of the identifiers.

     * @param _identifiers The identifiers.

     * @return A boolean indicating if the sender relates to one of the identifiers.

     */

    function isSenderAddressRelates(bytes32[] _identifiers) internal view returns (bool) {

        return contractAddressLocator.isContractAddressRelates(msg.sender, _identifiers);

    }



    /**

     * @dev Verify that the caller is mapped to a given identifier.

     * @param _identifier The identifier.

     */

    modifier only(bytes32 _identifier) {

        require(msg.sender == getContractAddress(_identifier), "caller is illegal");

        _;

    }



}



// File: contracts/saga-genesis/interfaces/ISagaExchanger.sol



/**

 * @title Saga Exchanger Interface.

 */

interface ISagaExchanger {

    /**

     * @dev Transfer SGA to an SGN holder.

     * @param _to The address of the SGN holder.

     * @param _value The amount of SGA to transfer.

     */

    function transferSgaToSgnHolder(address _to, uint256 _value) external;

}



// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol



/**

 * @title ERC20 interface

 * @dev see https://github.com/ethereum/EIPs/issues/20

 */

interface IERC20 {

  function totalSupply() external view returns (uint256);



  function balanceOf(address who) external view returns (uint256);



  function allowance(address owner, address spender)

    external view returns (uint256);



  function transfer(address to, uint256 value) external returns (bool);



  function approve(address spender, uint256 value)

    external returns (bool);



  function transferFrom(address from, address to, uint256 value)

    external returns (bool);



  event Transfer(

    address indexed from,

    address indexed to,

    uint256 value

  );



  event Approval(

    address indexed owner,

    address indexed spender,

    uint256 value

  );

}



// File: openzeppelin-solidity/contracts/math/SafeMath.sol



/**

 * @title SafeMath

 * @dev Math operations with safety checks that revert on error

 */

library SafeMath {



  /**

  * @dev Multiplies two numbers, reverts on overflow.

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

  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.

  */

  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b > 0); // Solidity only automatically asserts when dividing by 0

    uint256 c = a / b;

    // assert(a == b * c + a % b); // There is no case in which this doesn't hold



    return c;

  }



  /**

  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).

  */

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b <= a);

    uint256 c = a - b;



    return c;

  }



  /**

  * @dev Adds two numbers, reverts on overflow.

  */

  function add(uint256 a, uint256 b) internal pure returns (uint256) {

    uint256 c = a + b;

    require(c >= a);



    return c;

  }



  /**

  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),

  * reverts when dividing by zero.

  */

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b != 0);

    return a % b;

  }

}



// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol



/**

 * @title Standard ERC20 token

 *

 * @dev Implementation of the basic standard token.

 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md

 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol

 */

contract ERC20 is IERC20 {

  using SafeMath for uint256;



  mapping (address => uint256) private _balances;



  mapping (address => mapping (address => uint256)) private _allowed;



  uint256 private _totalSupply;



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

   * @dev Function to check the amount of tokens that an owner allowed to a spender.

   * @param owner address The address which owns the funds.

   * @param spender address The address which will spend the funds.

   * @return A uint256 specifying the amount of tokens still available for the spender.

   */

  function allowance(

    address owner,

    address spender

   )

    public

    view

    returns (uint256)

  {

    return _allowed[owner][spender];

  }



  /**

  * @dev Transfer token for a specified address

  * @param to The address to transfer to.

  * @param value The amount to be transferred.

  */

  function transfer(address to, uint256 value) public returns (bool) {

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

   * @dev Transfer tokens from one address to another

   * @param from address The address which you want to send tokens from

   * @param to address The address which you want to transfer to

   * @param value uint256 the amount of tokens to be transferred

   */

  function transferFrom(

    address from,

    address to,

    uint256 value

  )

    public

    returns (bool)

  {

    require(value <= _allowed[from][msg.sender]);



    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    _transfer(from, to, value);

    return true;

  }



  /**

   * @dev Increase the amount of tokens that an owner allowed to a spender.

   * approve should be called when allowed_[_spender] == 0. To increment

   * allowed value is better to use this function to avoid 2 calls (and wait until

   * the first transaction is mined)

   * From MonolithDAO Token.sol

   * @param spender The address which will spend the funds.

   * @param addedValue The amount of tokens to increase the allowance by.

   */

  function increaseAllowance(

    address spender,

    uint256 addedValue

  )

    public

    returns (bool)

  {

    require(spender != address(0));



    _allowed[msg.sender][spender] = (

      _allowed[msg.sender][spender].add(addedValue));

    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

    return true;

  }



  /**

   * @dev Decrease the amount of tokens that an owner allowed to a spender.

   * approve should be called when allowed_[_spender] == 0. To decrement

   * allowed value is better to use this function to avoid 2 calls (and wait until

   * the first transaction is mined)

   * From MonolithDAO Token.sol

   * @param spender The address which will spend the funds.

   * @param subtractedValue The amount of tokens to decrease the allowance by.

   */

  function decreaseAllowance(

    address spender,

    uint256 subtractedValue

  )

    public

    returns (bool)

  {

    require(spender != address(0));



    _allowed[msg.sender][spender] = (

      _allowed[msg.sender][spender].sub(subtractedValue));

    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

    return true;

  }



  /**

  * @dev Transfer token for a specified addresses

  * @param from The address to transfer from.

  * @param to The address to transfer to.

  * @param value The amount to be transferred.

  */

  function _transfer(address from, address to, uint256 value) internal {

    require(value <= _balances[from]);

    require(to != address(0));



    _balances[from] = _balances[from].sub(value);

    _balances[to] = _balances[to].add(value);

    emit Transfer(from, to, value);

  }



  /**

   * @dev Internal function that mints an amount of the token and assigns it to

   * an account. This encapsulates the modification of balances such that the

   * proper events are emitted.

   * @param account The account that will receive the created tokens.

   * @param value The amount that will be created.

   */

  function _mint(address account, uint256 value) internal {

    require(account != 0);

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

  function _burn(address account, uint256 value) internal {

    require(account != 0);

    require(value <= _balances[account]);



    _totalSupply = _totalSupply.sub(value);

    _balances[account] = _balances[account].sub(value);

    emit Transfer(account, address(0), value);

  }



  /**

   * @dev Internal function that burns an amount of the token of a given

   * account, deducting from the sender's allowance for said account. Uses the

   * internal burn function.

   * @param account The account whose tokens will be burnt.

   * @param value The amount that will be burnt.

   */

  function _burnFrom(address account, uint256 value) internal {

    require(value <= _allowed[account][msg.sender]);



    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,

    // this function needs to emit an event with the updated approval.

    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(

      value);

    _burn(account, value);

  }

}



// File: contracts/saga/SGAToken.sol



/**

 * Details of usage of licenced software see here: https://www.saga.org/software/readme_v1

 */



/**

 * @title Saga Token.

 * @dev ERC20 compatible.

 * @dev Exchange ETH for SGA.

 * @dev Exchange SGA for ETH.

 */

contract SGAToken is ERC20, ContractAddressLocatorHolder, IMintListener, ISagaExchanger, IPaymentHandler {

    string public constant VERSION = "1.0.0";



    string public constant name = "Saga";

    string public constant symbol = "SGA";

    uint8  public constant decimals = 18;



    /**

     * @dev Public Address 0x10063FCCf5eEE46fC65D399a7F5dd88730906CF9.

     * @notice SGA will be minted at this public address for SGN holders.

     * @notice SGA will be transferred from this public address upon conversion by an SGN holder.

     * @notice It is generated in a manner which ensures that the corresponding private key is unknown.

     */

    address public constant SGA_MINTED_FOR_SGN_HOLDERS = address(keccak256("SGA_MINTED_FOR_SGN_HOLDERS"));



    /**

     * @dev Create the contract.

     * @param _contractAddressLocator The contract address locator.

     */

    constructor(IContractAddressLocator _contractAddressLocator) ContractAddressLocatorHolder(_contractAddressLocator) public {}



    /**

     * @dev Return the contract which implements the ISGATokenManager interface.

     */

    function getSGATokenManager() public view returns (ISGATokenManager) {

        return ISGATokenManager(getContractAddress(_ISGATokenManager_));

    }



    /**

     * @dev Exchange ETH for SGA.

     * @notice Can be executed from externally-owned accounts but not from other contracts.

     * @notice This is due to the insufficient gas-stipend provided to the fallback function.

     */

    function() external payable {

        uint256 amount = getSGATokenManager().exchangeEthForSga(msg.sender, msg.value);

        _mint(msg.sender, amount);

    }



    /**

     * @dev Exchange ETH for SGA.

     * @notice Can be executed from externally-owned accounts as well as from other contracts.

     */

    function exchange() external payable {

        uint256 amount = getSGATokenManager().exchangeEthForSga(msg.sender, msg.value);

        _mint(msg.sender, amount);

    }



    /**

     * @dev Transfer SGA to another account.

     * @param _to The address of the destination account.

     * @param _value The amount of SGA to be transferred.

     * @return Status (true if completed successfully, false otherwise).

     * @notice If the destination account is this contract, then exchange SGA for ETH.

     */

    function transfer(address _to, uint256 _value) public returns (bool) {

        if (_to == address(this)) {

            uint256 amount = getSGATokenManager().exchangeSgaForEth(msg.sender, _value);

            _burn(msg.sender, _value);

            msg.sender.transfer(amount);

            return true;

        }

        getSGATokenManager().uponTransfer(msg.sender, _to, _value);

        return super.transfer(_to, _value);

    }



    /**

     * @dev Transfer SGA from one account to another.

     * @param _from The address of the source account.

     * @param _to The address of the destination account.

     * @param _value The amount of SGA to be transferred.

     * @return Status (true if completed successfully, false otherwise).

     * @notice If the destination account is this contract, then the operation is illegal.

     */

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(_to != address(this), "custodian-transfer of SGA into this contract is illegal");

        getSGATokenManager().uponTransferFrom(msg.sender, _from, _to, _value);

        return super.transferFrom(_from, _to, _value);

    }



    /**

     * @dev Deposit ETH into this contract.

     */

    function deposit() external payable {

        getSGATokenManager().uponDeposit(msg.sender, address(this).balance, msg.value);

    }



    /**

     * @dev Withdraw ETH from this contract.

     */

    function withdraw() external {

        (address wallet, uint256 amount) = getSGATokenManager().uponWithdraw(msg.sender, address(this).balance);

        wallet.transfer(amount);

    }



    /**

     * @dev Mint SGA for SGN holders.

     * @param _value The amount of SGA to mint.

     */

    function mintSgaForSgnHolders(uint256 _value) external only(_IMintManager_) {

        getSGATokenManager().uponMintSgaForSgnHolders(_value);

        _mint(SGA_MINTED_FOR_SGN_HOLDERS, _value);

    }



    /**

     * @dev Transfer SGA to an SGN holder.

     * @param _to The address of the SGN holder.

     * @param _value The amount of SGA to transfer.

     */

    function transferSgaToSgnHolder(address _to, uint256 _value) external only(_ISGNToken_) {

        getSGATokenManager().uponTransferSgaToSgnHolder(_to, _value);

        _transfer(SGA_MINTED_FOR_SGN_HOLDERS, _to, _value);

    }



    /**

     * @dev Transfer ETH to an SGA holder.

     * @param _to The address of the SGA holder.

     * @param _value The amount of ETH to transfer.

     */

    function transferEthToSgaHolder(address _to, uint256 _value) external only(_IPaymentManager_) {

        bool status = _to.send(_value);

        getSGATokenManager().postTransferEthToSgaHolder(_to, _value, status);

    }



    /**

     * @dev Get the amount of available ETH.

     * @return The amount of available ETH.

     */

    function getEthBalance() external view returns (uint256) {

        return address(this).balance;

    }



    /**

     * @dev Get the address of the reserve-wallet and the deficient amount of ETH in this contract.

     * @return The address of the reserve-wallet and the deficient amount of ETH in this contract.

     */

    function getDepositParams() external view returns (address, uint256) {

        return getSGATokenManager().getDepositParams();

    }



    /**

     * @dev Get the address of the reserve-wallet and the excessive amount of ETH in this contract.

     * @return The address of the reserve-wallet and the excessive amount of ETH in this contract.

     */

    function getWithdrawParams() external view returns (address, uint256) {

        return getSGATokenManager().getWithdrawParams();

    }

}
