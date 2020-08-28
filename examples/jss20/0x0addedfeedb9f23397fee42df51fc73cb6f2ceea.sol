pragma solidity ^0.5.11;

// ----------------------------------------------------------------------------
// PEG Stable Coin
//
// Symbol      : PEG
// Name        : PEG Stable Coin
// Decimals    : 18
//
// Ciarán Ó hAoláin, Phil Maguire 2019. Maynooth University 2019. The MIT License.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths library
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
/// @notice ERC Token Standard #20 Interface
/// @dev ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


// ----------------------------------------------------------------------------
/// @notice Contract function to receive approval and execute function in one call
/// @dev Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}


// ----------------------------------------------------------------------------
/// @notice Owned Contract
/// @dev Owned Contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
/// @notice DAI Medianiser Interface
/// @dev DAI Medianiser Interface
// ----------------------------------------------------------------------------
interface MedianiserInterface {
    function peek() external view returns (bytes32, bool);
}

// ----------------------------------------------------------------------------
/// @title PEG Stable Coin
/// @author Ciarán Ó hAoláin
/// @notice Defines an ERC20 token which manages the PEG token and its ETH pool
/// @dev Defines an ERC20 token which manages the PEG token and its ETH pool
// ----------------------------------------------------------------------------
contract PEG is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 _totalSupply;
    uint256 lastPriceAdjustment;
    uint256 timeBetweenPriceAdjustments;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    MedianiserInterface medianiser;
    
    event Burn(address indexed tokenOwner, uint256 tokens);
    event gotPEG(address indexed caller, uint256 amountGivenEther, uint256 amountReceivedPEG);
    event gotEther(address indexed caller, uint256 amountGivenPEG, uint256 amountReceivedEther);
    event Inflate(uint256 previousPoolSize, uint256 amountMinted);
    event Deflate(uint256 previousPoolSize, uint256 amountBurned);
    event NoAdjustment();
    event FailedAdjustment();

    // ----------------------------------------------------------------------------
    /// @notice This creates the PEG Stable Coin and creates PEG tokens for the pool
    /// @dev Contract constructor which accepts no parameters
    // ----------------------------------------------------------------------------
    constructor() payable public {
        symbol = "PEG";
        name = "PEG Stablecoin";
        decimals = 18;
        lastPriceAdjustment = now;
        timeBetweenPriceAdjustments = 60*60;
        
        medianiser = MedianiserInterface(0x729D19f657BD0614b4985Cf1D82531c67569197B);
        
        uint256 feedPrice;
        bool priceIsValid;
        (feedPrice, priceIsValid) = getOraclePriceETH_USD();
        require(priceIsValid);
        
        _totalSupply = feedPrice.mul(address(this).balance).div(10**uint(decimals));
        balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }


    // ------------------------------------------------------------------------
    /// @notice Get the current total supply of PEG tokens
    /// @dev Get the current total supply of PEG tokens
    /// @return total supply of PEG tokens
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }


    // ------------------------------------------------------------------------
    /// @notice Get the PEG balance of a given address
    /// @dev Get the PEG balance of a given address
    /// @param tokenOwner The address to find the PEG balance of
    /// @return PEG balance of tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    /// @notice Transfer PEG tokens from a user to another user. Doesn't allow transfers to 0x0 address (use burn())
    /// @dev Transfer PEG tokens from a user to another user. Doesn't allow transfers to 0x0 address (use burn())
    /// @param to Address to send tokens to
    /// @param tokens Quantity of tokens to send
    /// @return true if transfer is successful
    // ----------------f--------------------------------------------------------
    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(to != address(0));
        if (to == address(this)) getEther(tokens);
        else {
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(msg.sender, to, tokens);
        }
        return true;
    }
    
    // ------------------------------------------------------------------------
    /// @notice Burn PEG Tokens
    /// @dev Burn PEG Tokens
    /// @param tokens Quantity of tokens to burn
    /// @return true if burn is successful
    // ------------------------------------------------------------------------
    function burn(uint256 tokens) public returns (bool success) {
        _totalSupply = _totalSupply.sub(tokens);
        balances[msg.sender] -= balances[msg.sender].sub(tokens);
        emit Burn(msg.sender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    /// @notice Token owner can approve for `spender` to `transferFrom(...)` `tokens` from the token owner's account
    /// @dev Token owner can approve for `spender` to `transferFrom(...)` `tokens` from the token owner's account
    /// @param spender Address to authorise to spend tokens on your behalf
    /// @param tokens Quantity of tokens to authorise for spending
    /// @return true if approval is successful
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    /// @notice Transfer `tokens` from the `from` account to the `to` account. Caller must be approved to spend these funds. Can't be to the PEG contract (for conversion).
    /// @dev Transfer `tokens` from the `from` account to the `to` account. Caller must be approved to spend these funds. Can't be to the PEG contract (for conversion).
    /// @param from Address to transfer tokens from
    /// @param to Address tokens will be transferred to. Can't be the PEG contract's address
    /// @param tokens Quantity of tokens to transfer (must be approvedd by `to` address)
    /// @return true if approval is successful
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        require(to != address(0) && to != address(this));
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    /// @notice Get the amount of tokens approved by an address `tokenOwner` for use by `spender`
    /// @dev Get the amount of tokens approved by an address `tokenOwner` for use by `spender`
    /// @param tokenOwner The address owner whose tokens we want to verify approval for
    /// @param spender The address of the potentially approved spender
    /// @return the amount of PEG `spender` is approved to transfer on behalf of `tokenOwner`
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint256 allowancePEG) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    /// @notice Token owner can approve for `spender` to transferFrom(...) `tokens` from the token owner's account. The `spender` contract function `receiveApproval(...)` is then executed
    /// @dev Token owner can approve for `spender` to transferFrom(...) `tokens` from the token owner's account. The `spender` contract function `receiveApproval(...)` is then executed
    /// @param spender The contract address to be approved
    /// @param tokens The number of tokens the caller is approving for `spender` to use
    /// @param data The function call data provided to `spender.receiveApproval()`
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint256 tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


    // ------------------------------------------------------------------------
    /// @notice Ether can be sent directly to the contract in exchange for PEG (if sufficient gas is provided)
    /// @dev Ether can be sent directly to the contract in exchange for PEG (if sufficient gas is provided)
    // ------------------------------------------------------------------------
    function () external payable {
        getPEG();
    }
    
    // Runs a price feed adjustment if more than timeBetweenPriceAdjustments has passed
    modifier canTriggerPriceAdjustment {
        _;
        if (now >= lastPriceAdjustment + timeBetweenPriceAdjustments) priceFeedAdjustment();
    }
    
    // ------------------------------------------------------------------------
    /// @notice Gets the seconds until the next price adjustment
    /// @dev Gets the seconds until the next price adjustment
    /// @return seconds to next price adjustment, or 0 if this will take place after the next conversion transaction
    // ------------------------------------------------------------------------
    function getNextPriceAdjustmentTime() public view returns (uint256 nextPriceAdjustmentTime) {
        if (now >= lastPriceAdjustment + timeBetweenPriceAdjustments) return 0;
        else return lastPriceAdjustment + timeBetweenPriceAdjustments - now;
    }
    
    // ------------------------------------------------------------------------
    /// @notice Provides the caller with PEG in return for Ether
    /// @dev Provides the caller with PEG in return for Ether
    /// @return success true if the transaction is successful
    /// @return amountReceivedPEG the amount of PEG received by the caller
    // ------------------------------------------------------------------------
    function getPEG() public payable canTriggerPriceAdjustment returns (bool success, uint256 amountReceivedPEG) {
        amountReceivedPEG = balances[address(this)].mul(msg.value.mul(10**8).div(address(this).balance)).div(10**8);
        balances[address(this)] = balances[address(this)].sub(amountReceivedPEG);
        balances[msg.sender] = balances[msg.sender].add(amountReceivedPEG);
        emit gotPEG(msg.sender, msg.value, amountReceivedPEG);
        emit Transfer(address(this), msg.sender, amountReceivedPEG);
        return (true, amountReceivedPEG);
    }
    
    // ------------------------------------------------------------------------
    /// @notice Provides the caller with Ether in return for PEG
    /// @dev Provides the caller with Ether in return for PEG
    /// @param amountGivenPEG the quantity of PEG you want to exchange for Ether
    /// @return success true if the transaction was successful
    /// @return amountReceivedEther the amount of Ether received by the caller
    // ------------------------------------------------------------------------
    function getEther(uint256 amountGivenPEG) public canTriggerPriceAdjustment returns (bool success, uint256 amountReceivedEther) {
        amountReceivedEther = address(this).balance.mul(amountGivenPEG.mul(10**8).div(balances[address(this)].add(amountGivenPEG))).div(10**8);
        balances[address(this)] = balances[address(this)].add(amountGivenPEG);
        balances[msg.sender] = balances[msg.sender].sub(amountGivenPEG);
        emit gotEther(msg.sender, amountGivenPEG, amountReceivedEther);
        emit Transfer(msg.sender, address(this), amountGivenPEG);
        msg.sender.transfer(amountReceivedEther);
        return (true, amountReceivedEther);
    }
    
    // ------------------------------------------------------------------------
    /// @notice Get the quantity of Ether and PEG in the pools
    /// @dev Get the quantity of Ether and PEG in the pools
    /// @return balanceETH the amount of Ether in the pool
    /// @return balancePEG the amount of PEG in the pool
    // ------------------------------------------------------------------------
    function getPoolBalances() public view returns (uint256 balanceETH, uint256 balancePEG) {
        return (address(this).balance, balanceOf(address(this)));
    }
    
    // ------------------------------------------------------------------------
    /// @notice Increase the size of the ETH pool WITHOUT GAINING ANYTHING
    /// @dev Increase the size of the ETH pool WITHOUT GAINING ANYTHING
    /// @return true if the transaction is successful
    // ------------------------------------------------------------------------
    function inflateEtherPool() public payable returns (bool success) {
        return true;
    }
    
    // ------------------------------------------------------------------------
    /// @notice Gets the current ETH_USD exchange rate, according to the MakerDAO Oracle
    /// @dev Gets the current ETH_USD exchange rate, according to the MakerDAO Oracle
    /// @return priceETH_USD the current ETH_USD exchange rate
    /// @return priceIsValid true if oracle says it has a value
    // ------------------------------------------------------------------------
    function getOraclePriceETH_USD() public view returns (uint256 priceETH_USD, bool priceIsValid) {
        bytes32 price;
        (price, priceIsValid) = medianiser.peek();
        return (uint(price), priceIsValid);
    }
    
    // ------------------------------------------------------------------------
    /// @notice (private) Performs a pool size adjustment (+/- 10% of the difference) if > 1% deviation
    /// @dev (private) Performs a pool size adjustment (+/- 10% of the difference) if > 1% deviation
    /// @return The new size of the PEG pool
    // ------------------------------------------------------------------------
    function priceFeedAdjustment() private returns (uint256 newRatePEG) {
        uint256 feedPrice;
        bool priceIsValid;
        (feedPrice, priceIsValid) = getOraclePriceETH_USD();
        
        if (!priceIsValid) {
            newRatePEG = balances[address(this)];
            lastPriceAdjustment = now;
            emit FailedAdjustment();
            return (newRatePEG);
        }
        
        feedPrice = feedPrice.mul(address(this).balance).div(10**uint(decimals));
        if (feedPrice > (balances[address(this)]/100)*101 ) {
            uint256 posDelta = feedPrice.sub(balances[address(this)]).div(10);
            newRatePEG = balances[address(this)].add(posDelta);
            emit Inflate(balances[address(this)], posDelta);
            emit Transfer(address(0), address(this), posDelta);
            balances[address(this)] = newRatePEG;
            _totalSupply = _totalSupply.add(posDelta);
        } else if (feedPrice < (balances[address(this)]/100)*99) {
            uint256 negDelta = balances[address(this)].sub(feedPrice).div(10);
            newRatePEG = balances[address(this)].sub(negDelta);
            emit Deflate(balances[address(this)], negDelta);
            emit Transfer(address(this), address(0), negDelta);
            balances[address(this)] = newRatePEG;
            _totalSupply = _totalSupply.sub(negDelta);
        } else {
            newRatePEG = balances[address(this)];
            emit NoAdjustment();
        }
        lastPriceAdjustment = now;
    }

    // ------------------------------------------------------------------------
    /// @notice Allows the contract owner to withdraw wasted tokens
    /// @dev Allows the contract owner to withdraw wasted tokens
    /// @param tokenAddress the contract address of the token to be transferred
    /// @param tokens the quantity of tokens to be transferred
    /// @return true if the transaction is successful
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        require(tokenAddress != address(this));
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    function dumpContractCode() public view returns (bytes memory o_code) {
        address _addr = address(this);
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }
}