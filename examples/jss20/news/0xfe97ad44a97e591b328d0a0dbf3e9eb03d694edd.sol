/*

 * Copyright 2019 Dolomite

 *

 * Licensed under the Apache License, Version 2.0 (the "License");

 * you may not use this file except in compliance with the License.

 * You may obtain a copy of the License at

 *

 * http://www.apache.org/licenses/LICENSE-2.0

 *

 * Unless required by applicable law or agreed to in writing, software

 * distributed under the License is distributed on an "AS IS" BASIS,

 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

 * See the License for the specific language governing permissions and

 * limitations under the License.

 */



pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;



interface IERC20 {

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);



  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);



  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);



  function transfer(address to, uint256 value) external;

  function transferFrom(address from, address to, uint256 value) external;

  function approve(address spender, uint256 value) external;

}



library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {

    if (a == 0) return 0;

    uint256 c = a * b;

    require(c / a == b);

    return c;

  }



  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b > 0);

    uint256 c = a / b;

    return c;

  }



  function sub(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b <= a);

    uint256 c = a - b;

    return c;

  }



  function add(uint256 a, uint256 b) internal pure returns (uint256) {

    uint256 c = a + b;

    require(c >= a);

    return c;

  }



  function mod(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b != 0);

    return a % b;

  }

}



library Types {



  struct RequestFee {

    address feeRecipient;

    address feeToken;

    uint feeAmount;

  }



  struct RequestSignature {

    uint8 v; 

    bytes32 r; 

    bytes32 s;

  }



  enum RequestType { Update, Transfer, Approve, Perform }



  struct Request {

    address owner;

    address target;

    RequestType requestType;

    bytes payload;

    uint nonce;

    RequestFee fee;

    RequestSignature signature;

  }



  struct TransferRequest {

    address token;

    address recipient;

    uint amount;

    bool unwrap;

  }

}



library LoopringTypes {

  struct BrokerApprovalRequest {

    BrokerOrder[] orders;

    address tokenS;

    address tokenB;

    address feeToken;

    uint totalFillAmountB;

    uint totalRequestedAmountS;

    uint totalRequestedFeeAmount;

  }



  struct BrokerOrder {

    address owner;

    bytes32 orderHash;

    uint fillAmountB;

    uint requestedAmountS;

    uint requestedFeeAmount;

    address tokenRecipient;

    bytes extraData;

  }



  struct BrokerInterceptorReport {

    address owner;

    address broker;

    bytes32 orderHash;

    address tokenB;

    address tokenS;

    address feeToken;

    uint fillAmountB;

    uint spentAmountS;

    uint spentFeeAmount;

    address tokenRecipient;

    bytes extraData;

  }

}



interface IBrokerDelegate {

  function brokerRequestAllowance(LoopringTypes.BrokerApprovalRequest calldata request) external returns (bool);

  function onOrderFillReport(LoopringTypes.BrokerInterceptorReport calldata fillReport) external;

  function brokerBalanceOf(address owner, address token) external view returns (uint);

}



interface IDolomiteMarginTradingBroker {

  function brokerMarginRequestApproval(address owner, address token, uint amount) external;

  function brokerMarginGetTrader(address owner, bytes calldata orderData) external view returns (address);

}



interface IVersionable {

  

  /*

   * Is called by IDepositContractRegistry when this version

   * is being upgraded to. Will call `versionEndUsage` on the

   * old contract before calling this one

   */

  function versionBeginUsage(

    address owner, 

    address payable depositAddress, 

    address oldVersion, 

    bytes calldata additionalData

  ) external;



  /*

   * Is called by IDepositContractRegistry when this version is

   * being upgraded from. IDepositContractRegistry will then call

   * `versionBeginUsage` on the new contract

   */

  function versionEndUsage(

    address owner,

    address payable depositAddress,

    address newVersion,

    bytes calldata additionalData

  ) external;

}



interface IDepositContract {  

  function perform(

    address addr, 

    string calldata signature, 

    bytes calldata encodedParams,

    uint value

  ) external returns (bytes memory);

}



interface IDepositContractRegistry {

  function depositAddressOf(address owner) external view returns (address payable);

  function operatorOf(address owner, address operator) external returns (bool);

}



