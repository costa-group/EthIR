pragma solidity ^0.5.7;
contract ReentrancyGuard {
bool private _notEntered;
constructor () internal {
_notEntered = true;
}
modifier nonReentrant() {
require(_notEntered, "");
_notEntered = false;
_;
_notEntered = true;
}
}
pragma solidity ^0.5.0;
contract Context {
constructor () internal { }
function _msgSender() internal view returns (address payable) {
return msg.sender;
}
function _msgData() internal view returns (bytes memory) {
this; 
return msg.data;
}
}
pragma solidity ^0.5.0;
contract Ownable is Context {
address private _owner;
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
constructor () internal {
address msgSender = _msgSender();
_owner = msgSender;
emit OwnershipTransferred(address(0), msgSender);
}
function owner() public view returns (address) {
return _owner;
}
modifier onlyOwner() {
require(isOwner(), "");
_;
}
function isOwner() public view returns (bool) {
return _msgSender() == _owner;
}
function renounceOwnership() public onlyOwner {
emit OwnershipTransferred(_owner, address(0));
_owner = address(0);
}
function transferOwnership(address newOwner) public onlyOwner {
_transferOwnership(newOwner);
}
function _transferOwnership(address newOwner) internal {
require(newOwner != address(0), "");
emit OwnershipTransferred(_owner, newOwner);
_owner = newOwner;
}
}
pragma solidity ^0.5.6;
interface IERC20 {
function transfer(address to, uint256 value) external;
function approve(address spender, uint256 value) external;
function transferFrom(address from, address to, uint256 value) external;
function totalSupply() external view returns (uint256);
function balanceOf(address who) external view returns (uint256);
function allowance(address owner, address spender)
external
view
returns (uint256);
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(
address indexed owner,
address indexed spender,
uint256 value
);
}
pragma solidity ^0.5.7;
interface ISwaps {
function createOrder(
bytes32 _id,
address _baseAddress,
address _quoteAddress,
uint _baseLimit,
uint _quoteLimit,
uint _expirationTimestamp,
address _baseOnlyInvestor,
uint _minBaseInvestment,
uint _minQuoteInvestment,
address _brokerAddress,
uint _brokerBasePercent,
uint _brokerQuotePercent
) external;
function deposit(bytes32 _id, address _token, uint _amount)
external
payable;
function cancel(bytes32 _id) external;
function refund(bytes32 _id, address _token) external;
}
pragma solidity ^0.5.7;
contract Vault is Ownable {
address public swaps;
modifier onlySwaps() {
require(msg.sender == swaps);
_;
}
function() external payable {}
function tokenFallback(address, uint, bytes calldata) external {}
function setSwaps(address _swaps) public onlyOwner {
swaps = _swaps;
}
function withdraw(address _token, address _receiver, uint _amount)
public
onlySwaps
{
if (_token == address(0)) {
address(uint160(_receiver)).transfer(_amount);
} else {
IERC20(_token).transfer(_receiver, _amount);
}
}
}
pragma solidity ^0.5.0;
library SafeMath {
function add(uint256 a, uint256 b) internal pure returns (uint256) {
uint256 c = a + b;
require(c >= a, "");
return c;
}
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
return sub(a, b, "");
}
function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
require(b <= a, errorMessage);
uint256 c = a - b;
return c;
}
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
if (a == 0) {
return 0;
}
uint256 c = a * b;
require(c / a == b, "");
return c;
}
function div(uint256 a, uint256 b) internal pure returns (uint256) {
return div(a, b, "");
}
function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
require(b > 0, errorMessage);
uint256 c = a / b;
return c;
}
function mod(uint256 a, uint256 b) internal pure returns (uint256) {
return mod(a, b, "");
}
function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
require(b != 0, errorMessage);
return a % b;
}
}
contract Swaps is Ownable, ISwaps, ReentrancyGuard {
using SafeMath for uint;
uint public MAX_INVESTORS = 10;
Vault public vault;
mapping(bytes32 => address) public baseOnlyInvestor;
mapping(bytes32 => address) public owners;
mapping(bytes32 => address) public baseAddresses;
mapping(bytes32 => address) public quoteAddresses;
mapping(bytes32 => uint) public expirationTimestamps;
mapping(bytes32 => bool) public isSwapped;
mapping(bytes32 => bool) public isCancelled;
mapping(bytes32 => mapping(address => uint)) public limits;
mapping(bytes32 => mapping(address => uint)) public raised;
mapping(bytes32 => mapping(address => address[])) public investors;
mapping(bytes32 => mapping(address => mapping(address => uint))) public investments;
mapping(bytes32 => mapping(address => uint)) public minInvestments;
mapping(bytes32 => address[]) public brokers;
mapping(bytes32 => mapping(address => mapping(address => uint))) public brokerPercents;
uint public myWishBasePercent;
uint public myWishQuotePercent;
address public myWishAddress;
modifier onlyInvestor(bytes32 _id, address _token) {
require(
_isInvestor(_id, _token, msg.sender),
""
);
_;
}
modifier onlyWhenVaultDefined() {
require(address(vault) != address(0), "");
_;
}
modifier onlyOrderOwner(bytes32 _id) {
require(msg.sender == owners[_id], "");
_;
}
modifier onlyWhenOrderExists(bytes32 _id) {
require(owners[_id] != address(0), "");
_;
}
event OrderCreated(
bytes32 id,
address owner,
address baseAddress,
address quoteAddress,
uint baseLimit,
uint quoteLimit,
uint expirationTimestamp,
address baseOnlyInvestor,
uint minBaseInvestment,
uint minQuoteInvestment,
address broker,
uint brokerBasePercent,
uint brokerQuotePercent
);
event OrderCancelled(bytes32 id);
event Deposit(
bytes32 id,
address token,
address user,
uint amount,
uint balance
);
event Refund(bytes32 id, address token, address user, uint amount);
event OrderSwapped(bytes32 id, address byUser);
event SwapSend(bytes32 id, address token, address user, uint amount);
event BrokerSend(bytes32 id, address token, address broker, uint amount);
event MyWishAddressChange(
address oldMyWishAddress,
address newMyWishAddress
);
event MyWishPercentsChange(
uint oldBasePercent,
uint oldQuotePercent,
uint newBasePercent,
uint newQuotePercent
);
function tokenFallback(address, uint, bytes calldata) external {}
function createOrder(
bytes32 _id,
address _baseAddress,
address _quoteAddress,
uint _baseLimit,
uint _quoteLimit,
uint _expirationTimestamp,
address _baseOnlyInvestor,
uint _minBaseInvestment,
uint _minQuoteInvestment,
address _brokerAddress,
uint _brokerBasePercent,
uint _brokerQuotePercent
) external nonReentrant onlyWhenVaultDefined {
require(owners[_id] == address(0), "");
require(
_baseAddress != _quoteAddress,
""
);
require(_baseLimit > 0, "");
require(_quoteLimit > 0, "");
require(
_expirationTimestamp > now,
""
);
require(
_brokerBasePercent.add(myWishBasePercent) <= 10000,
""
);
require(
_brokerQuotePercent.add(myWishQuotePercent) <= 10000,
""
);
owners[_id] = msg.sender;
baseAddresses[_id] = _baseAddress;
quoteAddresses[_id] = _quoteAddress;
expirationTimestamps[_id] = _expirationTimestamp;
limits[_id][_baseAddress] = _baseLimit;
limits[_id][_quoteAddress] = _quoteLimit;
baseOnlyInvestor[_id] = _baseOnlyInvestor;
minInvestments[_id][_baseAddress] = _minBaseInvestment;
minInvestments[_id][_quoteAddress] = _minQuoteInvestment;
if (_brokerAddress != address(0)) {
brokers[_id].push(_brokerAddress);
brokerPercents[_id][_baseAddress][_brokerAddress] = _brokerBasePercent;
brokerPercents[_id][_quoteAddress][_brokerAddress] = _brokerQuotePercent;
}
if (myWishAddress != address(0)) {
brokers[_id].push(myWishAddress);
brokerPercents[_id][_baseAddress][myWishAddress] = myWishBasePercent;
brokerPercents[_id][_quoteAddress][myWishAddress] = myWishQuotePercent;
}
emit OrderCreated(
_id,
msg.sender,
_baseAddress,
_quoteAddress,
_baseLimit,
_quoteLimit,
_expirationTimestamp,
_baseOnlyInvestor,
_minBaseInvestment,
_minQuoteInvestment,
_brokerAddress,
_brokerBasePercent,
_brokerQuotePercent
);
}
function deposit(bytes32 _id, address _token, uint _amount)
external
payable
nonReentrant
onlyWhenVaultDefined
onlyWhenOrderExists(_id)
{
if (_token == address(0)) {
require(
msg.value == _amount,
""
);
address(vault).transfer(msg.value);
} else {
require(msg.value == 0, "");
uint allowance = IERC20(_token).allowance(
msg.sender,
address(this)
);
require(
_amount <= allowance,
""
);
IERC20(_token).transferFrom(msg.sender, address(vault), _amount);
}
_deposit(_id, _token, msg.sender, _amount);
}
function cancel(bytes32 _id)
external
nonReentrant
onlyOrderOwner(_id)
onlyWhenVaultDefined
onlyWhenOrderExists(_id)
{
require(!isCancelled[_id], "");
require(!isSwapped[_id], "");
address[2] memory tokens = [baseAddresses[_id], quoteAddresses[_id]];
for (uint t = 0; t < tokens.length; t++) {
address token = tokens[t];
for (uint u = 0; u < investors[_id][token].length; u++) {
address user = investors[_id][token][u];
uint userInvestment = investments[_id][token][user];
vault.withdraw(token, user, userInvestment);
}
}
isCancelled[_id] = true;
emit OrderCancelled(_id);
}
function refund(bytes32 _id, address _token)
external
nonReentrant
onlyInvestor(_id, _token)
onlyWhenVaultDefined
onlyWhenOrderExists(_id)
{
require(!isCancelled[_id], "");
require(!isSwapped[_id], "");
address user = msg.sender;
uint investment = investments[_id][_token][user];
if (investment > 0) {
delete investments[_id][_token][user];
}
_removeInvestor(investors[_id][_token], user);
if (investment > 0) {
raised[_id][_token] = raised[_id][_token].sub(investment);
vault.withdraw(_token, user, investment);
}
emit Refund(_id, _token, user, investment);
}
function setVault(Vault _vault) external onlyOwner {
vault = _vault;
}
function setMyWishPercents(uint _basePercent, uint _quotePercent)
external
onlyOwner
{
require(_basePercent <= 10000, "");
require(
_quotePercent <= 10000,
""
);
emit MyWishPercentsChange(
myWishBasePercent,
myWishQuotePercent,
_basePercent,
_quotePercent
);
myWishBasePercent = _basePercent;
myWishQuotePercent = _quotePercent;
}
function setMyWishAddress(address _myWishAddress) external onlyOwner {
emit MyWishAddressChange(myWishAddress, _myWishAddress);
myWishAddress = _myWishAddress;
}
function createKey(address _owner) public view returns (bytes32 result) {
uint creationTime = now;
result = 0x0000000000000000000000000000000000000000000000000000000000000000;
assembly {
result := or(result, mul(_owner, 0x1000000000000000000000000))
result := or(result, and(creationTime, 0xffffffffffffffffffffffff))
}
}
function allBrokersBasePercent(bytes32 _id) public view returns (uint) {
return _allBrokersPercent(baseAddresses[_id], _id);
}
function allBrokersQuotePercent(bytes32 _id) public view returns (uint) {
return _allBrokersPercent(quoteAddresses[_id], _id);
}
function baseLimit(bytes32 _id) public view returns (uint) {
return limits[_id][baseAddresses[_id]];
}
function quoteLimit(bytes32 _id) public view returns (uint) {
return limits[_id][quoteAddresses[_id]];
}
function baseRaised(bytes32 _id) public view returns (uint) {
return raised[_id][baseAddresses[_id]];
}
function quoteRaised(bytes32 _id) public view returns (uint) {
return raised[_id][quoteAddresses[_id]];
}
function isBaseFilled(bytes32 _id) public view returns (bool) {
return raised[_id][baseAddresses[_id]] == limits[_id][baseAddresses[_id]];
}
function isQuoteFilled(bytes32 _id) public view returns (bool) {
return raised[_id][quoteAddresses[_id]] == limits[_id][quoteAddresses[_id]];
}
function baseInvestors(bytes32 _id) public view returns (address[] memory) {
return investors[_id][baseAddresses[_id]];
}
function quoteInvestors(bytes32 _id)
public
view
returns (address[] memory)
{
return investors[_id][quoteAddresses[_id]];
}
function baseUserInvestment(bytes32 _id, address _user)
public
view
returns (uint)
{
return investments[_id][baseAddresses[_id]][_user];
}
function quoteUserInvestment(bytes32 _id, address _user)
public
view
returns (uint)
{
return investments[_id][quoteAddresses[_id]][_user];
}
function orderBrokers(bytes32 _id) public view returns (address[] memory) {
return brokers[_id];
}
function _allBrokersPercent(address _side, bytes32 _id)
internal
view
returns (uint)
{
uint percents;
for (uint i = 0; i < brokers[_id].length; i++) {
address broker = brokers[_id][i];
uint percent = brokerPercents[_id][_side][broker];
percents = percents.add(percent);
}
return percents;
}
function _swap(bytes32 _id) internal {
require(!isSwapped[_id], "");
require(!isCancelled[_id], "");
require(isBaseFilled(_id), "");
require(isQuoteFilled(_id), "");
require(now <= expirationTimestamps[_id], "");
_distribute(_id, baseAddresses[_id], quoteAddresses[_id]);
_distribute(_id, quoteAddresses[_id], baseAddresses[_id]);
isSwapped[_id] = true;
emit OrderSwapped(_id, msg.sender);
}
function _distribute(bytes32 _id, address _aSide, address _bSide) internal {
uint brokersPercent;
for (uint i = 0; i < brokers[_id].length; i++) {
address broker = brokers[_id][i];
uint percent = brokerPercents[_id][_bSide][broker];
brokersPercent = brokersPercent.add(percent);
}
uint toPayBrokers = raised[_id][_bSide].mul(brokersPercent).div(10000);
uint toPayInvestors = raised[_id][_bSide].sub(toPayBrokers);
uint remainder = toPayInvestors;
for (uint i = 0; i < investors[_id][_aSide].length; i++) {
address user = investors[_id][_aSide][i];
uint toPay;
// last
if (i + 1 == investors[_id][_aSide].length) {
toPay = remainder;
} else {
uint aSideRaised = raised[_id][_aSide];
uint userInvestment = investments[_id][_aSide][user];
toPay = userInvestment.mul(toPayInvestors).div(aSideRaised);
remainder = remainder.sub(toPay);
}
vault.withdraw(_bSide, user, toPay);
emit SwapSend(_id, _bSide, user, toPay);
}
remainder = toPayBrokers;
for (uint i = 0; i < brokers[_id].length; i++) {
address broker = brokers[_id][i];
uint toPay;
if (i + 1 == brokers[_id].length) {
toPay = remainder;
} else {
uint percent = brokerPercents[_id][_bSide][broker];
toPay = toPayBrokers.mul(percent).div(brokersPercent);
remainder = remainder.sub(toPay);
}
vault.withdraw(_bSide, broker, toPay);
emit BrokerSend(_id, _bSide, broker, toPay);
}
}
function _removeInvestor(address[] storage _array, address _investor)
internal
{
uint idx = _array.length - 1;
for (uint i = 0; i < _array.length - 1; i++) {
if (_array[i] == _investor) {
idx = i;
break;
}
}
_array[idx] = _array[_array.length - 1];
delete _array[_array.length - 1];
_array.length--;
}
function _deposit(bytes32 _id, address _token, address _from, uint _amount)
internal
{
uint amount = _amount;
require(
baseAddresses[_id] == _token || quoteAddresses[_id] == _token,
""
);
require(
raised[_id][_token] < limits[_id][_token],
""
);
require(now <= expirationTimestamps[_id], "");
if (baseAddresses[_id] == _token && baseOnlyInvestor[_id] != address(
0
)) {
require(
msg.sender == baseOnlyInvestor[_id],
""
);
}
if (limits[_id][_token].sub(
raised[_id][_token]
) > minInvestments[_id][_token]) {
require(
_amount >= minInvestments[_id][_token],
""
);
}
if (!_isInvestor(_id, _token, _from)) {
require(
investors[_id][_token].length < MAX_INVESTORS,
""
);
investors[_id][_token].push(_from);
}
uint raisedWithOverflow = raised[_id][_token].add(amount);
if (raisedWithOverflow > limits[_id][_token]) {
uint overflow = raisedWithOverflow.sub(limits[_id][_token]);
vault.withdraw(_token, _from, overflow);
amount = amount.sub(overflow);
}
investments[_id][_token][_from] = investments[_id][_token][_from].add(
amount
);
raised[_id][_token] = raised[_id][_token].add(amount);
emit Deposit(
_id,
_token,
_from,
amount,
investments[_id][_token][_from]
);
if (isBaseFilled(_id) && isQuoteFilled(_id)) {
_swap(_id);
}
}
function _isInvestor(bytes32 _id, address _token, address _who)
internal
view
returns (bool)
{
return investments[_id][_token][_who] > 0;
}
}