/**

 *Submitted for verification at Etherscan.io on 2020-07-28

*/



pragma solidity ^0.6.6;




interface AggregatorInterface {

  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);



  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

}



interface AggregatorV3Interface {



  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);



  // getRoundData and latestRoundData should both raise "No data present"

  // if they do not have data to report, instead of returning unset values

  // which could be misinterpreted as actual reported values.

  function getRoundData(uint80 _roundId)

    external

    view

    returns (

      uint80 roundId,

      int256 answer,

      uint256 startedAt,

      uint256 updatedAt,

      uint80 answeredInRound

    );

  function latestRoundData()

    external

    view

    returns (

      uint80 roundId,

      int256 answer,

      uint256 startedAt,

      uint256 updatedAt,

      uint80 answeredInRound

    );



  event NewRound(

    uint256 indexed roundId,

    address indexed startedBy,

    uint256 startedAt

  );

  event AnswerUpdated(

    int256 indexed current,

    uint256 indexed roundId,

    uint256 updatedAt

  );



}



/**

 * @title A facade forAggregator versions to conform to the new v0.6

 * Aggregator V3 interface.

 */

contract AggregatorFacade is AggregatorInterface, AggregatorV3Interface {



  AggregatorInterface public aggregator;

  uint8 public override decimals;

  string public override description;



  uint256 constant public override version = 2;



  // An error specific to the Aggregator V3 Interface, to prevent possible

  // confusion around accidentally reading unset values as reported values.

  string constant private V3_NO_DATA_ERROR = "No data present";



  constructor(

    address _aggregator,

    uint8 _decimals,

    string memory _description

  ) public {

    aggregator = AggregatorInterface(_aggregator);

    decimals = _decimals;

    description = _description;

  }



  /**

   * @notice get the latest completed round where the answer was updated

   */

  function latestRound()

    external

    view

    virtual

    override

    returns (uint256)

  {

    return aggregator.latestRound();

  }



  /**

   * @notice Reads the current answer from aggregator delegated to.

   */

  function latestAnswer()

    external

    view

    virtual

    override

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

    virtual

    override

    returns (uint256)

  {

    return aggregator.latestTimestamp();

  }



  /**

   * @notice get data about the latest round. Consumers are encouraged to check

   * that they're receiving fresh data by inspecting the updatedAt value.

   * @return roundId is the round ID for which data was retrieved

   * @return answer is the answer for the given round

   * @return startedAt is always equal to updatedAt because the underlying

   * Aggregator contract does not expose this information.

   * @return updatedAt is the timestamp when the round last was updated (i.e.

   * answer was last computed)

   * @return answeredInRound is always equal to roundId because the underlying

   * Aggregator contract does not expose this information.

   * @dev Note that for rounds that haven't yet received responses from all

   * oracles, answer and updatedAt may change between queries.

   */

  function latestRoundData()

    external

    view

    virtual

    override

    returns (

      uint80 roundId,

      int256 answer,

      uint256 startedAt,

      uint256 updatedAt,

      uint80 answeredInRound

    )

  {

    return _getRoundData(uint80(aggregator.latestRound()));

  }



  /**

   * @notice get past rounds answers

   * @param _roundId the answer number to retrieve the answer for

   */

  function getAnswer(uint256 _roundId)

    external

    view

    virtual

    override

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

    virtual

    override

    returns (uint256)

  {

    return aggregator.getTimestamp(_roundId);

  }



  /**

   * @notice get data about a round. Consumers are encouraged to check

   * that they're receiving fresh data by inspecting the updatedAt value.

   * @param _roundId the round ID to retrieve the round data for

   * @return roundId is the round ID for which data was retrieved

   * @return answer is the answer for the given round

   * @return startedAt is always equal to updatedAt because the underlying

   * Aggregator contract does not expose this information.

   * @return updatedAt is the timestamp when the round last was updated (i.e.

   * answer was last computed)

   * @return answeredInRound is always equal to roundId because the underlying

   * Aggregator contract does not expose this information.

   * @dev Note that for rounds that haven't yet received responses from all

   * oracles, answer and updatedAt may change between queries.

   */

  function getRoundData(uint80 _roundId)

    external

    view

    virtual

    override

    returns (

      uint80 roundId,

      int256 answer,

      uint256 startedAt,

      uint256 updatedAt,

      uint80 answeredInRound

    )

  {

    return _getRoundData(_roundId);

  }



  /*

   * Internal

   */



  function _getRoundData(uint80 _roundId)

    internal

    view

    returns (

      uint80 roundId,

      int256 answer,

      uint256 startedAt,

      uint256 updatedAt,

      uint80 answeredInRound

    )

  {

    answer = aggregator.getAnswer(_roundId);

    updatedAt = uint64(aggregator.getTimestamp(_roundId));



    require(updatedAt > 0, V3_NO_DATA_ERROR);



    return (_roundId, answer, updatedAt, updatedAt, _roundId);

  }



}