library DepositContractHelper {



  function wrapAndTransferToken(IDepositContract self, address token, address recipient, uint amount, address wethAddress) internal {

    if (token == wethAddress) {

      uint etherBalance = address(self).balance;

      if (etherBalance > 0) wrapEth(self, token, etherBalance);

    }

    transferToken(self, token, recipient, amount);

  }



  function transferToken(IDepositContract self, address token, address recipient, uint amount) internal {

    self.perform(token, "transfer(address,uint256)", abi.encode(recipient, amount), 0);

  }



  function transferEth(IDepositContract self, address recipient, uint amount) internal {

    self.perform(recipient, "", abi.encode(), amount);

  }



  function approveToken(IDepositContract self, address token, address broker, uint amount) internal {

    self.perform(token, "approve(address,uint256)", abi.encode(broker, amount), 0);

  }



  function wrapEth(IDepositContract self, address wethToken, uint amount) internal {

    self.perform(wethToken, "deposit()", abi.encode(), amount);

  }



  function unwrapWeth(IDepositContract self, address wethToken, uint amount) internal {

    self.perform(wethToken, "withdraw(uint256)", abi.encode(amount), 0);

  }



  function setDydxOperator(IDepositContract self, address dydxContract, address operator) internal {

    bytes memory encodedParams = abi.encode(

      bytes32(0x0000000000000000000000000000000000000000000000000000000000000020),

      bytes32(0x0000000000000000000000000000000000000000000000000000000000000001),

      operator,

      bytes32(0x0000000000000000000000000000000000000000000000000000000000000001)

    );

    self.perform(dydxContract, "setOperators((address,bool)[])", encodedParams, 0);

  }

}



library RequestHelper {



  bytes constant personalPrefix = "\x19Ethereum Signed Message:\n32";



  function getSigner(Types.Request memory self) internal pure returns (address) {

    bytes32 messageHash = keccak256(abi.encode(

      self.owner,

      self.target,

      self.requestType,

      self.payload,

      self.nonce,

      abi.encode(self.fee.feeRecipient, self.fee.feeToken, self.fee.feeAmount)

    ));



    bytes32 prefixedHash = keccak256(abi.encodePacked(personalPrefix, messageHash));

    return ecrecover(prefixedHash, self.signature.v, self.signature.r, self.signature.s);

  }



  function decodeTransferRequest(Types.Request memory self) 

    internal 

    pure 

    returns (Types.TransferRequest memory transferRequest) 

  {

    require(self.requestType == Types.RequestType.Transfer, "INVALID_REQUEST_TYPE");



    (

      transferRequest.token,

      transferRequest.recipient,

      transferRequest.amount,

      transferRequest.unwrap

    ) = abi.decode(self.payload, (address, address, uint, bool));

  }

}



contract Requestable {

  using RequestHelper for Types.Request;



  mapping(address => uint) nonces;



  function validateRequest(Types.Request memory request) internal {

    require(request.target == address(this), "INVALID_TARGET");

    require(request.getSigner() == request.owner, "INVALID_SIGNATURE");

    require(nonces[request.owner] + 1 == request.nonce, "INVALID_NONCE");

    

    if (request.fee.feeAmount > 0) {

      require(balanceOf(request.owner, request.fee.feeToken) >= request.fee.feeAmount, "INSUFFICIENT_FEE_BALANCE");

    }



    nonces[request.owner] += 1;

  }



  function completeRequest(Types.Request memory request) internal {

    if (request.fee.feeAmount > 0) {

      _payRequestFee(request.owner, request.fee.feeToken, request.fee.feeRecipient, request.fee.feeAmount);

    }

  }



  function nonceOf(address owner) public view returns (uint) {

    return nonces[owner];

  }



  // Abtract functions

  function balanceOf(address owner, address token) public view returns (uint);

  function _payRequestFee(address owner, address feeToken, address feeRecipient, uint feeAmount) internal;

}



/**

 * @title DolomiteDirectV1

 * @author Zack Rubenstein

 *

 * Interfaces with the IDepositContractRegistry and individual 

 * IDepositContracts to enable smart-wallet functionality as well

 * as spot and margin trading on Dolomite (through Loopring & Dy/dx)

 */

