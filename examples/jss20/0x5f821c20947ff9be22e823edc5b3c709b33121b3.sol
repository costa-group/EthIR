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


/**
 * @title ERC20Proxy
 * @notice This contract performs an ERC20 token transfer and stores a reference
  */
contract ERC20Proxy {
  // Event to declare a transfer with a reference
  event TransferWithReference(
    address tokenAddress,
    address to,
    uint256 amount,
    bytes indexed paymentReference
  );

  // Fallback function returns funds to the sender
  function()
    external
    payable
  {
    revert("not payable fallback");
  }

  /**
  * @notice Performs a ERC20 token transfer with a reference
  * @param _tokenAddress Address of the ERC20 token smart contract
  * @param _to Transfer recipient
  * @param _amount Amount to transfer
  * @param _paymentReference Reference of the payment related
  */
  function transferFromWithReference(
    address _tokenAddress,
    address _to,
    uint256 _amount,
    bytes calldata _paymentReference
  )
    external 
  {
    IERC20 erc20 = IERC20(_tokenAddress);
    require(erc20.transferFrom(msg.sender, _to, _amount), "transferFrom() failed");
    emit TransferWithReference(
      _tokenAddress,
      _to,
      _amount,
      _paymentReference
    );
  }
}