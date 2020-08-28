pragma solidity ^0.5.11;

// Math library (standard operations)
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256){
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// Allows owenership to be transferred between addresses for a cost (_costToBuy)
contract Ownable {
  address payable private _owner;
  address payable private _potentialNewOwner;
  uint private _costToBuy;
 
  event OwnershipTransferred(address payable indexed from, address payable indexed to, uint costToBuy);

  constructor() internal {
    _owner = msg.sender;
  }
  
  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }
  
  function transferOwnership(address payable newOwner) external onlyOwner {
    _potentialNewOwner = newOwner;
  }
  
  function acceptOwnership() external payable{
    require(msg.sender == _potentialNewOwner);
    require(_costToBuy == msg.value);
    _owner.transfer(_costToBuy);
    _owner = _potentialNewOwner;
    emit OwnershipTransferred(_owner, _potentialNewOwner, _costToBuy);
  }
  
  function getOwner() public view returns(address payable){
      return _owner;
  }
  
  function getCostToBuy() public view returns(uint){
      return _costToBuy;
  }
  
  function setCostToBuy(uint costToBuy) external onlyOwner{
      _costToBuy = costToBuy;
  }
}

// Allows the shutdown of the token at any time (to be used with any write operation related function)
contract CircuitBreaker is Ownable {
    bool public inLockdown;

    constructor () internal {
        inLockdown = false;
    }
    
    modifier outOfLockdown() {
        require(inLockdown == false);
        _;
    }
    
    function updateLockdownState(bool state) public{
        inLockdown = state;
    }
}

// The interface that enforces us to use all of the ERC20 standard functions (definition)
contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// The basic ERC20
contract ERC20 is ERC20Interface {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;
  mapping (address => mapping (address => uint256)) allowed;

  function balanceOf(address _owner) view public returns (uint256 balance) {
    return balances[_owner];
  }
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  
  function approve(address _spender, uint256 _value) public returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  
  function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

// An extension allowing the ERC20 to allow coins to be minted into existance at any point
contract MintableToken is ERC20{
    
  event Minted(address target, uint mintedAmount, uint time);
  
  function mintToken(address target, uint256 mintedAmount) public returns(bool){
	balances[target] = balances[target].add(mintedAmount);
	totalSupply = totalSupply.add(mintedAmount);
	emit Transfer(address(0), address(this), mintedAmount);
	emit Transfer(address(this), target, mintedAmount);
	emit Minted(target, mintedAmount, now);
	return true;
  }
}

// An extension allowing the ERC20 to send any token sent to it to the owner (so they are recoverable)
contract RecoverableToken is ERC20, Ownable {
  constructor() public {}
   
  event RecoveredTokens(address token, address owner, uint tokens, uint time);
  
  function recoverTokens(ERC20 token) public {
    uint tokens = tokensToBeReturned(token);
    require(token.transfer(getOwner(), tokens) == true);
    emit RecoveredTokens(address(token), getOwner(),  tokens, now);
  }
  function tokensToBeReturned(ERC20 token) public view returns (uint256) {
    return token.balanceOf(address(this));
  }
}

// An extension that allows the ERC20 to burn tokens from existance at any point
contract BurnableToken is ERC20 {
  address public BURN_ADDRESS;

  event Burned(address burner, uint256 burnedAmount);
 
  function burn(uint256 burnAmount) public {
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(burnAmount);
    totalSupply = totalSupply.sub(burnAmount);
    emit Burned(burner, burnAmount);
    emit Transfer(burner, BURN_ADDRESS, burnAmount);
  }
}

// An extension that allows the ERC20 owner to withdraw all ETH from the contract
contract WithdrawableToken is ERC20, Ownable {
    
  event WithdrawLog(uint256 balanceBefore, uint256 amount, uint256 balanceAfter);
  
  function withdraw(uint256 amount) public returns(bool){
	require(amount <= address(this).balance);
    getOwner().transfer(amount);
	emit WithdrawLog(address(getOwner()).balance.sub(amount), amount, address(getOwner()).balance);
    return true;
  } 
}

// The coin
contract BigPeiceOfShitCoin is RecoverableToken, BurnableToken, MintableToken, WithdrawableToken, CircuitBreaker { 
  string public name;
  string public symbol;
  uint256 public decimals;
  address payable public creator;
  
  event LogFundsReceived(address sender, uint amount);
  event UpdatedTokenInformation(string newName, string newSymbol);

  constructor(uint256 _totalTokensToMint) payable public {
    name = "BigPeiceOfShitCoin";
    symbol = "BPOS";
    totalSupply = _totalTokensToMint;
    decimals = 2;
    balances[msg.sender] = totalSupply;
    creator = msg.sender;
    emit LogFundsReceived(msg.sender, msg.value);
  }
  
  function() payable external outOfLockdown {
    emit LogFundsReceived(msg.sender, msg.value);
  }
  
  function transfer(address _to, uint256 _value) public outOfLockdown returns (bool success){
    return super.transfer(_to, _value);
  }
  
  function transferFrom(address _from, address _to, uint256 _value) public outOfLockdown returns (bool success){
    return super.transferFrom(_from, _to, _value);
  }
  
  function multipleTransfer(address[] calldata _toAddresses, uint256[] calldata _toValues) external outOfLockdown returns (uint256) {
    require(_toAddresses.length == _toValues.length);
    uint256 updatedCount = 0;
    for(uint256 i = 0;i<_toAddresses.length;i++){
       if(super.transfer(_toAddresses[i], _toValues[i]) == true){
           updatedCount++;
       }
    }
    return updatedCount;
  }
  
  function approve(address _spender, uint256 _value) public outOfLockdown  returns (bool) {
    return super.approve(_spender, _value);
  }
  
  function setTokenInformation(string calldata _name, string calldata _symbol) onlyOwner external {
    require(msg.sender != creator);
    name = _name;
    symbol = _symbol;
    emit UpdatedTokenInformation(name, symbol);
  }
  
  function withdraw(uint256 _amount) onlyOwner public returns(bool){
	return super.withdraw(_amount);
  }

  function mintToken(address _target, uint256 _mintedAmount) onlyOwner public returns (bool){
	return super.mintToken(_target, _mintedAmount);
  }
  
  function burn(uint256 _burnAmount) onlyOwner public{
    return super.burn(_burnAmount);
  }
  
  function updateLockdownState(bool _state) onlyOwner public{
    super.updateLockdownState(_state);
  }
  
  function recoverTokens(ERC20 _token) onlyOwner public{
     super.recoverTokens(_token);
  }
  
  function isToken() public pure returns (bool) {
    return true;
  }

  function deprecateContract() onlyOwner external{
    selfdestruct(creator);
  }
}