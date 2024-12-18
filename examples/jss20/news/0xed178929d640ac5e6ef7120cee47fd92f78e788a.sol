// Copyright (C) 2019, 2020 dipeshsukhani, nodarjanashia, suhailg, apoorvlathey, sebaudet, sumit



// This program is free software: you can redistribute it and/or modify

// it under the terms of the GNU Affero General Public License as published by

// the Free Software Foundation, either version 2 of the License, or

// (at your option) any later version.

//

// This program is distributed in the hope that it will be useful,

// but WITHOUT ANY WARRANTY; without even the implied warranty of

// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the

// GNU Affero General Public License for more details.

//

// Visit <https://www.gnu.org/licenses/>for a copy of the GNU Affero General Public License



///@author DeFiZap

///@notice this contract implements one click swapping among Uniswap Pools.



pragma solidity ^0.5.0;





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

    function transfer(address recipient, uint256 amount)

        external

        returns (bool);



    /**

     * @dev Returns the remaining number of tokens that `spender` will be

     * allowed to spend on behalf of `owner` through {transferFrom}. This is

     * zero by default.

     *

     * This value changes when {approve} or {transferFrom} are called.

     */

    function allowance(address owner, address spender)

        external

        view

        returns (uint256);



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

    function transferFrom(address sender, address recipient, uint256 amount)

        external

        returns (bool);



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

    event Approval(

        address indexed owner,

        address indexed spender,

        uint256 value

    );

}

// File: browser/Context.sol



pragma solidity ^0.5.0;





/*

 * @dev Provides information about the current execution context, including the

 * sender of the transaction and its data. While these are generally available

 * via msg.sender and msg.data, they should not be accessed in such a direct

 * manner, since when dealing with GSN meta-transactions the account sending and

 * paying for execution may not be the actual sender (as far as an application

 * is concerned).

 *

 * This contract is only required for intermediate, library-like contracts.

 */

contract Context {

    // Empty internal constructor, to prevent people from mistakenly deploying

    // an instance of this contract, which should be used via inheritance.

    constructor() internal {}



    // solhint-disable-previous-line no-empty-blocks



    function _msgSender() internal view returns (address payable) {

        return msg.sender;

    }



    function _msgData() internal view returns (bytes memory) {

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691

        return msg.data;

    }

}

// File: browser/OpenZepplinOwnable.sol



pragma solidity ^0.5.0;





/**

 * @dev Contract module which provides a basic access control mechanism, where

 * there is an account (an owner) that can be granted exclusive access to

 * specific functions.

 *

 * This module is used through inheritance. It will make available the modifier

 * `onlyOwner`, which can be applied to your functions to restrict their use to

 * the owner.

 */

