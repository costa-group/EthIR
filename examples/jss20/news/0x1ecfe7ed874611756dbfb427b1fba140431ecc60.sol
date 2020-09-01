// File: browser/OpenZepplinIERC20.sol

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    constructor () internal { }
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    constructor () internal {
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
// File: browser/Unipool_Bridge_Zap_v1_2.sol

// Copyright (C) 2019, 2020 dipeshsukhani, nodar, suhailg

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

// File: localhost/defizap/node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

///@author DeFiZap
///@notice this contract implements one click swapping among Uniswap Pools

// interface
interface IuniswapFactory_Unipool_Bridge_Zap_V1 {
    function getExchange(address token)
        external
        view
        returns (address exchange);
}


interface Iuniswap_Unipool_Bridge_Zap_V1 {
    function getTokenToEthInputPrice(uint256 tokens_sold)
        external
        view
        returns (uint256 eth_bought);

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

    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(address from, address to, uint256 tokens)
        external
        returns (bool success);
}

pragma solidity ^0.5.13;


contract Unipool_Bridge_Zap_V1 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    bool private stopped = false;
    uint16 public goodwill;
    address public dzgoodwillAddress;
    IuniswapFactory_Unipool_Bridge_Zap_V1 public UniSwapFactoryAddress = IuniswapFactory_Unipool_Bridge_Zap_V1(
        0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95
    );

    constructor(uint16 _goodwill, address payable _dzgoodwillAddress) public {
        goodwill = _goodwill;
        dzgoodwillAddress = _dzgoodwillAddress;
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    function set_new_UniSwapFactoryAddress(address _new_UniSwapFactoryAddress)
        public
        onlyOwner
    {
        UniSwapFactoryAddress = IuniswapFactory_Unipool_Bridge_Zap_V1(
            _new_UniSwapFactoryAddress
        );
    }

    function set_new_goodwill(uint16 _new_goodwill) public onlyOwner {
        require(
            _new_goodwill > 0 && _new_goodwill < 10000,
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

    function ZapBridge(
        address _toWhomToIssue,
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 _IncomingLP
    ) public payable nonReentrant stopInEmergency returns (bool) {
        require(
            _FromTokenContractAddress != _ToTokenContractAddress,
            "Cannot bridge to same pool"
        );

        uint256 goodwillPortion = SafeMath.div(
            SafeMath.mul(_IncomingLP, goodwill),
            10000
        );

        (uint256 ethReceived, uint256 erc20received) = _exitFromPool(
            _IncomingLP,
            goodwillPortion,
            _FromTokenContractAddress
        );

        (uint256 LiquidityTokens, uint256 eth4Token) = _enterToPool(
            erc20received,
            _FromTokenContractAddress,
            _ToTokenContractAddress
        );

        _transfer(
            LiquidityTokens,
            ethReceived.sub(eth4Token),
            _toWhomToIssue,
            _ToTokenContractAddress
        );
        return true;
    }

    function _enterToPool(
        uint256 erc20received,
        address _FromTokenContractAddress,
        address _ToTokenContractAddress
    ) internal returns (uint256 LiquidityTokens, uint256 eth4Token) {

            Iuniswap_Unipool_Bridge_Zap_V1 FromUniSwapExchangeContractAddress
         = Iuniswap_Unipool_Bridge_Zap_V1(
            UniSwapFactoryAddress.getExchange(_FromTokenContractAddress)
        );


            Iuniswap_Unipool_Bridge_Zap_V1 ToUniSwapExchangeContractAddress
         = Iuniswap_Unipool_Bridge_Zap_V1(
            UniSwapFactoryAddress.getExchange(_ToTokenContractAddress)
        );

        IERC20(_FromTokenContractAddress).approve(
            address(FromUniSwapExchangeContractAddress),
            erc20received
        );

        uint256 erc20bought = FromUniSwapExchangeContractAddress
            .tokenToTokenSwapInput(
            erc20received,
            1,
            1,
            SafeMath.add(now, 1800),
            _ToTokenContractAddress
        );

        require(erc20bought > 0, "Error in swapping ERC");

        IERC20(_ToTokenContractAddress).approve(
            address(ToUniSwapExchangeContractAddress),
            erc20bought.mul(2)
        );

        eth4Token = ToUniSwapExchangeContractAddress.getTokenToEthInputPrice(
            erc20bought
        );
        LiquidityTokens = ToUniSwapExchangeContractAddress.addLiquidity.value(
            eth4Token
        )(1, erc20bought, SafeMath.add(now, 1800));
        require(LiquidityTokens > 0, "Error in acquiring LP");
    }

    function _exitFromPool(
        uint256 _IncomingLP,
        uint256 goodwillPortion,
        address _FromTokenContractAddress
    ) internal returns (uint256 ethReceived, uint256 erc20received) {

            Iuniswap_Unipool_Bridge_Zap_V1 FromUniSwapExchangeContractAddress
         = Iuniswap_Unipool_Bridge_Zap_V1(
            UniSwapFactoryAddress.getExchange(_FromTokenContractAddress)
        );
        require(
            FromUniSwapExchangeContractAddress.transferFrom(
                msg.sender,
                address(this),
                SafeMath.sub(_IncomingLP, goodwillPortion)
            ),
            "Error in transferring LP:1"
        );
        require(
            FromUniSwapExchangeContractAddress.transferFrom(
                msg.sender,
                dzgoodwillAddress,
                goodwillPortion
            ),
            "Error in transferring LP:2"
        );

        (ethReceived, erc20received) = FromUniSwapExchangeContractAddress
            .removeLiquidity(
            SafeMath.sub(_IncomingLP, goodwillPortion),
            1,
            1,
            SafeMath.add(now, 1800)
        );
    }

    function _transfer(
        uint256 _LiquidityTokens,
        uint256 _residualEth,
        address _toWhomToIssue,
        address _ToTokenContractAddress
    ) internal {

            Iuniswap_Unipool_Bridge_Zap_V1 ToUniSwapExchangeContractAddress
         = Iuniswap_Unipool_Bridge_Zap_V1(
            UniSwapFactoryAddress.getExchange(_ToTokenContractAddress)
        );
        IERC20 ToTokenContractAddress = IERC20(_ToTokenContractAddress);
        require(
            ToUniSwapExchangeContractAddress.transfer(
                _toWhomToIssue,
                _LiquidityTokens
            ),
            "Error in transferring LP:3"
        );
        uint256 residualTokens = ToTokenContractAddress.balanceOf(
            address(this)
        );
        require(
            ToTokenContractAddress.transfer(_toWhomToIssue, residualTokens),
            "Error in returning residual tokens"
        );
        (bool success, ) = _toWhomToIssue.call.value(_residualEth)("");
        require(success, "Error in returning residual tokens");
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(_owner, qty);
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

    function() external payable {}
}