pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

contract MultiSigInterface{
  function update_and_check_reach_majority(uint64 id, string memory name, bytes32 hash, address sender) public returns (bool);
  function is_signer(address addr) public view returns(bool);
}

contract MultiSigTools{
  MultiSigInterface public multisig_contract;
  constructor(address _contract) public{
    require(_contract!= address(0x0));
    multisig_contract = MultiSigInterface(_contract);
  }

  modifier only_signer{
    require(multisig_contract.is_signer(msg.sender), "only a signer can call in MultiSigTools");
    _;
  }

  modifier is_majority_sig(uint64 id, string memory name) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sig, msg.data));
    if(multisig_contract.update_and_check_reach_majority(id, name, hash, msg.sender)){
      _;
    }
  }

  event TransferMultiSig(address _old, address _new);

  function transfer_multisig(uint64 id, address _contract) public only_signer
  is_majority_sig(id, "transfer_multisig"){
    require(_contract != address(0x0));
    address old = address(multisig_contract);
    multisig_contract = MultiSigInterface(_contract);
    emit TransferMultiSig(old, _contract);
  }
}
library AddressArray{
  function exists(address[] storage self, address addr) public view returns(bool){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return true;
      }
    }
    return false;
  }

  function index_of(address[] storage self, address addr) public view returns(uint){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return i;
      }
    }
    require(false, "AddressArray:index_of, not exist");
  }

  function remove(address[] storage self, address addr) public returns(bool){
    uint index = index_of(self, addr);
    self[index] = self[self.length - 1];

    delete self[self.length-1];
    self.length--;
  }

  function replace(address[] storage self, address old_addr, address new_addr) public returns(bool){
    uint index = index_of(self, old_addr);
    self[index] = new_addr;
  }
}

contract TransferableToken{
    function balanceOf(address _owner) public returns (uint256 balance) ;
    function transfer(address _to, uint256 _amount) public returns (bool success) ;
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) ;
}


contract TokenClaimer{

    event ClaimedTokens(address indexed _token, address indexed _to, uint _amount);
    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
  function _claimStdTokens(address _token, address payable to) internal {
        if (_token == address(0x0)) {
            to.transfer(address(this).balance);
            return;
        }
        TransferableToken token = TransferableToken(_token);
        uint balance = token.balanceOf(address(this));

        (bool status,) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", to, balance));
        require(status, "call failed");
        emit ClaimedTokens(_token, to, balance);
  }
}

contract TokenInterface is TransferableToken{
    function destroyTokens(address _owner, uint _amount) public returns (bool);
    function generateTokens(address _owner, uint _amount) public returns (bool);
}