contract Ownable is Context {

    address payable public _owner;



    event OwnershipTransferred(

        address indexed previousOwner,

        address indexed newOwner

    );



    /**

     * @dev Initializes the contract setting the deployer as the initial owner.

     */

    constructor() internal {

        address payable msgSender = _msgSender();

        _owner = msgSender;

        emit OwnershipTransferred(address(0), msgSender);

    }



    /**

     * @dev Returns the address of the current owner.

     */

    function owner() public view returns (address) {

        return _owner;

    }



    /**

     * @dev Throws if called by any account other than the owner.

     */

    modifier onlyOwner() {

        require(isOwner(), "Ownable: caller is not the owner");

        _;

    }



    /**

     * @dev Returns true if the caller is the current owner.

     */

    function isOwner() public view returns (bool) {

        return _msgSender() == _owner;

    }



    /**

     * @dev Leaves the contract without owner. It will not be possible to call

     * `onlyOwner` functions anymore. Can only be called by the current owner.

     *

     * NOTE: Renouncing ownership will leave the contract without an owner,

     * thereby removing any functionality that is only available to the owner.

     */

    function renounceOwnership() public onlyOwner {

        emit OwnershipTransferred(_owner, address(0));

        _owner = address(0);

    }



    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * Can only be called by the current owner.

     */

    function transferOwnership(address payable newOwner) public onlyOwner {

        _transferOwnership(newOwner);

    }



    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     */

    function _transferOwnership(address payable newOwner) internal {

        require(

            newOwner != address(0),

            "Ownable: new owner is the zero address"

        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;

    }

}

// File: browser/OpenZepplinSafeMath.sol



pragma solidity ^0.5.0;





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

    function sub(uint256 a, uint256 b, string memory errorMessage)

        internal

        pure

        returns (uint256)

    {

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

    function div(uint256 a, uint256 b, string memory errorMessage)

        internal

        pure

        returns (uint256)

    {

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

    function mod(uint256 a, uint256 b, string memory errorMessage)

        internal

        pure

        returns (uint256)

    {

        require(b != 0, errorMessage);

        return a % b;

    }

}

// File: browser/OpenZepplinReentrancyGuard.sol



pragma solidity ^0.5.0;





/**

 * @dev Contract module that helps prevent reentrant calls to a function.

 *

 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier

 * available, which can be applied to functions to make sure there are no nested

 * (reentrant) calls to them.

 *

 * Note that because there is a single `nonReentrant` guard, functions marked as

 * `nonReentrant` may not call one another. This can be worked around by making

 * those functions `private`, and then adding `external` `nonReentrant` entry

 * points to them.

 *

 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas

 * metering changes introduced in the Istanbul hardfork.

 */

contract ReentrancyGuard {

    bool private _notEntered;



    constructor() internal {

        // Storing an initial non-zero value makes deployment a bit more

        // expensive, but in exchange the refund on every call to nonReentrant

        // will be lower in amount. Since refunds are capped to a percetange of

        // the total transaction's gas, it is best to keep them low in cases

        // like this one, to increase the likelihood of the full refund coming

        // into effect.

        _notEntered = true;

    }



    /**

     * @dev Prevents a contract from calling itself, directly or indirectly.

     * Calling a `nonReentrant` function from another `nonReentrant`

     * function is not supported. It is possible to prevent this from happening

     * by making the `nonReentrant` function external, and make it call a

     * `private` function that does the actual work.

     */

    modifier nonReentrant() {

        // On the first call to nonReentrant, _notEntered will be true

        require(_notEntered, "ReentrancyGuard: reentrant call");



        // Any calls to nonReentrant after this point will fail

        _notEntered = false;



        _;



        // By storing the original value once again, a refund is triggered (see

        // https://eips.ethereum.org/EIPS/eip-2200)

        _notEntered = true;

    }

}





// interface

interface IuniswapFactory {

    function getExchange(address token)

        external

        view

        returns (address exchange);

}





interface IuniswapExchange {

    // for removing liquidity (returns ETH removed, ERC20 Removed)

    function removeLiquidity(

        uint256 amount,

        uint256 min_eth,

        uint256 min_tokens,

        uint256 deadline

    ) external returns (uint256, uint256);



    // converting ERC20 to ERC20 and transfer

    function tokenToTokenSwapInput(

        uint256 tokens_sold,

        uint256 min_tokens_bought,

        uint256 min_eth_bought,

        uint256 deadline,

        address token_addr

    ) external returns (uint256 tokens_bought);



    // add liquidity to a pool (returns LP tokens rec)

    function addLiquidity(

        uint256 min_liquidity,

        uint256 max_tokens,

        uint256 deadline

    ) external payable returns (uint256);



    function getEthToTokenInputPrice(uint256 eth_sold)

        external

        view

        returns (uint256 tokens_bought);



    function getTokenToEthInputPrice(uint256 tokens_sold)

        external

        view

        returns (uint256 eth_bought);



    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline)

        external

        payable

        returns (uint256 tokens_bought);



    function balanceOf(address _owner) external view returns (uint256);



    function transfer(address _to, uint256 _value) external returns (bool);



    function transferFrom(address from, address to, uint256 tokens)

        external

        returns (bool success);

}





interface ICurveExchange {

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)

        external;

}





interface yERC20 {

    function deposit(uint256 _amount) external;

}



pragma solidity ^0.5.13;




