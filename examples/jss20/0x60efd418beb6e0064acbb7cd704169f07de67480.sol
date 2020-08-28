pragma solidity 0.6.4;
pragma experimental ABIEncoderV2;

/**
 * @title An Unlock Protocol scanner
 * @author Maarten Zuidhoorn
 */
contract UnlockScanner {
  /**
  * @notice Get expiration timestamp for a single address
  * @param owner The address to get the timestamps for
  * @param unlockContract The address of the Unlock Protocol contract
  * @return timestamp The expiration timestamp, or zero if the address is not a contract, or does not implement the `keyExpirationTimestampFor` function
*/
  function unlockTimestamp(address owner, address unlockContract) external returns (uint256 timestamp) {
    timestamp = 0;
    uint256 size = codeSize(unlockContract);

    if (size > 0) {
      (bool success, bytes memory data) = unlockContract.call(abi.encodeWithSelector(bytes4(0xabdf82ce), owner));
      if (success) {
        (timestamp) = abi.decode(data, (uint256));
      }
    }
  }

  /**
   * @notice Get expiration timestamp for multiple contracts, for multiple addresses
   * @param addresses The addresses to get the timestamps for
   * @param contracts The addresses of the Unlock Protocol contracts
   * @return timestamps The timestamps in the same order as the addresses specified
   */
  function unlockTimestamps(address[] calldata addresses, address[] calldata contracts) external returns (uint256[][] memory timestamps) {
    timestamps = new uint256[][](addresses.length);

    for (uint256 i = 0; i < addresses.length; i++) {
      timestamps[i] = new uint256[](contracts.length);
      for (uint256 j = 0; j < contracts.length; j++) {
        timestamps[i][j] = this.unlockTimestamp(addresses[i], contracts[j]);
      }
    }
  }

  /**
    * @notice Get code size of an address
    * @param _address The address to get code size for
    * @return size The size of the code
   */
  function codeSize(address _address) internal view returns (uint256 size) {
    assembly {
      size := extcodesize(_address)
    }
  }
}