contract DolomiteDirectV1 is Requestable, IVersionable, IBrokerDelegate, IDolomiteMarginTradingBroker {

  using DepositContractHelper for IDepositContract;

  using SafeMath for uint;



  IDepositContractRegistry public registry;

  address public loopringProtocolAddress;

  address public dolomiteMarginProtocolAddress;

  address public dydxProtocolAddress;

  address public wethTokenAddress;



  constructor(

    address _depositContractRegistry,

    address _loopringRingSubmitter,

    address _dolomiteMarginProtocol,

    address _dydxProtocolAddress,

    address _wethTokenAddress

  ) public {

    registry = IDepositContractRegistry(_depositContractRegistry);

    loopringProtocolAddress = _loopringRingSubmitter;

    dolomiteMarginProtocolAddress = _dolomiteMarginProtocol;

    dydxProtocolAddress = _dydxProtocolAddress;

    wethTokenAddress = _wethTokenAddress;

  }



  /*

   * Returns the available balance for an owner that this contract manages.

   * If the token is WETH, it returns the sum of the ETH and WETH balance,

   * as ETH is automatically wrapped upon transfers (unless the unwrap option is

   * set to true in the transfer request)

   */

  function balanceOf(address owner, address token) public view returns (uint) {

    address depositAddress = registry.depositAddressOf(owner);

    uint tokenBalance = IERC20(token).balanceOf(depositAddress);

    if (token == wethTokenAddress) tokenBalance = tokenBalance.add(depositAddress.balance);

    return tokenBalance;

  }



  /*

   * Send up a signed transfer request and the given amount tokens

   * is transfered to the specified recipient.

   */

  function transfer(Types.Request memory request) public {

    validateRequest(request);

    

    Types.TransferRequest memory transferRequest = request.decodeTransferRequest();

    address payable depositAddress = registry.depositAddressOf(request.owner);



    _transfer(

      transferRequest.token, 

      depositAddress, 

      transferRequest.recipient, 

      transferRequest.amount, 

      transferRequest.unwrap

    );



    completeRequest(request);

  }



  // =============================



  function _transfer(address token, address payable depositAddress, address recipient, uint amount, bool unwrap) internal {

    IDepositContract depositContract = IDepositContract(depositAddress);

    

    if (token == wethTokenAddress && unwrap) {

      if (depositAddress.balance < amount) {

        depositContract.unwrapWeth(wethTokenAddress, amount.sub(depositAddress.balance));

      }



      depositContract.transferEth(recipient, amount);

      return;

    }



    depositContract.wrapAndTransferToken(token, recipient, amount, wethTokenAddress);

  }



  // -----------------------------

  // Loopring Broker Delegate



  function brokerRequestAllowance(LoopringTypes.BrokerApprovalRequest memory request) public returns (bool) {

    require(msg.sender == loopringProtocolAddress);



    LoopringTypes.BrokerOrder[] memory mergedOrders = new LoopringTypes.BrokerOrder[](request.orders.length);

    uint numMergedOrders = 1;



    mergedOrders[0] = request.orders[0];

    

    if (request.orders.length > 1) {

      for (uint i = 1; i < request.orders.length; i++) {

        bool isDuplicate = false;



        for (uint b = 0; b < numMergedOrders; b++) {

          if (request.orders[i].owner == mergedOrders[b].owner) {

            mergedOrders[b].requestedAmountS += request.orders[i].requestedAmountS;

            mergedOrders[b].requestedFeeAmount += request.orders[i].requestedFeeAmount;

            isDuplicate = true;

            break;

          }

        }



        if (!isDuplicate) {

          mergedOrders[numMergedOrders] = request.orders[i];

          numMergedOrders += 1;

        }

      }

    }



    for (uint j = 0; j < numMergedOrders; j++) {

      LoopringTypes.BrokerOrder memory order = mergedOrders[j];

      address payable depositAddress = registry.depositAddressOf(order.owner);

      

      _transfer(request.tokenS, depositAddress, address(this), order.requestedAmountS, false);

      if (order.requestedFeeAmount > 0) _transfer(request.feeToken, depositAddress, address(this), order.requestedFeeAmount, false);

    }



    return false; // Does not use onOrderFillReport

  }



  function onOrderFillReport(LoopringTypes.BrokerInterceptorReport memory fillReport) public {

    // Do nothing

  }



  function brokerBalanceOf(address owner, address tokenAddress) public view returns (uint) {

    return balanceOf(owner, tokenAddress);

  }



  // ----------------------------

  // Dolomite Margin Trading Broker



  function brokerMarginRequestApproval(address owner, address token, uint amount) public {

    require(msg.sender == dolomiteMarginProtocolAddress);



    address payable depositAddress = registry.depositAddressOf(owner);

    _transfer(token, depositAddress, address(this), amount, false);

  }



  function brokerMarginGetTrader(address owner, bytes memory orderData) public view returns (address) {

    return registry.depositAddressOf(owner);

  }



  // -----------------------------

  // Requestable



  function _payRequestFee(address owner, address feeToken, address feeRecipient, uint feeAmount) internal {

    _transfer(feeToken, registry.depositAddressOf(owner), feeRecipient, feeAmount, false);

  }



  // -----------------------------

  // Versionable



  function versionBeginUsage(

    address owner, 

    address payable depositAddress, 

    address oldVersion, 

    bytes calldata additionalData

  ) external { 

    // Approve the DolomiteMarginProtocol as an operator for the deposit contract's dydx account

    IDepositContract(depositAddress).setDydxOperator(dydxProtocolAddress, dolomiteMarginProtocolAddress);

  }



  function versionEndUsage(

    address owner,

    address payable depositAddress,

    address newVersion,

    bytes calldata additionalData

  ) external { /* do nothing */ }





  // =============================

  // Administrative



  /*

   * Tokens are held in individual deposit contracts, the only time a trader's

   * funds are held by this contract is when Loopring or Dy/dx requests a trader's

   * tokens, and immediatly upon this contract moving funds into itself, Loopring

   * or Dy/dx will move the funds out and into themselves. Thus, we can open this 

   * function up for anyone to call to set or reset the approval for Loopring and

   * Dy/dx for a given token. The reason these approvals are set globally and not

   * on an as-needed (per fill) basis is to reduce gas costs.

   */

  function enableTrading(address token) external {

    IERC20(token).approve(loopringProtocolAddress, 10**70);

    IERC20(token).approve(dolomiteMarginProtocolAddress, 10**70);

  }

}