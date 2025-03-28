pragma solidity ^0.4.24;


/**

 * @title Ownable

 * @dev The Ownable contract has an owner address, and provides basic authorization control

 * functions, this simplifies the implementation of "user permissions".

 */

contract Ownable {

  address public owner;





  event OwnershipRenounced(address indexed previousOwner);

  event OwnershipTransferred(

    address indexed previousOwner,

    address indexed newOwner

  );





  /**

   * @dev The Ownable constructor sets the original `owner` of the contract to the sender

   * account.

   */

  constructor() public {

    owner = msg.sender;

  }



  /**

   * @dev Throws if called by any account other than the owner.

   */

  modifier onlyOwner() {

    require(msg.sender == owner);

    _;

  }



  /**

   * @dev Allows the current owner to relinquish control of the contract.

   * @notice Renouncing to ownership will leave the contract without an owner.

   * It will not be possible to call the functions with the `onlyOwner`

   * modifier anymore.

   */

  function renounceOwnership() public onlyOwner {

    emit OwnershipRenounced(owner);

    owner = address(0);

  }



  /**

   * @dev Allows the current owner to transfer control of the contract to a newOwner.

   * @param _newOwner The address to transfer ownership to.

   */

  function transferOwnership(address _newOwner) public onlyOwner {

    _transferOwnership(_newOwner);

  }



  /**

   * @dev Transfers control of the contract to a newOwner.

   * @param _newOwner The address to transfer ownership to.

   */

  function _transferOwnership(address _newOwner) internal {

    require(_newOwner != address(0));

    emit OwnershipTransferred(owner, _newOwner);

    owner = _newOwner;

  }

}





interface AggregatorInterface {

  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);



  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);

  event NewRound(uint256 indexed roundId, address indexed startedBy);

}



/**

 * @title A trusted proxy for updating where current answers are read from

 * @notice This contract provides a consistent address for the

 * CurrentAnwerInterface but delegates where it reads from to the owner, who is

 * trusted to update it.

 */

contract AggregatorProxy is AggregatorInterface, Ownable {



  AggregatorInterface public aggregator;



  constructor(address _aggregator) public Ownable() {

    setAggregator(_aggregator);

  }



  /**

   * @notice Reads the current answer from aggregator delegated to.

   */

  function latestAnswer()

    external

    view

    returns (int256)

  {

    return aggregator.latestAnswer();

  }



  /**

   * @notice Reads the last updated height from aggregator delegated to.

   */

  function latestTimestamp()

    external

    view

    returns (uint256)

  {

    return aggregator.latestTimestamp();

  }



  /**

   * @notice get past rounds answers

   * @param _roundId the answer number to retrieve the answer for

   */

  function getAnswer(uint256 _roundId)

    external

    view

    returns (int256)

  {

    return aggregator.getAnswer(_roundId);

  }



  /**

   * @notice get block timestamp when an answer was last updated

   * @param _roundId the answer number to retrieve the updated timestamp for

   */

  function getTimestamp(uint256 _roundId)

    external

    view

    returns (uint256)

  {

    return aggregator.getTimestamp(_roundId);

  }



  /**

   * @notice get the latest completed round where the answer was updated

   */

  function latestRound()

    external

    view

    returns (uint256)

  {

    return aggregator.latestRound();

  }



  /**

   * @notice Allows the owner to update the aggregator address.

   * @param _aggregator The new address for the aggregator contract

   */

  function setAggregator(address _aggregator)

    public

    onlyOwner()

  {

    aggregator = AggregatorInterface(_aggregator);

  }



  /**

   * @notice Allows the owner to destroy the contract if it is not intended to

   * be used any longer.

   */

  function destroy()

    external

    onlyOwner()

  {

    selfdestruct(owner);

  }



}