contract ETH_ERC20_Curve_General_Zap_V1 is ReentrancyGuard, Ownable {

    using SafeMath for uint256;

    bool private stopped = false;

    uint16 public goodwill;

    address public dzgoodwillAddress;

    address public serviceAddress;

    uint16 public service = 50;



    IuniswapFactory public UniSwapFactoryAddress = IuniswapFactory(

        0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95

    );

    address public DaiTokenAddress = address(

        0x6B175474E89094C44Da98b954EedeAC495271d0F

    );

    address public UsdcTokenAddress = address(

        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48

    );

    address public sUSDCurveExchangeAddress = address(

        0xA5407eAE9Ba41422680e2e00537571bcC53efBfD

    );

    address public sUSDCurvePoolTokenAddress = address(

        0xC25a3A3b969415c80451098fa907EC722572917F

    );

    address public yCurveExchangeAddress = address(

        0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3

    );

    address public yCurvePoolTokenAddress = address(

        0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8

    );

    address public bUSDCurveExchangeAddress = address(

        0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB

    );

    address public bUSDCurvePoolTokenAddress = address(

        0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B

    );

    address public paxCurveExchangeAddress = address(

        0xA50cCc70b6a011CffDdf45057E39679379187287

    );

    address public paxCurvePoolTokenAddress = address(

        0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8

    );



    mapping(address => address) internal exchange2Token;



    constructor(uint16 _goodwill, address _dzgoodwillAddress, address _serviceAddress) public {

        goodwill = _goodwill;

        dzgoodwillAddress = _dzgoodwillAddress;

        serviceAddress = _serviceAddress;

        exchange2Token[sUSDCurveExchangeAddress] = sUSDCurvePoolTokenAddress;

        exchange2Token[yCurveExchangeAddress] = yCurvePoolTokenAddress;

        exchange2Token[bUSDCurveExchangeAddress] = bUSDCurvePoolTokenAddress;

        exchange2Token[paxCurveExchangeAddress] = paxCurvePoolTokenAddress;

        approveToken();

    }



    // circuit breaker modifiers

    modifier stopInEmergency {

        if (stopped) {

            revert("Temporarily Paused");

        } else {

            _;

        }

    }



    function approveToken() public {

        IERC20(DaiTokenAddress).approve(sUSDCurveExchangeAddress, uint256(-1));

        IERC20(DaiTokenAddress).approve(yCurveExchangeAddress, uint256(-1));

        IERC20(DaiTokenAddress).approve(bUSDCurveExchangeAddress, uint256(-1));

        IERC20(DaiTokenAddress).approve(paxCurveExchangeAddress, uint256(-1));



        IERC20(UsdcTokenAddress).approve(sUSDCurveExchangeAddress, uint256(-1));

        IERC20(UsdcTokenAddress).approve(yCurveExchangeAddress, uint256(-1));

        IERC20(UsdcTokenAddress).approve(bUSDCurveExchangeAddress, uint256(-1));

        IERC20(UsdcTokenAddress).approve(paxCurveExchangeAddress, uint256(-1));

    }





    function ZapIn(

        address _toWhomToIssue,

        address _IncomingTokenAddress,

        address _curvePoolExchangeAddress,

        uint256 _IncomingTokenQty

    ) public payable stopInEmergency returns (uint256 crvTokensBought) {

        require(

            _curvePoolExchangeAddress == sUSDCurveExchangeAddress ||

                _curvePoolExchangeAddress == yCurveExchangeAddress ||

                _curvePoolExchangeAddress == bUSDCurveExchangeAddress ||

                _curvePoolExchangeAddress == paxCurveExchangeAddress,

            "Invalid Curve Pool Address"

        );



        if (_IncomingTokenAddress == address(0)) {

            crvTokensBought = ZapInWithETH(

                _toWhomToIssue,

                _curvePoolExchangeAddress

            );

        } else {

            crvTokensBought = ZapInWithERC20(

                _toWhomToIssue,

                _IncomingTokenAddress,

                _curvePoolExchangeAddress,

                _IncomingTokenQty

            );

        }

    }



    function ZapInWithETH(

        address _toWhomToIssue,

        address _curvePoolExchangeAddress

    ) internal stopInEmergency returns (uint256 crvTokensBought) {

        require(msg.value > 0, "Err: No ETH sent");

        uint256 daiBought = _eth2Token(DaiTokenAddress, (msg.value).div(2));

        uint256 usdcBought = _eth2Token(UsdcTokenAddress, (msg.value).div(2));

        crvTokensBought = _enter2Curve(

            _toWhomToIssue,

            daiBought,

            usdcBought,

            _curvePoolExchangeAddress

        );

    }





    function ZapInWithERC20(

        address _toWhomToIssue,

        address _IncomingTokenAddress,

        address _curvePoolExchangeAddress,

        uint256 _IncomingTokenQty

    ) internal stopInEmergency returns (uint256 crvTokensBought) {

        require(_IncomingTokenQty > 0, "Err: No ERC20 sent");



        require(

            IERC20(_IncomingTokenAddress).transferFrom(

                msg.sender,

                address(this),

                _IncomingTokenQty

            ),

            "Error in transferring ERC20"

        );



        uint256 daiBought;

        uint256 usdcBought;



        if (_IncomingTokenAddress == DaiTokenAddress) {

            daiBought = _IncomingTokenQty;

            usdcBought = 0;

        } else if (_IncomingTokenAddress == UsdcTokenAddress) {

            daiBought = 0;

            usdcBought = _IncomingTokenQty;

        } else {

            daiBought = _token2Token(

                _IncomingTokenAddress,

                DaiTokenAddress,

                (_IncomingTokenQty).div(2)

            );

            usdcBought = _token2Token(

                _IncomingTokenAddress,

                UsdcTokenAddress,

                (_IncomingTokenQty).div(2)

            );

        }



        crvTokensBought = _enter2Curve(

            _toWhomToIssue,

            daiBought,

            usdcBought,

            _curvePoolExchangeAddress

        );

    }



    function _enter2Curve(

        address _toWhomToIssue,

        uint256 daiBought,

        uint256 usdcBought,

        address _curvePoolExchangeAddress

    ) internal returns (uint256 crvTokensBought) {

        // 0 = DAI, 1 = USDC, 2 = USDT, 3 = TUSD/sUSD

        ICurveExchange(_curvePoolExchangeAddress).add_liquidity(

            [daiBought, usdcBought, 0, 0],

            0

        );

        address poolTokenAddress = exchange2Token[_curvePoolExchangeAddress];

        crvTokensBought = IERC20(poolTokenAddress).balanceOf(address(this));

        require(crvTokensBought > 0, "Error swapping to CRV");

        

        uint256 servicePortion = SafeMath.div(

            SafeMath.mul(crvTokensBought, service),

            10000

        );



        uint256 goodwillPortion = SafeMath.div(

            SafeMath.mul(crvTokensBought, goodwill),

            10000

        );

        

        require(

            IERC20(poolTokenAddress).transfer(

                dzgoodwillAddress,

                goodwillPortion

            ),

            "Error transferring goodwill"

        );

        

        require(

            IERC20(poolTokenAddress).transfer(

                serviceAddress,

                servicePortion

            ),

            "Error transferring service"

        );

        

        require(

            IERC20(poolTokenAddress).transfer(

                _toWhomToIssue,

                IERC20(poolTokenAddress).balanceOf(address(this))

            ),

            "Error transferring CRV"

        );

        

    }



    function _eth2Token(address _ToTokenContractAddress, uint256 ethReceived)

        internal

        returns (uint256 tokensBought)

    {

        IuniswapExchange ToUniSwapExchangeContractAddress = IuniswapExchange(

            UniSwapFactoryAddress.getExchange(_ToTokenContractAddress)

        );



        tokensBought = ToUniSwapExchangeContractAddress

            .ethToTokenSwapInput

            .value(ethReceived)(1, SafeMath.add(now, 300));

        require(tokensBought > 0, "Error in swapping ETH");

    }



    function _token2Token(

        address _FromTokenContractAddress,

        address _ToTokenContractAddress,

        uint256 tokens2Trade

    ) internal returns (uint256 tokensBought) {

        IuniswapExchange FromUniSwapExchangeContractAddress = IuniswapExchange(

            UniSwapFactoryAddress.getExchange(_FromTokenContractAddress)

        );



        IERC20(_FromTokenContractAddress).approve(

            address(FromUniSwapExchangeContractAddress),

            tokens2Trade

        );



        tokensBought = FromUniSwapExchangeContractAddress.tokenToTokenSwapInput(

            tokens2Trade,

            1,

            1,

            SafeMath.add(now, 300),

            _ToTokenContractAddress

        );



        require(tokensBought > 0, "Error in swapping ERC");

    }



    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {

        uint256 qty = _TokenAddress.balanceOf(address(this));

        _TokenAddress.transfer(_owner, qty);

    }



    function set_new_goodwill(uint16 _new_goodwill) public onlyOwner {

        require(

            _new_goodwill >= 0 && _new_goodwill < 10000,

            "GoodWill Value not allowed"

        );

        goodwill = _new_goodwill;

    }



    function set_new_dzgoodwillAddress(address _new_dzgoodwillAddress)

        public

        onlyOwner

    {

        dzgoodwillAddress = _new_dzgoodwillAddress;

    }

    



    // - to Pause the contract

    function toggleContractActive() public onlyOwner {

        stopped = !stopped;

    }



    // - to withdraw any ETH balance sitting in the contract

    function withdraw() public onlyOwner {

        _owner.transfer(address(this).balance);

    }



    // - to kill the contract

    function destruct() public onlyOwner {

        selfdestruct(_owner);

    }

}