contract PeriodMint is MultiSigTools{
  using SafeMath for uint;
  using AddressArray for address[];

  TokenInterface public token_contract;
  uint public last_block_num;
  uint public period_block_num;
  uint public period_share;
  uint public total_alloc_share;

  mapping(address => uint) public share_amounts;
  address[] public shareholders;

  address public admin;

  constructor(address _token, uint _start_block, uint _period, uint _period_share,
                            address _multisig) MultiSigTools(_multisig) public {
    token_contract = TokenInterface(_token);
    last_block_num = _start_block;
    period_block_num = _period;
    period_share = _period_share;
    total_alloc_share = 0;
    admin = address(0);
  }

  function issue() public {
    uint interval = block.number.safeSub(last_block_num);
    uint periods = interval.safeDiv(period_block_num);
    if(periods == 0) return ;

    last_block_num = last_block_num.safeAdd(periods.safeMul(period_block_num));
    uint total_allocation = total_alloc_share;
    uint total_shares = periods.safeMul(period_share);
    for(uint i = 0; i < shareholders.length; i++){
      if(share_amounts[shareholders[i]] == 0) continue;
      uint t = share_amounts[shareholders[i]].safeMul(total_shares).safeDiv(total_allocation);
      token_contract.generateTokens(shareholders[i], t);
    }
  }

  function delegate_admin(uint64 id, address _admin) public only_signer is_majority_sig(id, "delegate_admin"){
    require(_admin != address(0x0), "invalid address");
    admin = _admin;
  }

  function cancel_delegate_admin(uint64 id) public only_signer is_majority_sig(id, "cancel_delegate_admin"){
    admin = address(0x0);
  }

  modifier only_admin{
    require(admin != address(0x0), "admin not set");
    require(msg.sender == admin, "only admin can op this");
    _;
  }

  function shareholder_exists(address account) private view returns(bool){
    return shareholders.exists(account);
  }

  function _internal_add_shareholder(address account, uint amount) private{
    require(amount > 0, "invalid amount");
    require(account != address(0), "invalid address");
    require(!shareholder_exists(account), "already exist");

    issue();

    shareholders.push(account);
    share_amounts[account] = amount;
    total_alloc_share = total_alloc_share.safeAdd(amount);
  }


  function admin_add_shareholder(address account, uint amount) public only_admin{
    _internal_add_shareholder(account, amount);
  }

  function add_shareholder(uint64 id, address account, uint amount)
    public
    only_signer
    is_majority_sig(id, "add_shareholder")
  {
    _internal_add_shareholder(account, amount);
  }

  function _internal_config_shareholder(address account, uint amount) private{
    require(account != address(0x0), "invalid address");
    require(shareholder_exists(account), "not exist");

    issue();

    total_alloc_share = total_alloc_share.safeSub(share_amounts[account]);
    total_alloc_share = total_alloc_share.safeAdd(amount);
    share_amounts[account] = amount;
  }

  function config_shareholder(uint64 id, address account, uint amount)
    external
    only_signer
    is_majority_sig(id, "config_shareholder")
  {
    _internal_config_shareholder(account, amount);
  }

  function admin_config_shareholder(address account, uint amount)
    public
    only_admin{
      _internal_config_shareholder(account, amount);
  }

  function _internal_remove_shareholder(address account) private {
    require(account != address(0), "invalid address");
    require(shareholder_exists(account), "not exist");
    issue();
    total_alloc_share = total_alloc_share.safeSub(share_amounts[account]);
    share_amounts[account] = 0;
    shareholders.remove(account);
  }

  function remove_shareholder(uint64 id, address account)
    public
    only_signer
    is_majority_sig(id, "remove_shareholder"){
    _internal_remove_shareholder(account);
  }

  function admin_remove_shareholder(address account)
    public
    only_admin{
    _internal_remove_shareholder(account);
  }

  function get_total_allocation() public view returns(uint total){
    return total_alloc_share;
  }

  function get_share(address account) public view returns(uint){
    return share_amounts[account];
  }

  function status() public view returns(uint _last_block_num,
                                       uint _period_block_num,
                                       uint _period_share){
    return (last_block_num, period_block_num, period_share);
  }

  function set_issue_period_param(uint64 id, uint block_num, uint share)
    public
    only_signer
    is_majority_sig(id, "set_issue_period_param")
  {
    require(block_num > 0);
    require(share > 0);
    issue();
    period_block_num = block_num;
    period_share = share;
  }

  function get_shareholders_count() public view returns(uint){
    return shareholders.length;
  }

  function get_shareholder_amount_with_index(uint index) public view returns(address account, uint amount) {
    require(index>=0 && index<shareholders.length);
    return (shareholders[index], share_amounts[shareholders[index]]);
  }
}

contract PeriodMintFactory{
  event NewPeriodMintFactory(address addr);
  function createPeriodMint(address _token, uint _start_block, uint _period, uint _period_share,
                            address _multisig) public returns(address){
    PeriodMint pm = new PeriodMint(_token, _start_block, _period, _period_share, _multisig);
    emit NewPeriodMintFactory(address(pm));
    return address(pm);
  }
}