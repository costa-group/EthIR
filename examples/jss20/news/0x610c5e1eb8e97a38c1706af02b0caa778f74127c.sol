// File: contracts/iface/IBrokerRegistry.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;




/// @title IBrokerRegistry

/// @dev A broker is an account that can submit orders on behalf of other

///      accounts. When registering a broker, the owner can also specify a

///      pre-deployed BrokerInterceptor to hook into the exchange smart contracts.

/// @author Daniel Wang - <daniel@loopring.org>.

contract IBrokerRegistry {

    event BrokerRegistered(

        address owner,

        address broker,

        address interceptor

    );



    event BrokerUnregistered(

        address owner,

        address broker,

        address interceptor

    );



    event AllBrokersUnregistered(

        address owner

    );



    /// @dev   Validates if the broker was registered for the order owner and

    ///        returns the possible BrokerInterceptor to be used.

    /// @param owner The owner of the order

    /// @param broker The broker of the order

    /// @return True if the broker was registered for the owner

    ///         and the BrokerInterceptor to use.

    function getBroker(

        address owner,

        address broker

        )

        external

        view

        returns(

            bool registered,

            address interceptor

        );



    /// @dev   Gets all registered brokers for an owner.

    /// @param owner The owner

    /// @param start The start index of the list of brokers

    /// @param count The number of brokers to return

    /// @return The list of requested brokers and corresponding BrokerInterceptors

    function getBrokers(

        address owner,

        uint    start,

        uint    count

        )

        external

        view

        returns (

            address[] memory brokers,

            address[] memory interceptors

        );



    /// @dev   Registers a broker for msg.sender and an optional

    ///        corresponding BrokerInterceptor.

    /// @param broker The broker to register

    /// @param interceptor The optional BrokerInterceptor to use (0x0 allowed)

    function registerBroker(

        address broker,

        address interceptor

        )

        external;



    /// @dev   Unregisters a broker for msg.sender

    /// @param broker The broker to unregister

    function unregisterBroker(

        address broker

        )

        external;



    /// @dev   Unregisters all brokers for msg.sender

    function unregisterAllBrokers(

        )

        external;

}



// File: contracts/iface/IBurnRateTable.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;




/// @author Brecht Devos - <brecht@loopring.org>

/// @title IBurnRateTable - A contract for managing burn rates for tokens

contract IBurnRateTable {



    struct TokenData {

        uint    tier;

        uint    validUntil;

    }



    mapping(address => TokenData) public tokens;



    uint public constant YEAR_TO_SECONDS = 31556952;



    // Tiers

    uint8 public constant TIER_4 = 0;

    uint8 public constant TIER_3 = 1;

    uint8 public constant TIER_2 = 2;

    uint8 public constant TIER_1 = 3;



    uint16 public constant BURN_BASE_PERCENTAGE           =                 100 * 10; // 100%



    // Cost of upgrading the tier level of a token in a percentage of the total LRC supply

    uint16 public constant TIER_UPGRADE_COST_PERCENTAGE   =                        1; // 0.1%



    // Burn rates

    // Matching

    uint16 public constant BURN_MATCHING_TIER1            =                       25; // 2.5%

    uint16 public constant BURN_MATCHING_TIER2            =                  15 * 10; //  15%

    uint16 public constant BURN_MATCHING_TIER3            =                  30 * 10; //  30%

    uint16 public constant BURN_MATCHING_TIER4            =                  50 * 10; //  50%

    // P2P

    uint16 public constant BURN_P2P_TIER1                 =                       25; // 2.5%

    uint16 public constant BURN_P2P_TIER2                 =                  15 * 10; //  15%

    uint16 public constant BURN_P2P_TIER3                 =                  30 * 10; //  30%

    uint16 public constant BURN_P2P_TIER4                 =                  50 * 10; //  50%



    event TokenTierUpgraded(

        address indexed addr,

        uint            tier

    );



    /// @dev   Returns the P2P and matching burn rate for the token.

    /// @param token The token to get the burn rate for.

    /// @return The burn rate. The P2P burn rate and matching burn rate

    ///         are packed together in the lowest 4 bytes.

    ///         (2 bytes P2P, 2 bytes matching)

    function getBurnRate(

        address token

        )

        external

        view

        returns (uint32 burnRate);



    /// @dev   Returns the tier of a token.

    /// @param token The token to get the token tier for.

    /// @return The tier of the token

    function getTokenTier(

        address token

        )

        public

        view

        returns (uint);



    /// @dev   Upgrades the tier of a token. Before calling this function,

    ///        msg.sender needs to approve this contract for the neccessary funds.

    /// @param token The token to upgrade the tier for.

    /// @return True if successful, false otherwise.

    function upgradeTokenTier(

        address token

        )

        external

        returns (bool);



}



// File: contracts/iface/IFeeHolder.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;




/// @author Kongliang Zhong - <kongliang@loopring.org>

/// @title IFeeHolder - A contract holding fees.

contract IFeeHolder {



    event TokenWithdrawn(

        address owner,

        address token,

        uint value

    );



    // A map of all fee balances

    mapping(address => mapping(address => uint)) public feeBalances;



    // A map of all the nonces for a withdrawTokenFor request

    mapping(address => uint) public nonces;



    /// @dev   Allows withdrawing the tokens to be burned by

    ///        authorized contracts.

    /// @param token The token to be used to burn buy and burn LRC

    /// @param value The amount of tokens to withdraw

    function withdrawBurned(

        address token,

        uint value

        )

        external

        returns (bool success);



    /// @dev   Allows withdrawing the fee payments funds

    ///        msg.sender is the recipient of the fee and the address

    ///        to which the tokens will be sent.

    /// @param token The token to withdraw

    /// @param value The amount of tokens to withdraw

    function withdrawToken(

        address token,

        uint value

        )

        external

        returns (bool success);



    /// @dev   Allows withdrawing the fee payments funds by providing a

    ///        a signature

    function withdrawTokenFor(

      address owner,

      address token,

      uint value,

      address recipient,

      uint feeValue,

      address feeRecipient,

      uint nonce,

      bytes calldata signature

      )

      external

      returns (bool success);



    function batchAddFeeBalances(

        bytes32[] calldata batch

        )

        external;

}



// File: contracts/iface/IOrderBook.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;




/// @title IOrderBook

/// @author Daniel Wang - <daniel@loopring.org>.

/// @author Kongliang Zhong - <kongliang@loopring.org>.

contract IOrderBook {

    // The map of registered order hashes

    mapping(bytes32 => bool) public orderSubmitted;



    /// @dev  Event emitted when an order was successfully submitted

    ///        orderHash      The hash of the order

    ///        orderData      The data of the order as passed to submitOrder()

    event OrderSubmitted(

        bytes32 orderHash,

        bytes   orderData

    );



    /// @dev   Submits an order to the on-chain order book.

    ///        No signature is needed. The order can only be sumbitted by its

    ///        owner or its broker (the owner can be the address of a contract).

    /// @param orderData The data of the order. Contains all fields that are used

    ///        for the order hash calculation.

    ///        See OrderHelper.updateHash() for detailed information.

    function submitOrder(

        bytes calldata orderData

        )

        external

        returns (bytes32);

}



// File: contracts/iface/IOrderRegistry.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;




/// @title IOrderRegistry

/// @author Daniel Wang - <daniel@loopring.org>.

contract IOrderRegistry {



    /// @dev   Returns wether the order hash was registered in the registry.

    /// @param broker The broker of the order

    /// @param orderHash The hash of the order

    /// @return True if the order hash was registered, else false.

    function isOrderHashRegistered(

        address broker,

        bytes32 orderHash

        )

        external

        view

        returns (bool);



    /// @dev   Registers an order in the registry.

    ///        msg.sender needs to be the broker of the order.

    /// @param orderHash The hash of the order

    function registerOrderHash(

        bytes32 orderHash

        )

        external;

}



// File: contracts/iface/ITradeDelegate.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;




/// @title ITradeDelegate

/// @dev Acts as a middle man to transfer ERC20 tokens on behalf of different

/// versions of Loopring protocol to avoid ERC20 re-authorization.

/// @author Daniel Wang - <daniel@loopring.org>.

contract ITradeDelegate {



    function batchTransfer(

        bytes32[] calldata batch

        )

        external;





    /// @dev Add a Loopring protocol address.

    /// @param addr A loopring protocol address.

    function authorizeAddress(

        address addr

        )

        external;



    /// @dev Remove a Loopring protocol address.

    /// @param addr A loopring protocol address.

    function deauthorizeAddress(

        address addr

        )

        external;



    function isAddressAuthorized(

        address addr

        )

        public

        view

        returns (bool);





    function suspend()

        external;



    function resume()

        external;



    function kill()

        external;

}



// File: contracts/iface/ITradeHistory.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;




/// @title ITradeHistory

/// @dev Stores the trade history and cancelled data of orders

/// @author Brecht Devos - <brecht@loopring.org>.

contract ITradeHistory {



    // The following map is used to keep trace of order fill and cancellation

    // history.

    mapping (bytes32 => uint) public filled;



    // This map is used to keep trace of order's cancellation history.

    mapping (address => mapping (bytes32 => bool)) public cancelled;



    // A map from a broker to its cutoff timestamp.

    mapping (address => uint) public cutoffs;



    // A map from a broker to its trading-pair cutoff timestamp.

    mapping (address => mapping (bytes20 => uint)) public tradingPairCutoffs;



    // A map from a broker to an order owner to its cutoff timestamp.

    mapping (address => mapping (address => uint)) public cutoffsOwner;



    // A map from a broker to an order owner to its trading-pair cutoff timestamp.

    mapping (address => mapping (address => mapping (bytes20 => uint))) public tradingPairCutoffsOwner;





    function batchUpdateFilled(

        bytes32[] calldata filledInfo

        )

        external;



    function setCancelled(

        address broker,

        bytes32 orderHash

        )

        external;



    function setCutoffs(

        address broker,

        uint cutoff

        )

        external;



    function setTradingPairCutoffs(

        address broker,

        bytes20 tokenPair,

        uint cutoff

        )

        external;



    function setCutoffsOfOwner(

        address broker,

        address owner,

        uint cutoff

        )

        external;



    function setTradingPairCutoffsOfOwner(

        address broker,

        address owner,

        bytes20 tokenPair,

        uint cutoff

        )

        external;



    function batchGetFilledAndCheckCancelled(

        bytes32[] calldata orderInfo

        )

        external

        view

        returns (uint[] memory fills);





    /// @dev Add a Loopring protocol address.

    /// @param addr A loopring protocol address.

    function authorizeAddress(

        address addr

        )

        external;



    /// @dev Remove a Loopring protocol address.

    /// @param addr A loopring protocol address.

    function deauthorizeAddress(

        address addr

        )

        external;



    function isAddressAuthorized(

        address addr

        )

        public

        view

        returns (bool);





    function suspend()

        external;



    function resume()

        external;



    function kill()

        external;

}



// File: contracts/impl/Data.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;


















library Data {



    enum TokenType { ERC20 }



    struct Header {

        uint version;

        uint numOrders;

        uint numRings;

        uint numSpendables;

    }



    struct BrokerAction {

        bytes32 hash;

        address broker;

        uint[] orderIndices;

        uint numOrders;

        uint[] transferIndices;

        uint numTransfers;

        address tokenS;

        address tokenB;

        address feeToken;

    }



    struct BrokerTransfer {

        bytes32 hash;

        address token;

        uint amount;

        address recipient;

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



    struct BrokerApprovalRequest {

        BrokerOrder[] orders;

        address tokenS;

        address tokenB;

        address feeToken;

        uint totalFillAmountB;

        uint totalRequestedAmountS;

        uint totalRequestedFeeAmount;

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



    struct Context {

        address lrcTokenAddress;

        ITradeDelegate  delegate;

        ITradeHistory   tradeHistory;

        IBrokerRegistry orderBrokerRegistry;

        IOrderRegistry  orderRegistry;

        IFeeHolder feeHolder;

        IOrderBook orderBook;

        IBurnRateTable burnRateTable;

        uint64 ringIndex;

        uint feePercentageBase;

        bytes32[] tokenBurnRates;

        uint feeData;

        uint feePtr;

        uint transferData;

        uint transferPtr;

        BrokerOrder[] brokerOrders;

        BrokerAction[] brokerActions;

        BrokerTransfer[] brokerTransfers;

        uint numBrokerOrders;

        uint numBrokerActions;

        uint numBrokerTransfers;

    }



    struct Mining {

        // required fields

        address feeRecipient;



        // optional fields

        address miner;

        bytes   sig;



        // computed fields

        bytes32 hash;

        address interceptor;

    }



    struct Spendable {

        bool initialized;

        uint amount;

        uint reserved;

    }



    struct Order {

        uint      version;



        // required fields

        address   owner;

        address   tokenS;

        address   tokenB;

        uint      amountS;

        uint      amountB;

        uint      validSince;

        Spendable tokenSpendableS;

        Spendable tokenSpendableFee;



        // optional fields

        address   dualAuthAddr;

        address   broker;

        Spendable brokerSpendableS;

        Spendable brokerSpendableFee;

        address   orderInterceptor;

        address   wallet;

        uint      validUntil;

        bytes     sig;

        bytes     dualAuthSig;

        bool      allOrNone;

        address   feeToken;

        uint      feeAmount;

        int16     waiveFeePercentage;

        uint16    tokenSFeePercentage;    // Pre-trading

        uint16    tokenBFeePercentage;   // Post-trading

        address   tokenRecipient;

        uint16    walletSplitPercentage;



        // computed fields

        bool    P2P;

        bytes32 hash;

        address brokerInterceptor;

        uint    filledAmountS;

        uint    initialFilledAmountS;

        bool    valid;



        TokenType tokenTypeS;

        TokenType tokenTypeB;

        TokenType tokenTypeFee;

        bytes32 trancheS;

        bytes32 trancheB;

        uint    maxPrimaryFillAmount;

        bool    transferFirstAsMaker;

        bytes   transferDataS;

    }



    struct Participation {

        // required fields

        Order order;



        // computed fields

        uint splitS;

        uint feeAmount;

        uint feeAmountS;

        uint feeAmountB;

        uint rebateFee;

        uint rebateS;

        uint rebateB;

        uint fillAmountS;

        uint fillAmountB;

    }



    struct Ring {

        uint size;

        Participation[] participations;

        bytes32 hash;

        uint minerFeesToOrdersPercentage;

        bool valid;

    }



    struct FeeContext {

        Data.Ring ring;

        Data.Context ctx;

        address feeRecipient;

        uint walletPercentage;

        int16 waiveFeePercentage;

        address owner;

        address wallet;

        bool P2P;

    }

}



// File: contracts/lib/BytesUtil.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;




/// @title Utility Functions for bytes

/// @author Daniel Wang - <daniel@loopring.org>

library BytesUtil {

    function bytesToBytes32(

        bytes memory b,

        uint offset

        )

        internal

        pure

        returns (bytes32)

    {

        return bytes32(bytesToUintX(b, offset, 32));

    }



    function bytesToUint(

        bytes memory b,

        uint offset

        )

        internal

        pure

        returns (uint)

    {

        return bytesToUintX(b, offset, 32);

    }



    function bytesToAddress(

        bytes memory b,

        uint offset

        )

        internal

        pure

        returns (address)

    {

        return address(bytesToUintX(b, offset, 20) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

    }



    function bytesToUint16(

        bytes memory b,

        uint offset

        )

        internal

        pure

        returns (uint16)

    {

        return uint16(bytesToUintX(b, offset, 2) & 0xFFFF);

    }



    function bytesToUintX(

        bytes memory b,

        uint offset,

        uint numBytes

        )

        private

        pure

        returns (uint data)

    {

        require(b.length >= offset + numBytes, "INVALID_SIZE");

        assembly {

            data := mload(add(add(b, numBytes), offset))

        }

    }



    function subBytes(

        bytes memory b,

        uint offset

        )

        internal

        pure

        returns (bytes memory data)

    {

        require(b.length >= offset + 32, "INVALID_SIZE");

        assembly {

            data := add(add(b, 32), offset)

        }

    }

}



// File: contracts/lib/MultihashUtil.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;






/// @title Utility Functions for Multihash signature verificaiton

/// @author Daniel Wang - <daniel@loopring.org>

/// For more information:

///   - https://github.com/saurfang/ipfs-multihash-on-solidity

///   - https://github.com/multiformats/multihash

///   - https://github.com/multiformats/js-multihash

library MultihashUtil {



    enum HashAlgorithm { Ethereum, EIP712 }



    string public constant SIG_PREFIX = "\x19Ethereum Signed Message:\n32";



    function verifySignature(

        address signer,

        bytes32 plaintext,

        bytes memory multihash

        )

        internal

        pure

        returns (bool)

    {

        uint length = multihash.length;

        require(length >= 2, "invalid multihash format");

        uint8 algorithm;

        uint8 size;

        assembly {

            algorithm := mload(add(multihash, 1))

            size := mload(add(multihash, 2))

        }

        require(length == (2 + size), "bad multihash size");



        if (algorithm == uint8(HashAlgorithm.Ethereum)) {

            require(signer != address(0x0), "invalid signer address");

            require(size == 65, "bad Ethereum multihash size");

            bytes32 hash;

            uint8 v;

            bytes32 r;

            bytes32 s;

            assembly {

                let data := mload(0x40)

                mstore(data, 0x19457468657265756d205369676e6564204d6573736167653a0a333200000000) // SIG_PREFIX

                mstore(add(data, 28), plaintext)                                                 // plaintext

                hash := keccak256(data, 60)                                                      // 28 + 32

                // Extract v, r and s from the multihash data

                v := mload(add(multihash, 3))

                r := mload(add(multihash, 35))

                s := mload(add(multihash, 67))

            }

            return signer == ecrecover(

                hash,

                v,

                r,

                s

            );

        } else if (algorithm == uint8(HashAlgorithm.EIP712)) {

            require(signer != address(0x0), "invalid signer address");

            require(size == 65, "bad EIP712 multihash size");

            uint8 v;

            bytes32 r;

            bytes32 s;

            assembly {

                // Extract v, r and s from the multihash data

                v := mload(add(multihash, 3))

                r := mload(add(multihash, 35))

                s := mload(add(multihash, 67))

            }

            return signer == ecrecover(

                plaintext,

                v,

                r,

                s

            );

        } else {

            return false;

        }

    }

}



// File: contracts/helper/MiningHelper.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;








/// @title MiningHelper

/// @author Daniel Wang - <daniel@loopring.org>.

library MiningHelper {



    function updateMinerAndInterceptor(

        Data.Mining memory mining

        )

        internal

        pure

    {



        if (mining.miner == address(0x0)) {

            mining.miner = mining.feeRecipient;

        }



        // We do not support any interceptors for now

        /* else { */

        /*     (bool registered, address interceptor) = ctx.minerBrokerRegistry.getBroker( */

        /*         mining.feeRecipient, */

        /*         mining.miner */

        /*     ); */

        /*     if (registered) { */

        /*         mining.interceptor = interceptor; */

        /*     } */

        /* } */

    }



    function updateHash(

        Data.Mining memory mining,

        Data.Ring[] memory rings

        )

        internal

        pure

    {

        bytes32 hash;

        assembly {

            let ring := mload(add(rings, 32))                               // rings[0]

            let ringHashes := mload(add(ring, 64))                          // ring.hash

            for { let i := 1 } lt(i, mload(rings)) { i := add(i, 1) } {

                ring := mload(add(rings, mul(add(i, 1), 32)))               // rings[i]

                ringHashes := xor(ringHashes, mload(add(ring, 64)))         // ring.hash

            }

            let data := mload(0x40)

            data := add(data, 12)

            // Store data back to front to allow overwriting data at the front because of padding

            mstore(add(data, 40), ringHashes)                               // ringHashes

            mstore(sub(add(data, 20), 12), mload(add(mining, 32)))          // mining.miner

            mstore(sub(data, 12),          mload(add(mining,  0)))          // mining.feeRecipient

            hash := keccak256(data, 72)                                     // 20 + 20 + 32

        }

        mining.hash = hash;

    }



    function checkMinerSignature(

        Data.Mining memory mining

        )

        internal

        view

        returns (bool)

    {

        if (mining.sig.length == 0) {

            return (msg.sender == mining.miner);

        } else {

            return MultihashUtil.verifySignature(

                mining.miner,

                mining.hash,

                mining.sig

            );

        }

    }



}



// File: contracts/lib/ERC20.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;




/// @title ERC20 Token Interface

/// @dev see https://github.com/ethereum/EIPs/issues/20

/// @author Daniel Wang - <daniel@loopring.org>

contract ERC20 {

    function totalSupply()

        public

        view

        returns (uint256);



    function balanceOf(

        address who

        )

        public

        view

        returns (uint256);



    function allowance(

        address owner,

        address spender

        )

        public

        view

        returns (uint256);



    function transfer(

        address to,

        uint256 value

        )

        public

        returns (bool);



    function transferFrom(

        address from,

        address to,

        uint256 value

        )

        public

        returns (bool);



    function approve(

        address spender,

        uint256 value

        )

        public

        returns (bool);

}



// File: contracts/lib/MathUint.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;




/// @title Utility Functions for uint

/// @author Daniel Wang - <daniel@loopring.org>

library MathUint {



    function mul(

        uint a,

        uint b

        )

        internal

        pure

        returns (uint c)

    {

        c = a * b;

        require(a == 0 || c / a == b, "INVALID_VALUE");

    }



    function sub(

        uint a,

        uint b

        )

        internal

        pure

        returns (uint)

    {

        require(b <= a, "INVALID_VALUE");

        return a - b;

    }



    function add(

        uint a,

        uint b

        )

        internal

        pure

        returns (uint c)

    {

        c = a + b;

        require(c >= a, "INVALID_VALUE");

    }



    function hasRoundingError(

        uint value,

        uint numerator,

        uint denominator

        )

        internal

        pure

        returns (bool)

    {

        uint multiplied = mul(value, numerator);

        uint remainder = multiplied % denominator;

        // Return true if the rounding error is larger than 1%

        return mul(remainder, 100) > multiplied;

    }

}



// File: contracts/iface/IBrokerDelegate.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/



pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;





/**

 * @title IBrokerDelegate

 * @author Zack Rubenstein

 */

interface IBrokerDelegate {



  /*

   * Loopring requests an allowance be set on a given token for a specified amount. Order details

   * are provided (tokenS, totalAmountS, tokenB, totalAmountB, orderTokenRecipient, extraOrderData)

   * to aid in any calculations or on-chain exchange of assets that may be required. The last 4

   * parameters concern the actual token approval being requested of the broker.

   *

   * @returns Whether or not onOrderFillReport should be called for orders using this broker

   */

  function brokerRequestAllowance(Data.BrokerApprovalRequest calldata request) external returns (bool);



  /*

   * After Loopring performs all of the transfers necessary to complete all the submitted

   * rings it will call this function for every order's brokerInterceptor (if set) passing

   * along the final fill counts for tokenB, tokenS and feeToken. This allows actions to be

   * performed on a per-order basis after all tokenS/feeToken funds have left the order owner's

   * possesion and the tokenB funds have been transfered to the order owner's intended recipient

   */

  function onOrderFillReport(Data.BrokerInterceptorReport calldata fillReport) external;



  /*

   * Get the available token balance controlled by the broker on behalf of an address (owner)

   */

  function brokerBalanceOf(address owner, address token) external view returns (uint);

}



// File: contracts/helper/OrderHelper.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;












/// @title OrderHelper

/// @author Daniel Wang - <daniel@loopring.org>.

library OrderHelper {

    using MathUint      for uint;



    string constant internal EIP191_HEADER = "\x19\x01";

    string constant internal EIP712_DOMAIN_NAME = "Loopring Protocol";

    string constant internal EIP712_DOMAIN_VERSION = "2";

    bytes32 constant internal EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(

        abi.encodePacked(

            "EIP712Domain(",

            "string name,",

            "string version",

            ")"

        )

    );

    bytes32 constant internal EIP712_ORDER_SCHEMA_HASH = keccak256(

        abi.encodePacked(

            "Order(",

            "uint amountS,",

            "uint amountB,",

            "uint feeAmount,",

            "uint validSince,",

            "uint validUntil,",

            "address owner,",

            "address tokenS,",

            "address tokenB,",

            "address dualAuthAddr,",

            "address broker,",

            "address orderInterceptor,",

            "address wallet,",

            "address tokenRecipient,",

            "address feeToken,",

            "uint16 walletSplitPercentage,",

            "uint16 tokenSFeePercentage,",

            "uint16 tokenBFeePercentage,",

            "bool allOrNone,",

            "uint8 tokenTypeS,",

            "uint8 tokenTypeB,",

            "uint8 tokenTypeFee,",

            "bytes32 trancheS,",

            "bytes32 trancheB,",

            "bytes transferDataS",

            ")"

        )

    );

    bytes32 constant internal EIP712_DOMAIN_HASH = keccak256(

        abi.encodePacked(

            EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,

            keccak256(bytes(EIP712_DOMAIN_NAME)),

            keccak256(bytes(EIP712_DOMAIN_VERSION))

        )

    );



    function updateHash(Data.Order memory order)

        internal

        pure

    {

        /* bytes32 message = keccak256( */

        /*     abi.encode( */

        /*         EIP712_ORDER_SCHEMA_HASH, */

        /*         order.amountS, */

        /*         order.amountB, */

        /*         order.feeAmount, */

        /*         order.validSince, */

        /*         order.validUntil, */

        /*         order.owner, */

        /*         order.tokenS, */

        /*         order.tokenB, */

        /*         order.dualAuthAddr, */

        /*         order.broker, */

        /*         order.orderInterceptor, */

        /*         order.wallet, */

        /*         order.tokenRecipient */

        /*         order.feeToken, */

        /*         order.walletSplitPercentage, */

        /*         order.tokenSFeePercentage, */

        /*         order.tokenBFeePercentage, */

        /*         order.allOrNone, */

        /*         order.tokenTypeS, */

        /*         order.tokenTypeB, */

        /*         order.tokenTypeFee, */

        /*         order.trancheS, */

        /*         order.trancheB, */

        /*         order.transferDataS */

        /*     ) */

        /* ); */

        /* order.hash = keccak256( */

        /*    abi.encodePacked( */

        /*        EIP191_HEADER, */

        /*        EIP712_DOMAIN_HASH, */

        /*        message */

        /*    ) */

        /*); */



        // Precalculated EIP712_ORDER_SCHEMA_HASH amd EIP712_DOMAIN_HASH because

        // the solidity compiler doesn't correctly precalculate them for us.

        bytes32 _EIP712_ORDER_SCHEMA_HASH = 0x40b942178d2a51f1f61934268590778feb8114db632db7d88537c98d2b05c5f2;

        bytes32 _EIP712_DOMAIN_HASH = 0xaea25658c273c666156bd427f83a666135fcde6887a6c25fc1cd1562bc4f3f34;



        bytes32 hash;

        assembly {

            // Calculate the hash for transferDataS separately

            let transferDataS := mload(add(order, 1248))              // order.transferDataS

            let transferDataSHash := keccak256(add(transferDataS, 32), mload(transferDataS))



            let ptr := mload(64)

            mstore(add(ptr,   0), _EIP712_ORDER_SCHEMA_HASH)     // EIP712_ORDER_SCHEMA_HASH

            mstore(add(ptr,  32), mload(add(order, 128)))        // order.amountS

            mstore(add(ptr,  64), mload(add(order, 160)))        // order.amountB

            mstore(add(ptr,  96), mload(add(order, 640)))        // order.feeAmount

            mstore(add(ptr, 128), mload(add(order, 192)))        // order.validSince

            mstore(add(ptr, 160), mload(add(order, 480)))        // order.validUntil

            mstore(add(ptr, 192), mload(add(order,  32)))        // order.owner

            mstore(add(ptr, 224), mload(add(order,  64)))        // order.tokenS

            mstore(add(ptr, 256), mload(add(order,  96)))        // order.tokenB

            mstore(add(ptr, 288), mload(add(order, 288)))        // order.dualAuthAddr

            mstore(add(ptr, 320), mload(add(order, 320)))        // order.broker

            mstore(add(ptr, 352), mload(add(order, 416)))        // order.orderInterceptor

            mstore(add(ptr, 384), mload(add(order, 448)))        // order.wallet

            mstore(add(ptr, 416), mload(add(order, 768)))        // order.tokenRecipient

            mstore(add(ptr, 448), mload(add(order, 608)))        // order.feeToken

            mstore(add(ptr, 480), mload(add(order, 800)))        // order.walletSplitPercentage

            mstore(add(ptr, 512), mload(add(order, 704)))        // order.tokenSFeePercentage

            mstore(add(ptr, 544), mload(add(order, 736)))        // order.tokenBFeePercentage

            mstore(add(ptr, 576), mload(add(order, 576)))        // order.allOrNone

            mstore(add(ptr, 608), mload(add(order, 1024)))       // order.tokenTypeS

            mstore(add(ptr, 640), mload(add(order, 1056)))       // order.tokenTypeB

            mstore(add(ptr, 672), mload(add(order, 1088)))       // order.tokenTypeFee

            mstore(add(ptr, 704), mload(add(order, 1120)))       // order.trancheS

            mstore(add(ptr, 736), mload(add(order, 1152)))       // order.trancheB

            mstore(add(ptr, 768), transferDataSHash)             // keccak256(order.transferDataS)

            let message := keccak256(ptr, 800)                   // 25 * 32



            mstore(add(ptr,  0), 0x1901)                         // EIP191_HEADER

            mstore(add(ptr, 32), _EIP712_DOMAIN_HASH)            // EIP712_DOMAIN_HASH

            mstore(add(ptr, 64), message)                        // message

            hash := keccak256(add(ptr, 30), 66)                  // 2 + 32 + 32

        }

        order.hash = hash;

    }



    function check(

        Data.Order memory order,

        Data.Context memory ctx

        )

        internal

        view

    {

        // If the order was already partially filled

        // we don't have to check all of the infos and the signature again

        if(order.filledAmountS == 0) {

            validateAllInfo(order, ctx);

            checkOwnerSignature(order, ctx);

        } else {

            validateUnstableInfo(order, ctx);

        }



        checkP2P(order);

    }



    function validateAllInfo(

        Data.Order memory order,

        Data.Context memory ctx

        )

        internal

        view

    {

        bool valid = true;

        valid = valid && (order.version == 0); // unsupported order version

        valid = valid && (order.owner != address(0x0)); // invalid order owner

        valid = valid && (order.tokenS != address(0x0)); // invalid order tokenS

        valid = valid && (order.tokenB != address(0x0)); // invalid order tokenB

        valid = valid && (order.amountS != 0); // invalid order amountS

        valid = valid && (order.amountB != 0); // invalid order amountB

        valid = valid && (order.feeToken != address(0x0)); // invalid fee token



        valid = valid && (order.tokenSFeePercentage < ctx.feePercentageBase); // invalid tokenS percentage

        valid = valid && (order.tokenBFeePercentage < ctx.feePercentageBase); // invalid tokenB percentage

        valid = valid && (order.walletSplitPercentage <= 100); // invalid wallet split percentage



        // We only support ERC20 for now

        valid = valid && (order.tokenTypeS == Data.TokenType.ERC20 && order.trancheS == 0x0);

        valid = valid && (order.tokenTypeFee == Data.TokenType.ERC20);



        // NOTICE: replaced to allow orders to specify market's primary token (to denote order side)

        // valid = valid && (order.tokenTypeB == Data.TokenType.ERC20 && order.trancheB == 0x0);

        valid = valid && (order.tokenTypeB == Data.TokenType.ERC20) && (

            bytes32ToAddress(order.trancheB) == order.tokenB ||

            bytes32ToAddress(order.trancheB) == order.tokenS

        );



        // NOTICE: commented to allow order.transferDataS to be used for dApps building on Loopring

        // valid = valid && (order.transferDataS.length == 0);



        valid = valid && (order.validSince <= now); // order is too early to match



        order.valid = order.valid && valid;



        validateUnstableInfo(order, ctx);

    }





    function validateUnstableInfo(

        Data.Order memory order,

        Data.Context memory ctx

        )

        internal

        view

    {

        bool valid = true;

        valid = valid && (order.validUntil == 0 || order.validUntil > now);  // order is expired

        valid = valid && (order.waiveFeePercentage <= int16(ctx.feePercentageBase)); // invalid waive percentage

        valid = valid && (order.waiveFeePercentage >= -int16(ctx.feePercentageBase)); // invalid waive percentage

        if (order.dualAuthAddr != address(0x0)) { // if dualAuthAddr exists, dualAuthSig must be exist.

            valid = valid && (order.dualAuthSig.length > 0);

        }

        order.valid = order.valid && valid;

    }





    function checkP2P(

        Data.Order memory order

        )

        internal

        pure

    {

        order.P2P = (order.tokenSFeePercentage > 0 || order.tokenBFeePercentage > 0);

    }



    function isBuy(Data.Order memory order) internal pure returns (bool) {

        return bytes32ToAddress(order.trancheB) == order.tokenB;

    }



    function checkOwnerSignature(

        Data.Order memory order,

        Data.Context memory ctx

        )

        internal

        view

    {

        if (order.sig.length == 0) {

            bool registered = ctx.orderRegistry.isOrderHashRegistered(

                order.owner,

                order.hash

            );



            if (!registered) {

                order.valid = order.valid && ctx.orderBook.orderSubmitted(order.hash);

            }

        } else {

            order.valid = order.valid && MultihashUtil.verifySignature(

                order.owner,

                order.hash,

                order.sig

            );

            require(order.valid, 'INVALID_SIGNATURE');

        }

    }



    function checkDualAuthSignature(

        Data.Order memory order,

        bytes32 miningHash

        )

        internal

        pure

    {

        if (order.dualAuthSig.length != 0) {

            order.valid = order.valid && MultihashUtil.verifySignature(

                order.dualAuthAddr,

                miningHash,

                order.dualAuthSig

            );

            require(order.valid, 'INVALID_DUAL_AUTH_SIGNATURE');

        }

    }



    function validateAllOrNone(

        Data.Order memory order

        )

        internal

        pure

    {

        // Check if this order needs to be completely filled

        if(order.allOrNone) {

            order.valid = order.valid && (order.filledAmountS == order.amountS);

        }

    }



    function getBrokerHash(Data.Order memory order) internal pure returns (bytes32) {

        return keccak256(abi.encodePacked(order.broker, order.tokenS, order.tokenB, order.feeToken));

    }



    function getSpendableS(

        Data.Order memory order,

        Data.Context memory ctx

        )

        internal

        view

        returns (uint)

    {

        return getSpendable(

            order,

            ctx.delegate,

            order.tokenS,

            order.owner,

            order.tokenSpendableS

        );

    }



    function getSpendableFee(

        Data.Order memory order,

        Data.Context memory ctx

        )

        internal

        view

        returns (uint)

    {

        return getSpendable(

            order,

            ctx.delegate,

            order.feeToken,

            order.owner,

            order.tokenSpendableFee

        );

    }



    function reserveAmountS(

        Data.Order memory order,

        uint amount

        )

        internal

        pure

    {

        order.tokenSpendableS.reserved += amount;

    }



    function reserveAmountFee(

        Data.Order memory order,

        uint amount

        )

        internal

        pure

    {

        order.tokenSpendableFee.reserved += amount;

    }



    function resetReservations(

        Data.Order memory order

        )

        internal

        pure

    {

        order.tokenSpendableS.reserved = 0;

        order.tokenSpendableFee.reserved = 0;

    }



    /// @return Amount of ERC20 token that can be spent by this contract.

    function getERC20Spendable(

        Data.Order memory order,

        ITradeDelegate delegate,

        address tokenAddress,

        address owner

        )

        private

        view

        returns (uint spendable)

    {

        if (order.broker == address(0x0)) {

            ERC20 token = ERC20(tokenAddress);

            spendable = token.allowance(

                owner,

                address(delegate)

            );

            if (spendable != 0) {

                uint balance = token.balanceOf(owner);

                spendable = (balance < spendable) ? balance : spendable;

            }

        } else {

            IBrokerDelegate broker = IBrokerDelegate(order.broker);

            spendable = broker.brokerBalanceOf(owner, tokenAddress);

        }

    }



    function getSpendable(

        Data.Order memory order,

        ITradeDelegate delegate,

        address tokenAddress,

        address owner,

        Data.Spendable memory tokenSpendable

        )

        private

        view

        returns (uint spendable)

    {

        if (!tokenSpendable.initialized) {

            tokenSpendable.amount = getERC20Spendable(

                order,

                delegate,

                tokenAddress,

                owner

            );

            tokenSpendable.initialized = true;

        }

        spendable = tokenSpendable.amount.sub(tokenSpendable.reserved);

    }



    function bytes32ToAddress(bytes32 data) private pure returns (address) {

        return address(uint160(uint256(data)));

    }

}



// File: contracts/iface/IRingSubmitter.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;




/// @title IRingSubmitter

/// @author Daniel Wang - <daniel@loopring.org>

/// @author Kongliang Zhong - <kongliang@loopring.org>

contract IRingSubmitter {

    uint16  public constant FEE_PERCENTAGE_BASE = 1000;



    /// @dev  Event emitted when a ring was successfully mined

    ///        _ringIndex     The index of the ring

    ///        _ringHash      The hash of the ring

    ///        _feeRecipient  The recipient of the matching fee

    ///        _fills         The info of the orders in the ring stored like:

    ///                       [orderHash, owner, tokenS, amountS, split, feeAmount, feeAmountS, feeAmountB]

    event RingMined(

        uint            _ringIndex,

        bytes32 indexed _ringHash,

        address indexed _feeRecipient,

        bytes           _fills

    );



    /// @dev   Event emitted when a ring was not successfully mined

    ///         _ringHash  The hash of the ring

    event InvalidRing(

        bytes32 _ringHash

    );



    /// @dev   Event emitted when fee rebates are distributed (waiveFeePercentage < 0)

    ///         _ringHash   The hash of the ring whose order(s) will receive the rebate

    ///         _orderHash  The hash of the order that will receive the rebate

    ///         _feeToken   The address of the token that will be paid to the _orderHash's owner

    ///         _feeAmount  The amount to be paid to the owner

    event DistributeFeeRebate(

        bytes32 indexed _ringHash,

        bytes32 indexed _orderHash,

        address         _feeToken,

        uint            _feeAmount

    );



    /// @dev   Submit order-rings for validation and settlement.

    /// @param data Packed data of all rings.

    function submitRings(

        bytes calldata data

        )

        external;

}



// File: contracts/helper/ParticipationHelper.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;










/// @title ParticipationHelper

/// @author Daniel Wang - <daniel@loopring.org>.

library ParticipationHelper {

    using MathUint for uint;

    using OrderHelper for Data.Order;



    function setMaxFillAmounts(

        Data.Participation memory p,

        Data.Context memory ctx

        )

        internal

        view

    {

        uint spendableS = p.order.getSpendableS(ctx);

        uint remainingS = p.order.amountS.sub(p.order.filledAmountS);

        p.fillAmountS = (spendableS < remainingS) ? spendableS : remainingS;



        if (!p.order.P2P) {

            // No need to check the fee balance of the owner if feeToken == tokenB,

            // fillAmountB will be used to pay the fee.

            if (!(p.order.feeToken == p.order.tokenB &&

                  // p.order.owner == p.order.tokenRecipient &&

                  p.order.feeAmount <= p.order.amountB)) {

                // Check how much fee needs to be paid. We limit fillAmountS to how much

                // fee the order owner can pay.

                uint feeAmount = p.order.feeAmount.mul(p.fillAmountS) / p.order.amountS;

                if (feeAmount > 0) {

                    uint spendableFee = p.order.getSpendableFee(ctx);

                    if (p.order.feeToken == p.order.tokenS && p.fillAmountS + feeAmount > spendableS) {

                        assert(spendableFee == spendableS);

                        // Equally divide the available tokens between fillAmountS and feeAmount

                        uint totalAmount = p.order.amountS.add(p.order.feeAmount);

                        p.fillAmountS = spendableS.mul(p.order.amountS) / totalAmount;

                        feeAmount = spendableS.mul(p.order.feeAmount) / totalAmount;

                    } else if (feeAmount > spendableFee) {

                        // Scale down fillAmountS so the available feeAmount is sufficient

                        feeAmount = spendableFee;

                        p.fillAmountS = feeAmount.mul(p.order.amountS) / p.order.feeAmount;

                    }

                }

            }

        }



        p.fillAmountB = p.fillAmountS.mul(p.order.amountB) / p.order.amountS;



        // If relayer sets max primary fill amount, rebalance max fill amounts if needed

        if (p.order.maxPrimaryFillAmount > 0) {

            if (p.order.isBuy() && p.order.maxPrimaryFillAmount < p.fillAmountB) {

                p.fillAmountB = p.order.maxPrimaryFillAmount;

                p.fillAmountS = p.fillAmountB.mul(p.order.amountS) / p.order.amountB;

            } else if (!p.order.isBuy() && p.order.maxPrimaryFillAmount < p.fillAmountS) {

                p.fillAmountS = p.order.maxPrimaryFillAmount;

                p.fillAmountB = p.fillAmountS.mul(p.order.amountB) / p.order.amountS;

            }

        }

    }



    function calculateFees(

        Data.Participation memory p,

        Data.Participation memory prevP,

        Data.Context memory ctx

        )

        internal

        view

        returns (bool)

    {

        if (p.order.P2P) {

            // Calculate P2P fees

            p.feeAmount = 0;

            p.feeAmountS = p.fillAmountS.mul(p.order.tokenSFeePercentage) / ctx.feePercentageBase;

            p.feeAmountB = p.fillAmountB.mul(p.order.tokenBFeePercentage) / ctx.feePercentageBase;

        } else {

            // Calculate matching fees

            p.feeAmountS = 0;

            p.feeAmountB = 0;



            // Use primary token fill ratio to calculate fee

            // if it's a BUY order, use the amount B (tokenB is the primary)

            // if it's a SELL order, use the amount S (tokenS is the primary)

            if (p.order.isBuy()) {

                p.feeAmount = p.order.feeAmount.mul(p.fillAmountB) / p.order.amountB;

            } else {

                p.feeAmount = p.order.feeAmount.mul(p.fillAmountS) / p.order.amountS;

            }



            // If feeToken == tokenB AND owner == tokenRecipient, try to pay using fillAmountB



            if (p.order.feeToken == p.order.tokenB &&

                // p.order.owner == p.order.tokenRecipient &&

                p.fillAmountB >= p.feeAmount) {

                p.feeAmountB = p.feeAmount;

                p.feeAmount = 0;

            }



            if (p.feeAmount > 0) {

                // Make sure we can pay the feeAmount

                uint spendableFee = p.order.getSpendableFee(ctx);

                if (p.feeAmount > spendableFee) {

                    // This normally should not happen, but this is possible when self-trading

                    return false;

                } else {

                    p.order.reserveAmountFee(p.feeAmount);

                }

            }

        }



        if ((p.fillAmountS - p.feeAmountS) >= prevP.fillAmountB) {

            // NOTICE: this line commented as order recipient should receive the margin

            // p.splitS = (p.fillAmountS - p.feeAmountS) - prevP.fillAmountB;



            p.fillAmountS = prevP.fillAmountB + p.feeAmountS;

            return true;

        } else {

            revert('INVALID_FEES');

            // return false;

        }

    }



    function checkFills(

        Data.Participation memory p

        )

        internal

        pure

        returns (bool valid)

    {

        // NOTICE: deprecated logic, order recipient can get better price as they receive margin

        // Check if the rounding error of the calculated fillAmountB is larger than 1%.

        // If that's the case, this partipation in invalid

        // p.fillAmountB := p.fillAmountS.mul(p.order.amountB) / p.order.amountS

        // valid = !MathUint.hasRoundingError(

        //     p.fillAmountS,

        //     p.order.amountB,

        //     p.order.amountS

        // );



        // We at least need to buy and sell something

        valid = p.fillAmountS > 0;

        valid = valid && p.fillAmountB > 0;



        require(valid, 'INVALID_FILLS');

    }



    function adjustOrderState(

        Data.Participation memory p

        )

        internal

        pure

    {

        // Update filled amount

        p.order.filledAmountS += p.fillAmountS + p.splitS;



        // Update spendables

        uint totalAmountS = p.fillAmountS;

        uint totalAmountFee = p.feeAmount;

        p.order.tokenSpendableS.amount = p.order.tokenSpendableS.amount.sub(totalAmountS);

        p.order.tokenSpendableFee.amount = p.order.tokenSpendableFee.amount.sub(totalAmountFee);

    }



    function revertOrderState(

        Data.Participation memory p

        )

        internal

        pure

    {

        // Revert filled amount

        p.order.filledAmountS = p.order.filledAmountS.sub(p.fillAmountS + p.splitS);



        // We do not revert any spendables. Rings will not get rebalanced so this doesn't matter.

    }



}



// File: contracts/helper/RingHelper.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;


















/// @title RingHelper

library RingHelper {

    using MathUint for uint;

    using OrderHelper for Data.Order;

    using ParticipationHelper for Data.Participation;



    /// @dev   Event emitted when fee rebates are distributed (waiveFeePercentage < 0)

    ///         _ringHash   The hash of the ring whose order(s) will receive the rebate

    ///         _orderHash  The hash of the order that will receive the rebate

    ///         _feeToken   The address of the token that will be paid to the _orderHash's owner

    ///         _feeAmount  The amount to be paid to the owner

    event DistributeFeeRebate(

        bytes32 indexed _ringHash,

        bytes32 indexed _orderHash,

        address         _feeToken,

        uint            _feeAmount

    );



    function updateHash(

        Data.Ring memory ring

        )

        internal

        pure

    {

        uint ringSize = ring.size;

        bytes32 hash;

        assembly {

            let data := mload(0x40)

            let ptr := data

            let participations := mload(add(ring, 32))                                  // ring.participations

            for { let i := 0 } lt(i, ringSize) { i := add(i, 1) } {

                let participation := mload(add(participations, add(32, mul(i, 32))))    // participations[i]

                let order := mload(participation)                                       // participation.order



                let waiveFeePercentage := and(mload(add(order, 672)), 0xFFFF)           // order.waiveFeePercentage

                let orderHash := mload(add(order, 864))                                 // order.hash



                mstore(add(ptr, 2), waiveFeePercentage)

                mstore(ptr, orderHash)



                ptr := add(ptr, 34)

            }

            hash := keccak256(data, sub(ptr, data))

        }

        ring.hash = hash;

    }



    function calculateFillAmountAndFee(

        Data.Ring memory ring,

        Data.Context memory ctx

        )

        internal

        view

    {

        // Invalid order data could cause a divide by zero in the calculations

        if (!ring.valid) {

            return;

        }



        uint i;

        uint prevIndex;



        for (i = 0; i < ring.size; i++) {

            ring.participations[i].setMaxFillAmounts(

                ctx

            );

        }



        // Match the orders

        Data.Participation memory taker = ring.participations[0];

        Data.Participation memory maker = ring.participations[1];



        if (taker.order.isBuy()) {

            uint spread = matchRing(taker, maker);

            taker.fillAmountS = maker.fillAmountB; // For BUY orders owner can sell less to get what is wanted (keeps spread)

            taker.splitS = spread;

        } else {

            matchRing(maker, taker);

            taker.fillAmountB = maker.fillAmountS; // For SELL orders owner sells max and can get more than expected (spends spread)

            taker.splitS = 0;

        }



        maker.splitS = 0;



        // Validate matched orders

        for (i = 0; i < ring.size; i++) {

            // Check if the fill amounts of the participation are valid

            ring.valid = ring.valid && ring.participations[i].checkFills();



            // Reserve the total amount tokenS used for all the orders

            // (e.g. the owner of order 0 could use LRC as feeToken in order 0, while

            // the same owner can also sell LRC in order 2).

            ring.participations[i].order.reserveAmountS(ring.participations[i].fillAmountS);

        }



        for (i = 0; i < ring.size; i++) {

            prevIndex = (i + ring.size - 1) % ring.size;



            bool valid = ring.participations[i].calculateFees(ring.participations[prevIndex], ctx);

            if (!valid) {

                ring.valid = false;

                break;

            }



            int16 waiveFeePercentage = ring.participations[i].order.waiveFeePercentage;

            if (waiveFeePercentage < 0) {

                ring.minerFeesToOrdersPercentage += uint(-waiveFeePercentage);

            }

        }

        // Miner can only distribute 100% of its fees to all orders combined

        ring.valid = ring.valid && (ring.minerFeesToOrdersPercentage <= ctx.feePercentageBase);



        // Ring calculations are done. Make sure te remove all spendable reservations for this ring

        for (i = 0; i < ring.size; i++) {

            ring.participations[i].order.resetReservations();

        }

    }



    function matchRing(

        Data.Participation memory buyer,

        Data.Participation memory seller

        )

        internal

        pure

        returns (uint)

    {

        if (buyer.fillAmountB < seller.fillAmountS) {

            // Amount seller wants less than amount maker sells

            seller.fillAmountS = buyer.fillAmountB;

            seller.fillAmountB = seller.fillAmountS.mul(seller.order.amountB) / seller.order.amountS;

        } else {

            buyer.fillAmountB = seller.fillAmountS;

            buyer.fillAmountS = buyer.fillAmountB.mul(buyer.order.amountS) / buyer.order.amountB;

        }



        require(buyer.fillAmountS >= seller.fillAmountB, "NOT-MATCHABLE");

        return buyer.fillAmountS.sub(seller.fillAmountB); // Return spread

    }



    function calculateOrderFillAmounts(

        Data.Context memory ctx,

        Data.Participation memory p,

        Data.Participation memory prevP,

        uint i,

        uint smallest

        )

        internal

        pure

        returns (uint smallest_)

    {

        // Default to the same smallest index

        smallest_ = smallest;



        uint postFeeFillAmountS = p.fillAmountS;

        uint tokenSFeePercentage = p.order.tokenSFeePercentage;

        if (tokenSFeePercentage > 0) {

            uint feeAmountS = p.fillAmountS.mul(tokenSFeePercentage) / ctx.feePercentageBase;

            postFeeFillAmountS = p.fillAmountS - feeAmountS;

        }



        if (prevP.fillAmountB > postFeeFillAmountS) {

            smallest_ = i;

            prevP.fillAmountB = postFeeFillAmountS;

            prevP.fillAmountS = postFeeFillAmountS.mul(prevP.order.amountS) / prevP.order.amountB;

        }

    }



    function checkOrdersValid(

        Data.Ring memory ring

        )

        internal

        pure

    {

        // NOTICE: deprecated logic, rings must be of size 2 now

        // ring.valid = ring.valid && (ring.size > 1 && ring.size <= 8); // invalid ring size

        

        ring.valid = ring.valid && ring.size == 2;



        // Ring must consist of a buy and a sell

        ring.valid = ring.valid && (

            (ring.participations[0].order.isBuy() && !ring.participations[1].order.isBuy()) ||

            (ring.participations[1].order.isBuy() && !ring.participations[0].order.isBuy())

        );



        for (uint i = 0; i < ring.size; i++) {

            uint prev = (i + ring.size - 1) % ring.size;

            ring.valid = ring.valid && ring.participations[i].order.valid;

            ring.valid = ring.valid && ring.participations[i].order.tokenS == ring.participations[prev].order.tokenB;

            ring.valid = ring.valid && !ring.participations[i].order.P2P; // No longer support P2P orders

        }

    }



    function checkForSubRings(

        Data.Ring memory ring

        )

        internal

        pure

    {

        for (uint i = 0; i < ring.size - 1; i++) {

            address tokenS = ring.participations[i].order.tokenS;

            for (uint j = i + 1; j < ring.size; j++) {

                ring.valid = ring.valid && (tokenS != ring.participations[j].order.tokenS);

            }

        }

    }



    function adjustOrderStates(

        Data.Ring memory ring

        )

        internal

        pure

    {

        // Adjust the orders

        for (uint i = 0; i < ring.size; i++) {

            ring.participations[i].adjustOrderState();

        }

    }





    function revertOrderStats(

        Data.Ring memory ring

        )

        internal

        pure

    {

        for (uint i = 0; i < ring.size; i++) {

            ring.participations[i].revertOrderState();

        }

    }



    function doPayments(

        Data.Ring memory ring,

        Data.Context memory ctx,

        Data.Mining memory mining

        )

        internal

    {

        payFees(ring, ctx, mining);

        transferTokens(ring, ctx, mining.feeRecipient);

    }



    function generateFills(

        Data.Ring memory ring,

        uint destPtr

        )

        internal

        pure

        returns (uint fill)

    {

        uint ringSize = ring.size;

        uint fillSize = 8 * 32;

        assembly {

            fill := destPtr

            let participations := mload(add(ring, 32))                                 // ring.participations



            for { let i := 0 } lt(i, ringSize) { i := add(i, 1) } {

                let participation := mload(add(participations, add(32, mul(i, 32))))   // participations[i]

                let order := mload(participation)                                      // participation.order



                // Calculate the actual fees paid after rebate

                let feeAmount := sub(

                    mload(add(participation, 64)),                                      // participation.feeAmount

                    mload(add(participation, 160))                                      // participation.rebateFee

                )

                let feeAmountS := sub(

                    mload(add(participation, 96)),                                      // participation.feeAmountS

                    mload(add(participation, 192))                                      // participation.rebateFeeS

                )

                let feeAmountB := sub(

                    mload(add(participation, 128)),                                     // participation.feeAmountB

                    mload(add(participation, 224))                                      // participation.rebateFeeB

                )



                mstore(add(fill,   0), mload(add(order, 864)))                         // order.hash

                mstore(add(fill,  32), mload(add(order,  32)))                         // order.owner

                mstore(add(fill,  64), mload(add(order,  64)))                         // order.tokenS

                mstore(add(fill,  96), mload(add(participation, 256)))                 // participation.fillAmountS

                mstore(add(fill, 128), mload(add(participation,  32)))                 // participation.splitS

                mstore(add(fill, 160), feeAmount)                                      // feeAmount

                mstore(add(fill, 192), feeAmountS)                                     // feeAmountS

                mstore(add(fill, 224), feeAmountB)                                     // feeAmountB



                fill := add(fill, fillSize)

            }

        }

    }



    function transferTokens(

        Data.Ring memory ring,

        Data.Context memory ctx,

        address feeRecipient

        )

        internal

        pure

    {

        Data.Participation memory taker = ring.participations[0];

        Data.Participation memory maker = ring.participations[1];



        if (maker.order.transferFirstAsMaker) {

            transferTokensForParticipation(ctx, feeRecipient, maker, taker);

            transferTokensForParticipation(ctx, feeRecipient, taker, maker);

        } else {

            transferTokensForParticipation(ctx, feeRecipient, taker, maker);

            transferTokensForParticipation(ctx, feeRecipient, maker, taker);

        }

    }



    function transferTokensForParticipation(

        Data.Context memory ctx,

        address feeRecipient,

        Data.Participation memory p,

        Data.Participation memory prevP

        )

        internal

        pure

        returns (uint)

    {

        // If the buyer needs to pay fees in tokenB, the seller needs

        // to send the tokenS amount to the fee holder contract

        uint amountSToBuyer = p.fillAmountS

            .sub(p.feeAmountS)

            .sub(prevP.feeAmountB.sub(prevP.rebateB)); // buyer fee amount after rebate



        uint amountSToFeeHolder = p.feeAmountS

            .sub(p.rebateS)

            .add(prevP.feeAmountB.sub(prevP.rebateB)); // buyer fee amount after rebate



        uint amountFeeToFeeHolder = p.feeAmount

            .sub(p.rebateFee);





        if (p.order.tokenS == p.order.feeToken) {

            amountSToFeeHolder = amountSToFeeHolder.add(amountFeeToFeeHolder);

            amountFeeToFeeHolder = 0;

        }



        // Transfers

        if (p.order.broker == address(0x0)) {

            ctx.transferPtr = addTokenTransfer(

                ctx.transferData,

                ctx.transferPtr,

                p.order.tokenS,

                p.order.owner,

                prevP.order.tokenRecipient,

                amountSToBuyer

            );



            ctx.transferPtr = addTokenTransfer(

                ctx.transferData,

                ctx.transferPtr,

                p.order.feeToken,

                p.order.owner,

                address(ctx.feeHolder),

                amountFeeToFeeHolder

            );



            ctx.transferPtr = addTokenTransfer(

                ctx.transferData,

                ctx.transferPtr,

                p.order.tokenS,

                p.order.owner,

                address(ctx.feeHolder),

                amountSToFeeHolder

            );

        } else {

            

            // Calculates amount received from other participant

            uint receivableAmountB = prevP.fillAmountS

                .sub(prevP.feeAmountS)

                .sub(p.feeAmountB.sub(p.rebateB)); // seller fee amount after rebate



            addBrokerTokenTransfer(

                ctx,

                p,

                receivableAmountB, // receivable amount incremented/set in called function for order

                p.order.tokenS,

                prevP.order.tokenRecipient,

                amountSToBuyer,

                false

            );



            addBrokerTokenTransfer(

                ctx,

                p,

                0, // receivable amount set to 0 for fee transfers

                p.order.feeToken,

                address(ctx.feeHolder),

                amountFeeToFeeHolder,

                true // this transfer concerns the fee token

            );



            addBrokerTokenTransfer(

                ctx,

                p,

                0, // receivable amount set to 0 for fee transfers

                p.order.tokenS,

                address(ctx.feeHolder),

                amountSToFeeHolder,

                false

            );

        }

        



        // NOTICE: Dolomite does not take the margin ever. We still track it for the order's history.

        // ctx.transferPtr = addTokenTransfer(

        //     ctx.transferData,

        //     ctx.transferPtr,

        //     p.order.tokenS,

        //     p.order.owner,

        //     feeRecipient,

        //     p.splitS

        // );

    }



    function addBrokerTokenTransfer(

        Data.Context memory ctx,

        Data.Participation memory participation,

        uint receivableAmount,

        address requestToken, 

        address recipient,

        uint requestAmount,

        bool isForFeeToken

    )

        internal

        pure

    {

        if (requestAmount > 0) {

            bytes32 actionHash = participation.order.getBrokerHash();

            bytes32 transferHash = keccak256(abi.encodePacked(actionHash, requestToken, recipient));

            

            Data.BrokerAction memory action;

            bool isActionNewlyCreated = false;



            uint index = 0;

            bool found = false;



            // Find a preexisting BrokerAction

            for (index = 0; index < ctx.numBrokerActions; index++) {

                if (ctx.brokerActions[index].hash == actionHash) {

                    action = ctx.brokerActions[index];

                    found = true;

                    break;

                }

            }



            // If none exist, create a new BrokerAction

            if (!found) {

                action = Data.BrokerAction({

                    hash: actionHash,

                    broker: participation.order.broker,

                    orderIndices: new uint[](ctx.brokerOrders.length),

                    numOrders: 0,

                    transferIndices: new uint[](ctx.brokerTransfers.length * 3),

                    numTransfers: 0,

                    tokenS: participation.order.tokenS,

                    tokenB: participation.order.tokenB,

                    feeToken: participation.order.feeToken

                });

                ctx.brokerActions[ctx.numBrokerActions] = action;

                ctx.numBrokerActions += 1;

                isActionNewlyCreated = true;

            } else {

                found = false;

            }



            // Find a preexisting BrokerOrder for the participant's order from those registered with the action

            if (!isActionNewlyCreated) {

                for (index = 0; index < action.numOrders; index++) {

                    if (ctx.brokerOrders[action.orderIndices[index]].orderHash == participation.order.hash) {

                        Data.BrokerOrder memory brokerOrder = ctx.brokerOrders[action.orderIndices[index]];

                        brokerOrder.fillAmountB += receivableAmount;

                        

                        if (isForFeeToken) {

                            brokerOrder.requestedFeeAmount += requestAmount;

                        } else {

                            brokerOrder.requestedAmountS += requestAmount;

                        }



                        found = true;

                        break;

                    }

                }

            }

            

            // If none exist, create a new BrokerOrder

            if (!found) {

                ctx.brokerOrders[ctx.numBrokerOrders] = Data.BrokerOrder({

                    owner: participation.order.owner,

                    orderHash: participation.order.hash,

                    fillAmountB: receivableAmount,

                    requestedAmountS: isForFeeToken ? 0 : requestAmount,

                    requestedFeeAmount: isForFeeToken ? requestAmount : 0,

                    tokenRecipient: participation.order.tokenRecipient,

                    extraData: participation.order.transferDataS

                });

                action.orderIndices[action.numOrders] = ctx.numBrokerOrders;

                action.numOrders += 1;

                ctx.numBrokerOrders += 1;

            } else {

                found = false;

            }



            // Find a preexisting BrokerTransfer from those registered with the action

            if (!isActionNewlyCreated) {

                for (index = 0; index < action.numTransfers; index++) {

                    if (ctx.brokerTransfers[action.transferIndices[index]].hash == transferHash) {

                        Data.BrokerTransfer memory transfer = ctx.brokerTransfers[action.transferIndices[index]];

                        transfer.amount += requestAmount;

                        found = true;

                        break;

                    }

                }

            }



            // If none exist, create a new BrokerTransfer

            if (!found) {

                ctx.brokerTransfers[ctx.numBrokerTransfers] = Data.BrokerTransfer(transferHash, requestToken, requestAmount, recipient);

                action.transferIndices[action.numTransfers] = ctx.numBrokerTransfers;

                action.numTransfers += 1;

                ctx.numBrokerTransfers += 1;

            }

        }

    }



    function addTokenTransfer(

        uint data,

        uint ptr,

        address token,

        address from,

        address to,

        uint amount

        )

        internal

        pure

        returns (uint)

    {

        if (amount > 0 && from != to) {

            assembly {

                // Try to find an existing fee payment of the same token to the same owner

                let addNew := 1

                for { let p := data } lt(p, ptr) { p := add(p, 128) } {

                    let dataToken := mload(add(p,  0))

                    let dataFrom := mload(add(p, 32))

                    let dataTo := mload(add(p, 64))

                    // if(token == dataToken && from == dataFrom && to == dataTo)

                    if and(and(eq(token, dataToken), eq(from, dataFrom)), eq(to, dataTo)) {

                        let dataAmount := mload(add(p, 96))

                        // dataAmount = amount.add(dataAmount);

                        dataAmount := add(amount, dataAmount)

                        // require(dataAmount >= amount) (safe math)

                        if lt(dataAmount, amount) {

                            revert(0, 0)

                        }

                        mstore(add(p, 96), dataAmount)

                        addNew := 0

                        // End the loop

                        p := ptr

                    }

                }

                // Add a new transfer

                if eq(addNew, 1) {

                    mstore(add(ptr,  0), token)

                    mstore(add(ptr, 32), from)

                    mstore(add(ptr, 64), to)

                    mstore(add(ptr, 96), amount)

                    ptr := add(ptr, 128)

                }

            }

            return ptr;

        } else {

            return ptr;

        }

    }



    function payFees(

        Data.Ring memory ring,

        Data.Context memory ctx,

        Data.Mining memory mining

        )

        internal

    {

        Data.FeeContext memory feeCtx;

        feeCtx.ring = ring;

        feeCtx.ctx = ctx;

        feeCtx.feeRecipient = mining.feeRecipient;

        for (uint i = 0; i < ring.size; i++) {

            payFeesForParticipation(

                feeCtx,

                ring.participations[i]

            );

        }

    }



    function payFeesForParticipation(

        Data.FeeContext memory feeCtx,

        Data.Participation memory p

        )

        internal

        returns (uint)

    {

        feeCtx.walletPercentage = p.order.P2P ? 100 : (

            (p.order.wallet == address(0x0) ? 0 : p.order.walletSplitPercentage)

        );

        feeCtx.waiveFeePercentage = p.order.waiveFeePercentage;

        feeCtx.owner = p.order.owner;

        feeCtx.wallet = p.order.wallet;

        feeCtx.P2P = p.order.P2P;



        p.rebateFee = payFeesAndBurn(

            feeCtx,

            p.order.feeToken,

            p.feeAmount

        );

        p.rebateS = payFeesAndBurn(

            feeCtx,

            p.order.tokenS,

            p.feeAmountS

        );

        p.rebateB = payFeesAndBurn(

            feeCtx,

            p.order.tokenB,

            p.feeAmountB

        );

    }



    function payFeesAndBurn(

        Data.FeeContext memory feeCtx,

        address token,

        uint totalAmount

        )

        internal

        returns (uint)

    {

        if (totalAmount == 0) {

            return 0;

        }



        uint amount = totalAmount;

        // No need to pay any fees in a P2P order without a wallet

        // (but the fee amount is a part of amountS of the order, so the fee amount is rebated).

        if (feeCtx.P2P && feeCtx.wallet == address(0x0)) {

            amount = 0;

        }



        uint feeToWallet = 0;

        uint minerFee = 0;

        uint minerFeeBurn = 0;

        uint walletFeeBurn = 0;

        if (amount > 0) {

            feeToWallet = amount.mul(feeCtx.walletPercentage) / 100;

            minerFee = amount - feeToWallet;



            // Miner can waive fees for this order. If waiveFeePercentage > 0 this is a simple reduction in fees.

            if (feeCtx.waiveFeePercentage > 0) {

                minerFee = minerFee.mul(

                    feeCtx.ctx.feePercentageBase - uint(feeCtx.waiveFeePercentage)) /

                    feeCtx.ctx.feePercentageBase;

            } else if (feeCtx.waiveFeePercentage < 0) {

                // No fees need to be paid by this order

                minerFee = 0;

            }



            uint32 burnRate = getBurnRate(feeCtx, token);

            assert(burnRate <= feeCtx.ctx.feePercentageBase);



            // Miner fee

            minerFeeBurn = minerFee.mul(burnRate) / feeCtx.ctx.feePercentageBase;

            minerFee = minerFee - minerFeeBurn;

            // Wallet fee

            walletFeeBurn = feeToWallet.mul(burnRate) / feeCtx.ctx.feePercentageBase;

            feeToWallet = feeToWallet - walletFeeBurn;



            // Pay the wallet

            feeCtx.ctx.feePtr = addFeePayment(

                feeCtx.ctx.feeData,

                feeCtx.ctx.feePtr,

                token,

                feeCtx.wallet,

                feeToWallet

            );



            // Pay the burn rate with the feeHolder as owner

            feeCtx.ctx.feePtr = addFeePayment(

                feeCtx.ctx.feeData,

                feeCtx.ctx.feePtr,

                token,

                address(feeCtx.ctx.feeHolder),

                minerFeeBurn + walletFeeBurn

            );



            // Fees can be paid out in different tokens so we can't easily accumulate the total fee

            // that needs to be paid out to order owners. So we pay out each part out here to all

            // orders that need it.

            uint feeToMiner = minerFee;

            if (feeCtx.ring.minerFeesToOrdersPercentage > 0 && minerFee > 0) {

                // Pay out the fees to the orders

                distributeMinerFeeToOwners(

                    feeCtx,

                    token,

                    minerFee

                );

                // Subtract all fees the miner pays to the orders

                feeToMiner = minerFee.mul(feeCtx.ctx.feePercentageBase -

                    feeCtx.ring.minerFeesToOrdersPercentage) /

                    feeCtx.ctx.feePercentageBase;

            }



            // Pay the miner

            feeCtx.ctx.feePtr = addFeePayment(

                feeCtx.ctx.feeData,

                feeCtx.ctx.feePtr,

                token,

                feeCtx.feeRecipient,

                feeToMiner

            );

        }



        // Calculate the total fee payment after possible discounts (burn rebate + fee waiving)

        // and return the total rebate

        return totalAmount.sub((feeToWallet + minerFee) + (minerFeeBurn + walletFeeBurn));

    }



    function getBurnRate(

        Data.FeeContext memory feeCtx,

        address token

        )

        internal

        view

        returns (uint32)

    {

        bytes32[] memory tokenBurnRates = feeCtx.ctx.tokenBurnRates;

        uint length = tokenBurnRates.length;

        for (uint i = 0; i < length; i += 2) {

            if (token == address(bytes20(tokenBurnRates[i]))) {

                uint32 burnRate = uint32(bytes4(tokenBurnRates[i + 1]));

                return feeCtx.P2P ? (burnRate / 0x10000) : (burnRate & 0xFFFF);

            }

        }

        // Not found, add it to the list

        uint32 burnRate = feeCtx.ctx.burnRateTable.getBurnRate(token);

        assembly {

            let ptr := add(tokenBurnRates, mul(add(1, length), 32))

            mstore(ptr, token)                              // token

            mstore(add(ptr, 32), burnRate)                  // burn rate

            mstore(tokenBurnRates, add(length, 2))          // length

        }

        return feeCtx.P2P ? (burnRate / 0x10000) : (burnRate & 0xFFFF);

    }



    function distributeMinerFeeToOwners(

        Data.FeeContext memory feeCtx,

        address token,

        uint minerFee

        )

        internal

    {

        for (uint i = 0; i < feeCtx.ring.size; i++) {

            if (feeCtx.ring.participations[i].order.waiveFeePercentage < 0) {

                uint feeToOwner = minerFee

                    .mul(uint(-feeCtx.ring.participations[i].order.waiveFeePercentage)) / feeCtx.ctx.feePercentageBase;



                emit DistributeFeeRebate(feeCtx.ring.hash, feeCtx.ring.participations[i].order.hash, token, feeToOwner);



                feeCtx.ctx.feePtr = addFeePayment(

                    feeCtx.ctx.feeData,

                    feeCtx.ctx.feePtr,

                    token,

                    feeCtx.ring.participations[i].order.owner,

                    feeToOwner);

            }

        }

    }



    function addFeePayment(

        uint data,

        uint ptr,

        address token,

        address owner,

        uint amount

        )

        internal

        pure

        returns (uint)

    {

        if (amount == 0) {

            return ptr;

        } else {

            assembly {

                // Try to find an existing fee payment of the same token to the same owner

                let addNew := 1

                for { let p := data } lt(p, ptr) { p := add(p, 96) } {

                    let dataToken := mload(add(p,  0))

                    let dataOwner := mload(add(p, 32))

                    // if(token == dataToken && owner == dataOwner)

                    if and(eq(token, dataToken), eq(owner, dataOwner)) {

                        let dataAmount := mload(add(p, 64))

                        // dataAmount = amount.add(dataAmount);

                        dataAmount := add(amount, dataAmount)

                        // require(dataAmount >= amount) (safe math)

                        if lt(dataAmount, amount) {

                            revert(0, 0)

                        }

                        mstore(add(p, 64), dataAmount)

                        addNew := 0

                        // End the loop

                        p := ptr

                    }

                }

                // Add a new fee payment

                if eq(addNew, 1) {

                    mstore(add(ptr,  0), token)

                    mstore(add(ptr, 32), owner)

                    mstore(add(ptr, 64), amount)

                    ptr := add(ptr, 96)

                }

            }

            return ptr;

        }

    }



}



// File: contracts/iface/Errors.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;




/// @title Errors

contract Errors {

    string constant ZERO_VALUE                 = "ZERO_VALUE";

    string constant ZERO_ADDRESS               = "ZERO_ADDRESS";

    string constant INVALID_VALUE              = "INVALID_VALUE";

    string constant INVALID_ADDRESS            = "INVALID_ADDRESS";

    string constant INVALID_SIZE               = "INVALID_SIZE";

    string constant INVALID_SIG                = "INVALID_SIG";

    string constant INVALID_STATE              = "INVALID_STATE";

    string constant NOT_FOUND                  = "NOT_FOUND";

    string constant ALREADY_EXIST              = "ALREADY_EXIST";

    string constant REENTRY                    = "REENTRY";

    string constant UNAUTHORIZED               = "UNAUTHORIZED";

    string constant UNIMPLEMENTED              = "UNIMPLEMENTED";

    string constant UNSUPPORTED                = "UNSUPPORTED";

    string constant TRANSFER_FAILURE           = "TRANSFER_FAILURE";

    string constant WITHDRAWAL_FAILURE         = "WITHDRAWAL_FAILURE";

    string constant BURN_FAILURE               = "BURN_FAILURE";

    string constant BURN_RATE_FROZEN           = "BURN_RATE_FROZEN";

    string constant BURN_RATE_MINIMIZED        = "BURN_RATE_MINIMIZED";

    string constant UNAUTHORIZED_ONCHAIN_ORDER = "UNAUTHORIZED_ONCHAIN_ORDER";

    string constant INVALID_CANDIDATE          = "INVALID_CANDIDATE";

    string constant ALREADY_VOTED              = "ALREADY_VOTED";

    string constant NOT_OWNER                  = "NOT_OWNER";

}



// File: contracts/lib/NoDefaultFunc.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;






/// @title NoDefaultFunc

/// @dev Disable default functions.

contract NoDefaultFunc is Errors {

    function ()

        external

        payable

    {

        revert(UNSUPPORTED);

    }

}



// File: contracts/lib/ERC20SafeTransfer.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;




/// @title ERC20 safe transfer

/// @dev see https://github.com/sec-bit/badERC20Fix

/// @author Brecht Devos - <brecht@loopring.org>

library ERC20SafeTransfer {



    function safeTransfer(

        address token,

        address to,

        uint256 value)

        internal

        returns (bool success)

    {

        // A transfer is successful when 'call' is successful and depending on the token:

        // - No value is returned: we assume a revert when the transfer failed (i.e. 'call' returns false)

        // - A single boolean is returned: this boolean needs to be true (non-zero)



        // bytes4(keccak256("transfer(address,uint256)")) = 0xa9059cbb

        bytes memory callData = abi.encodeWithSelector(

            bytes4(0xa9059cbb),

            to,

            value

        );

        (success, ) = token.call(callData);

        return checkReturnValue(success);

    }



    function safeTransferFrom(

        address token,

        address from,

        address to,

        uint256 value)

        internal

        returns (bool success)

    {

        // A transferFrom is successful when 'call' is successful and depending on the token:

        // - No value is returned: we assume a revert when the transfer failed (i.e. 'call' returns false)

        // - A single boolean is returned: this boolean needs to be true (non-zero)



        // bytes4(keccak256("transferFrom(address,address,uint256)")) = 0x23b872dd

        bytes memory callData = abi.encodeWithSelector(

            bytes4(0x23b872dd),

            from,

            to,

            value

        );

        (success, ) = token.call(callData);

        return checkReturnValue(success);

    }



    function checkReturnValue(

        bool success

        )

        internal

        pure

        returns (bool)

    {

        // A transfer/transferFrom is successful when 'call' is successful and depending on the token:

        // - No value is returned: we assume a revert when the transfer failed (i.e. 'call' returns false)

        // - A single boolean is returned: this boolean needs to be true (non-zero)

        if (success) {

            assembly {

                switch returndatasize()

                // Non-standard ERC20: nothing is returned so if 'call' was successful we assume the transfer succeeded

                case 0 {

                    success := 1

                }

                // Standard ERC20: a single boolean value is returned which needs to be true

                case 32 {

                    returndatacopy(0, 0, 32)

                    success := mload(0)

                }

                // None of the above: not successful

                default {

                    success := 0

                }

            }

        }

        return success;

    }



}



// File: contracts/impl/ExchangeDeserializer.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/

pragma solidity ^0.5.7;








/// @title Deserializes the data passed to submitRings

/// @author Daniel Wang - <daniel@loopring.org>,

library ExchangeDeserializer {

    using BytesUtil     for bytes;



    function deserialize(

        address lrcTokenAddress,

        bytes memory data

        )

        internal

        view

        returns (

            Data.Mining memory mining,

            Data.Order[] memory orders,

            Data.Ring[] memory rings

        )

    {

        // Read the header

        Data.Header memory header;

        header.version = data.bytesToUint16(0);

        header.numOrders = data.bytesToUint16(2);

        header.numRings = data.bytesToUint16(4);

        header.numSpendables = data.bytesToUint16(6);



        // Validation

        require(header.version == 0, "Unsupported serialization format");

        require(header.numOrders > 0, "Invalid number of orders");

        require(header.numRings > 0, "Invalid number of rings");

        require(header.numSpendables > 0, "Invalid number of spendables");



        // Calculate data pointers

        uint dataPtr;

        assembly {

            dataPtr := data

        }

        uint miningDataPtr = dataPtr + 8;

        uint orderDataPtr = miningDataPtr + 3 * 2;

        uint ringDataPtr = orderDataPtr + (32 * header.numOrders) * 2;

        uint dataBlobPtr = ringDataPtr + (header.numRings * 9) + 32;



        // The data stream needs to be at least large enough for the

        // header/mining/orders/rings data + 64 bytes of zeros in the data blob.

        require(data.length >= (dataBlobPtr - dataPtr) + 32, "Invalid input data");



        // Setup the rings

        mining = setupMiningData(dataBlobPtr, miningDataPtr + 2);

        orders = setupOrders(dataBlobPtr, orderDataPtr + 2, header.numOrders, header.numSpendables, lrcTokenAddress);

        rings = assembleRings(ringDataPtr + 1, header.numRings, orders);

    }



    function setupMiningData(

        uint data,

        uint tablesPtr

        )

        internal

        view

        returns (Data.Mining memory mining)

    {

        bytes memory emptyBytes = new bytes(0);

        uint offset;



        assembly {

            // Default to transaction origin for feeRecipient

            mstore(add(data, 20), origin)



            // mining.feeRecipient

            offset := mul(and(mload(add(tablesPtr,  0)), 0xFFFF), 4)

            mstore(

                add(mining,   0),

                mload(add(add(data, 20), offset))

            )



            // Restore default to 0

            mstore(add(data, 20), 0)



            // mining.miner

            offset := mul(and(mload(add(tablesPtr,  2)), 0xFFFF), 4)

            mstore(

                add(mining,  32),

                mload(add(add(data, 20), offset))

            )



            // Default to empty bytes array

            mstore(add(data, 32), emptyBytes)



            // mining.sig

            offset := mul(and(mload(add(tablesPtr,  4)), 0xFFFF), 4)

            mstore(

                add(mining, 64),

                add(data, add(offset, 32))

            )



            // Restore default to 0

            mstore(add(data, 32), 0)

        }

    }



    function setupOrders(

        uint data,

        uint tablesPtr,

        uint numOrders,

        uint numSpendables,

        address lrcTokenAddress

        )

        internal

        pure

        returns (Data.Order[] memory orders)

    {

        bytes memory emptyBytes = new bytes(0);

        uint orderStructSize = 40 * 32;

        // Memory for orders length + numOrders order pointers

        uint arrayDataSize = (1 + numOrders) * 32;

        Data.Spendable[] memory spendableList = new Data.Spendable[](numSpendables);

        uint offset;



        assembly {

            // Allocate memory for all orders

            orders := mload(0x40)

            mstore(add(orders, 0), numOrders)                       // orders.length

            // Reserve the memory for the orders array

            mstore(0x40, add(orders, add(arrayDataSize, mul(orderStructSize, numOrders))))



            for { let i := 0 } lt(i, numOrders) { i := add(i, 1) } {

                let order := add(orders, add(arrayDataSize, mul(orderStructSize, i)))



                // Store the memory location of this order in the orders array

                mstore(add(orders, mul(add(1, i), 32)), order)



                // order.version

                offset := and(mload(add(tablesPtr,  0)), 0xFFFF)

                mstore(

                    add(order,   0),

                    offset

                )



                // order.owner

                offset := mul(and(mload(add(tablesPtr,  2)), 0xFFFF), 4)

                mstore(

                    add(order,  32),

                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

                )



                // order.tokenS

                offset := mul(and(mload(add(tablesPtr,  4)), 0xFFFF), 4)

                mstore(

                    add(order,  64),

                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

                )



                // order.tokenB

                offset := mul(and(mload(add(tablesPtr,  6)), 0xFFFF), 4)

                mstore(

                    add(order,  96),

                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

                )



                // order.amountS

                offset := mul(and(mload(add(tablesPtr,  8)), 0xFFFF), 4)

                mstore(

                    add(order, 128),

                    mload(add(add(data, 32), offset))

                )



                // order.amountB

                offset := mul(and(mload(add(tablesPtr, 10)), 0xFFFF), 4)

                mstore(

                    add(order, 160),

                    mload(add(add(data, 32), offset))

                )



                // order.validSince

                offset := mul(and(mload(add(tablesPtr, 12)), 0xFFFF), 4)

                mstore(

                    add(order, 192),

                    and(mload(add(add(data, 4), offset)), 0xFFFFFFFF)

                )



                // order.tokenSpendableS

                offset := and(mload(add(tablesPtr, 14)), 0xFFFF)

                // Force the spendable index to 0 if it's invalid

                offset := mul(offset, lt(offset, numSpendables))

                mstore(

                    add(order, 224),

                    mload(add(spendableList, mul(add(offset, 1), 32)))

                )



                // order.tokenSpendableFee

                offset := and(mload(add(tablesPtr, 16)), 0xFFFF)

                // Force the spendable index to 0 if it's invalid

                offset := mul(offset, lt(offset, numSpendables))

                mstore(

                    add(order, 256),

                    mload(add(spendableList, mul(add(offset, 1), 32)))

                )



                // order.dualAuthAddr

                offset := mul(and(mload(add(tablesPtr, 18)), 0xFFFF), 4)

                mstore(

                    add(order, 288),

                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

                )



                // order.broker

                offset := mul(and(mload(add(tablesPtr, 20)), 0xFFFF), 4)

                mstore(

                    add(order, 320),

                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

                )



                // order.orderInterceptor

                offset := mul(and(mload(add(tablesPtr, 22)), 0xFFFF), 4)

                mstore(

                    add(order, 416),

                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

                )



                // order.wallet

                offset := mul(and(mload(add(tablesPtr, 24)), 0xFFFF), 4)

                mstore(

                    add(order, 448),

                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

                )



                // order.validUntil

                offset := mul(and(mload(add(tablesPtr, 26)), 0xFFFF), 4)

                mstore(

                    add(order, 480),

                    and(mload(add(add(data,  4), offset)), 0xFFFFFFFF)

                )



                // Default to empty bytes array for value sig and dualAuthSig

                mstore(add(data, 32), emptyBytes)



                // order.sig

                offset := mul(and(mload(add(tablesPtr, 28)), 0xFFFF), 4)

                mstore(

                    add(order, 512),

                    add(data, add(offset, 32))

                )



                // order.dualAuthSig

                offset := mul(and(mload(add(tablesPtr, 30)), 0xFFFF), 4)

                mstore(

                    add(order, 544),

                    add(data, add(offset, 32))

                )



                // Restore default to 0

                mstore(add(data, 32), 0)



                // order.allOrNone

                offset := and(mload(add(tablesPtr, 32)), 0xFFFF)

                mstore(

                    add(order, 576),

                    gt(offset, 0)

                )



                // lrcTokenAddress is the default value for feeToken

                mstore(add(data, 20), lrcTokenAddress)



                // order.feeToken

                offset := mul(and(mload(add(tablesPtr, 34)), 0xFFFF), 4)

                mstore(

                    add(order, 608),

                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

                )



                // Restore default to 0

                mstore(add(data, 20), 0)



                // order.feeAmount

                offset := mul(and(mload(add(tablesPtr, 36)), 0xFFFF), 4)

                mstore(

                    add(order, 640),

                    mload(add(add(data, 32), offset))

                )



                // order.waiveFeePercentage

                offset := and(mload(add(tablesPtr, 38)), 0xFFFF)

                mstore(

                    add(order, 672),

                    offset

                )



                // order.tokenSFeePercentage

                offset := and(mload(add(tablesPtr, 40)), 0xFFFF)

                mstore(

                    add(order, 704),

                    offset

                )



                // order.tokenBFeePercentage

                offset := and(mload(add(tablesPtr, 42)), 0xFFFF)

                mstore(

                    add(order, 736),

                    offset

                )



                // The owner is the default value of tokenRecipient

                mstore(add(data, 20), mload(add(order, 32)))                // order.owner



                // order.tokenRecipient

                offset := mul(and(mload(add(tablesPtr, 44)), 0xFFFF), 4)

                mstore(

                    add(order, 768),

                    and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

                )



                // Restore default to 0

                mstore(add(data, 20), 0)



                // order.walletSplitPercentage

                offset := and(mload(add(tablesPtr, 46)), 0xFFFF)

                mstore(

                    add(order, 800),

                    offset

                )



                // order.tokenTypeS

                offset := and(mload(add(tablesPtr, 48)), 0xFFFF)

                mstore(

                    add(order, 1024),

                    offset

                )



                // order.tokenTypeB

                offset := and(mload(add(tablesPtr, 50)), 0xFFFF)

                mstore(

                    add(order, 1056),

                    offset

                )



                // order.tokenTypeFee

                offset := and(mload(add(tablesPtr, 52)), 0xFFFF)

                mstore(

                    add(order, 1088),

                    offset

                )



                // order.trancheS

                offset := mul(and(mload(add(tablesPtr, 54)), 0xFFFF), 4)

                mstore(

                    add(order, 1120),

                    mload(add(add(data, 32), offset))

                )



                // order.trancheB

                offset := mul(and(mload(add(tablesPtr, 56)), 0xFFFF), 4)

                mstore(

                    add(order, 1152),

                    mload(add(add(data, 32), offset))

                )



                // Restore default to 0

                mstore(add(data, 20), 0)



                // order.maxPrimaryFillAmount

                offset := mul(and(mload(add(tablesPtr, 58)), 0xFFFF), 4)

                mstore(

                    add(order, 1184),

                    mload(add(add(data, 32), offset))

                )



                // order.transferMakerFirst

                offset := and(mload(add(tablesPtr, 60)), 0xFFFF)

                mstore(

                    add(order, 1216),

                    gt(offset, 0)

                )



                // Default to empty bytes array for transferDataS

                mstore(add(data, 32), emptyBytes)



                // order.transferDataS

                offset := mul(and(mload(add(tablesPtr, 62)), 0xFFFF), 4)

                mstore(

                    add(order, 1248),

                    add(data, add(offset, 32))

                )



                // Restore default to 0

                mstore(add(data, 32), 0)



                // Set default  values

                mstore(add(order, 832), 0)         // order.P2P

                mstore(add(order, 864), 0)         // order.hash

                mstore(add(order, 896), 0)         // order.brokerInterceptor

                mstore(add(order, 928), 0)         // order.filledAmountS

                mstore(add(order, 960), 0)         // order.initialFilledAmountS

                mstore(add(order, 992), 1)         // order.valid



                // Advance to the next order

                tablesPtr := add(tablesPtr, 64)

            }

        }

    }



    function assembleRings(

        uint data,

        uint numRings,

        Data.Order[] memory orders

        )

        internal

        pure

        returns (Data.Ring[] memory rings)

    {

        uint ringsArrayDataSize = (1 + numRings) * 32;

        uint ringStructSize = 5 * 32;

        uint participationStructSize = 10 * 32;



        assembly {

            // Allocate memory for all rings

            rings := mload(0x40)

            mstore(add(rings, 0), numRings)                      // rings.length

            // Reserve the memory for the rings array

            mstore(0x40, add(rings, add(ringsArrayDataSize, mul(ringStructSize, numRings))))



            for { let r := 0 } lt(r, numRings) { r := add(r, 1) } {

                let ring := add(rings, add(ringsArrayDataSize, mul(ringStructSize, r)))



                // Store the memory location of this ring in the rings array

                mstore(add(rings, mul(add(r, 1), 32)), ring)



                // Get the ring size

                let ringSize := and(mload(data), 0xFF)

                data := add(data, 1)



                // require(ringsSize <= 8)

                if gt(ringSize, 8) {

                    revert(0, 0)

                }



                // Allocate memory for all participations

                let participations := mload(0x40)

                mstore(add(participations, 0), ringSize)         // participations.length

                // Memory for participations length + ringSize participation pointers

                let participationsData := add(participations, mul(add(1, ringSize), 32))

                // Reserve the memory for the participations

                mstore(0x40, add(participationsData, mul(participationStructSize, ringSize)))



                // Initialize ring properties

                mstore(add(ring,   0), ringSize)                 // ring.size

                mstore(add(ring,  32), participations)           // ring.participations

                mstore(add(ring,  64), 0)                        // ring.hash

                mstore(add(ring,  96), 0)                        // ring.minerFeesToOrdersPercentage

                mstore(add(ring, 128), 1)                        // ring.valid



                for { let i := 0 } lt(i, ringSize) { i := add(i, 1) } {

                    let participation := add(participationsData, mul(participationStructSize, i))



                    // Store the memory location of this participation in the participations array

                    mstore(add(participations, mul(add(i, 1), 32)), participation)



                    // Get the order index

                    let orderIndex := and(mload(data), 0xFF)

                    // require(orderIndex < orders.length)

                    if iszero(lt(orderIndex, mload(orders))) {

                        revert(0, 0)

                    }

                    data := add(data, 1)



                    // participation.order

                    mstore(

                        add(participation,   0),

                        mload(add(orders, mul(add(orderIndex, 1), 32)))

                    )



                    // Set default values

                    mstore(add(participation,  32), 0)          // participation.splitS

                    mstore(add(participation,  64), 0)          // participation.feeAmount

                    mstore(add(participation,  96), 0)          // participation.feeAmountS

                    mstore(add(participation, 128), 0)          // participation.feeAmountB

                    mstore(add(participation, 160), 0)          // participation.rebateFee

                    mstore(add(participation, 192), 0)          // participation.rebateS

                    mstore(add(participation, 224), 0)          // participation.rebateB

                    mstore(add(participation, 256), 0)          // participation.fillAmountS

                    mstore(add(participation, 288), 0)          // participation.fillAmountB

                }



                // Advance to the next ring

                data := add(data, sub(8, ringSize))

            }

        }

    }

}



// File: impl/RingSubmitter.sol



/*



  Copyright 2017 Loopring Project Ltd (Loopring Foundation).



  Licensed under the Apache License, Version 2.0 (the "License");

  you may not use this file except in compliance with the License.

  You may obtain a copy of the License at



  http://www.apache.org/licenses/LICENSE-2.0



  Unless required by applicable law or agreed to in writing, software

  distributed under the License is distributed on an "AS IS" BASIS,

  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and

  limitations under the License.

*/







































/// @title An Implementation of IRingSubmitter.

/// @author Daniel Wang - <daniel@loopring.org>,

/// @author Kongliang Zhong - <kongliang@loopring.org>

/// @author Brechtpd - <brecht@loopring.org>

/// Recognized contributing developers from the community:

///     https://github.com/rainydio

///     https://github.com/BenjaminPrice

///     https://github.com/jonasshen

///     https://github.com/Hephyrius

contract RingSubmitter is IRingSubmitter, NoDefaultFunc {

    using MathUint          for uint;

    using BytesUtil         for bytes;

    using OrderHelper       for Data.Order;

    using RingHelper        for Data.Ring;

    using MiningHelper      for Data.Mining;

    using ERC20SafeTransfer for address;



    address public  lrcTokenAddress             = address(0x0);

    address public  wethTokenAddress            = address(0x0);

    address public  delegateAddress             = address(0x0);

    address public  tradeHistoryAddress         = address(0x0);

    address public  orderBrokerRegistryAddress  = address(0x0);

    address public  orderRegistryAddress        = address(0x0);

    address public  feeHolderAddress            = address(0x0);

    address public  orderBookAddress            = address(0x0);

    address public  burnRateTableAddress        = address(0x0);



    uint64  public  ringIndex                   = 0;



    uint    public constant MAX_RING_SIZE       = 8;



    struct SubmitRingsParam {

        uint16[]    encodeSpecs;

        uint16      miningSpec;

        uint16[]    orderSpecs;

        uint8[][]   ringSpecs;

        address[]   addressList;

        uint[]      uintList;

        bytes[]     bytesList;

    }



    constructor(

        address _lrcTokenAddress,

        address _wethTokenAddress,

        address _delegateAddress,

        address _tradeHistoryAddress,

        address _orderBrokerRegistryAddress,

        address _orderRegistryAddress,

        address _feeHolderAddress,

        address _orderBookAddress,

        address _burnRateTableAddress

        )

        public

    {

        require(_lrcTokenAddress != address(0x0), ZERO_ADDRESS);

        require(_wethTokenAddress != address(0x0), ZERO_ADDRESS);

        require(_delegateAddress != address(0x0), ZERO_ADDRESS);

        require(_tradeHistoryAddress != address(0x0), ZERO_ADDRESS);

        require(_orderBrokerRegistryAddress != address(0x0), ZERO_ADDRESS);

        require(_orderRegistryAddress != address(0x0), ZERO_ADDRESS);

        require(_feeHolderAddress != address(0x0), ZERO_ADDRESS);

        require(_orderBookAddress != address(0x0), ZERO_ADDRESS);

        require(_burnRateTableAddress != address(0x0), ZERO_ADDRESS);



        lrcTokenAddress = _lrcTokenAddress;

        wethTokenAddress = _wethTokenAddress;

        delegateAddress = _delegateAddress;

        tradeHistoryAddress = _tradeHistoryAddress;

        orderBrokerRegistryAddress = _orderBrokerRegistryAddress;

        orderRegistryAddress = _orderRegistryAddress;

        feeHolderAddress = _feeHolderAddress;

        orderBookAddress = _orderBookAddress;

        burnRateTableAddress = _burnRateTableAddress;

    }



    function submitRings(

        bytes calldata data

        )

        external

    {

        uint i;

        bytes32[] memory tokenBurnRates;



        (

            Data.Mining  memory mining,

            Data.Order[] memory orders,

            Data.Ring[]  memory rings

        ) = ExchangeDeserializer.deserialize(lrcTokenAddress, data);



        Data.Context memory ctx = Data.Context(

            lrcTokenAddress,

            ITradeDelegate(delegateAddress),

            ITradeHistory(tradeHistoryAddress),

            IBrokerRegistry(orderBrokerRegistryAddress),

            IOrderRegistry(orderRegistryAddress),

            IFeeHolder(feeHolderAddress),

            IOrderBook(orderBookAddress),

            IBurnRateTable(burnRateTableAddress),

            ringIndex,

            FEE_PERCENTAGE_BASE,

            tokenBurnRates,

            0,

            0,

            0,

            0,

            new Data.BrokerOrder[](orders.length),

            new Data.BrokerAction[](orders.length),

            new Data.BrokerTransfer[](orders.length * 3),

            0,

            0,

            0

        );



        // Set the highest bit of ringIndex to '1' (IN STORAGE!)

        ringIndex = ctx.ringIndex | (1 << 63);



        // Check if the highest bit of ringIndex is '1'

        require((ctx.ringIndex >> 63) == 0, REENTRY);



        // Allocate memory that is used to batch things for all rings

        setupLists(ctx, orders, rings);



        for (i = 0; i < orders.length; i++) {

            orders[i].updateHash();

        }



        batchGetFilledAndCheckCancelled(ctx, orders);



        for (i = 0; i < orders.length; i++) {

            orders[i].check(ctx);

            // An order can only be sent once

            for (uint j = i + 1; j < orders.length; j++) {

                require(orders[i].hash != orders[j].hash, INVALID_VALUE);

            }

        }



        for (i = 0; i < rings.length; i++) {

            rings[i].updateHash();

        }



        mining.updateHash(rings);

        mining.updateMinerAndInterceptor();

        require(mining.checkMinerSignature(), INVALID_SIG);



        for (i = 0; i < orders.length; i++) {

            // We don't need to verify the dual author signature again if it uses the same

            // dual author address as the previous order (the miner can optimize the order of the orders

            // so this happens as much as possible). We don't need to check if the signature is the same

            // because the same mining hash is signed for all orders.

            if(i > 0 && orders[i].dualAuthAddr == orders[i - 1].dualAuthAddr) {

                continue;

            }

            orders[i].checkDualAuthSignature(mining.hash);

        }



        for (i = 0; i < rings.length; i++) {

            Data.Ring memory ring = rings[i];

            ring.checkOrdersValid();

            // ring.checkForSubRings(); we submit rings of size 2 - there's no need to check for sub-rings

            ring.calculateFillAmountAndFee(ctx);

            if (ring.valid) {

                ring.adjustOrderStates();

            }

        }



        // Check if the allOrNone orders are completely filled over all rings

        // This can invalidate rings

        checkRings(orders, rings);



        for (i = 0; i < rings.length; i++) {

            Data.Ring memory ring = rings[i];

            if (ring.valid) {

                // Only settle rings we have checked to be valid

                ring.doPayments(ctx, mining);

                emitRingMinedEvent(

                    ring,

                    ctx.ringIndex++,

                    mining.feeRecipient

                );

            } else {

                emit InvalidRing(ring.hash);

            }

        }



        // Do all token transfers for all rings

        batchTransferTokens(ctx);

        // Do all broker token transfers for all rings

        batchBrokerTransferTokens(ctx, orders);

        // Do all fee payments for all rings

        batchPayFees(ctx);

        // Update all order stats

        updateOrdersStats(ctx, orders);



        // Update ringIndex while setting the highest bit of ringIndex back to '0'

        ringIndex = ctx.ringIndex;

    }



    function checkRings(

        Data.Order[] memory orders,

        Data.Ring[] memory rings

        )

        internal

        pure

    {

        // Check if allOrNone orders are completely filled

        // When a ring is turned invalid because of an allOrNone order we have to

        // recheck the other rings again because they may contain other allOrNone orders

        // that may not be completely filled anymore.

        bool reevaluateRings = true;

        while (reevaluateRings) {

            reevaluateRings = false;

            for (uint i = 0; i < orders.length; i++) {

                if (orders[i].valid) {

                    orders[i].validateAllOrNone();

                    // Check if the order valid status has changed

                    reevaluateRings = reevaluateRings || !orders[i].valid;

                }

            }

            if (reevaluateRings) {

                for (uint i = 0; i < rings.length; i++) {

                    Data.Ring memory ring = rings[i];

                    if (ring.valid) {

                        ring.checkOrdersValid();

                        if (!ring.valid) {

                            // If the ring was valid before the completely filled check we have to revert the filled amountS

                            // of the orders in the ring. This is a bit awkward so maybe there's a better solution.

                            ring.revertOrderStats();

                        }

                    }

                }

            }

        }

    }



    function emitRingMinedEvent(

        Data.Ring memory ring,

        uint _ringIndex,

        address feeRecipient

        )

        internal

    {

        bytes32 ringHash = ring.hash;

        // keccak256("RingMined(uint256,bytes32,address,bytes)")

        bytes32 ringMinedSignature = 0xb2ef4bc5209dff0c46d5dfddb2b68a23bd4820e8f33107fde76ed15ba90695c9;

        uint fillsSize = ring.size * 8 * 32;



        uint data;

        uint ptr;

        assembly {

            data := mload(0x40)

            ptr := data

            mstore(ptr, _ringIndex)                     // ring index data

            mstore(add(ptr, 32), 0x40)                  // offset to fills data

            mstore(add(ptr, 64), fillsSize)             // fills length

            ptr := add(ptr, 96)

        }

        ptr = ring.generateFills(ptr);



        assembly {

            log3(

                data,                                   // data start

                sub(ptr, data),                         // data length

                ringMinedSignature,                     // Topic 0: RingMined signature

                ringHash,                               // Topic 1: ring hash

                feeRecipient                            // Topic 2: feeRecipient

            )

        }

    }



    function setupLists(

        Data.Context memory ctx,

        Data.Order[] memory orders,

        Data.Ring[] memory rings

        )

        internal

        pure

    {

        setupTokenBurnRateList(ctx, orders);

        setupFeePaymentList(ctx, rings);

        setupTokenTransferList(ctx, rings);

    }



    function setupTokenBurnRateList(

        Data.Context memory ctx,

        Data.Order[] memory orders

        )

        internal

        pure

    {

        // Allocate enough memory to store burn rates for all tokens even

        // if every token is unique (max 2 unique tokens / order)

        uint maxNumTokenBurnRates = orders.length * 2;

        bytes32[] memory tokenBurnRates;

        assembly {

            tokenBurnRates := mload(0x40)

            mstore(tokenBurnRates, 0)                               // tokenBurnRates.length

            mstore(0x40, add(

                tokenBurnRates,

                add(32, mul(maxNumTokenBurnRates, 64))

            ))

        }

        ctx.tokenBurnRates = tokenBurnRates;

    }



    function setupFeePaymentList(

        Data.Context memory ctx,

        Data.Ring[] memory rings

        )

        internal

        pure

    {

        uint totalMaxSizeFeePayments = 0;

        for (uint i = 0; i < rings.length; i++) {

            // Up to (ringSize + 3) * 3 payments per order (because of fee sharing by miner)

            // (3 x 32 bytes for every fee payment)

            uint ringSize = rings[i].size;

            uint maxSize = (ringSize + 3) * 3 * ringSize * 3;

            totalMaxSizeFeePayments += maxSize;

        }

        // Store the data directly in the call data format as expected by batchAddFeeBalances:

        // - 0x00: batchAddFeeBalances selector (4 bytes)

        // - 0x04: parameter offset (batchAddFeeBalances has a single function parameter) (32 bytes)

        // - 0x24: length of the array passed into the function (32 bytes)

        // - 0x44: the array data (32 bytes x length)

        bytes4 batchAddFeeBalancesSelector = ctx.feeHolder.batchAddFeeBalances.selector;

        uint ptr;

        assembly {

            let data := mload(0x40)

            mstore(data, batchAddFeeBalancesSelector)

            mstore(add(data, 4), 32)

            ptr := add(data, 68)

            mstore(0x40, add(ptr, mul(totalMaxSizeFeePayments, 32)))

        }

        ctx.feeData = ptr;

        ctx.feePtr = ptr;

    }



    function setupTokenTransferList(

        Data.Context memory ctx,

        Data.Ring[] memory rings

        )

        internal

        pure

    {

        uint totalMaxSizeTransfers = 0;

        for (uint i = 0; i < rings.length; i++) {

            // Up to 4 transfers per order

            // (4 x 32 bytes for every transfer)

            uint maxSize = 4 * rings[i].size * 4;

            totalMaxSizeTransfers += maxSize;

        }

        // Store the data directly in the call data format as expected by batchTransfer:

        // - 0x00: batchTransfer selector (4 bytes)

        // - 0x04: parameter offset (batchTransfer has a single function parameter) (32 bytes)

        // - 0x24: length of the array passed into the function (32 bytes)

        // - 0x44: the array data (32 bytes x length)

        bytes4 batchTransferSelector = ctx.delegate.batchTransfer.selector;

        uint ptr;

        assembly {

            let data := mload(0x40)

            mstore(data, batchTransferSelector)

            mstore(add(data, 4), 32)

            ptr := add(data, 68)

            mstore(0x40, add(ptr, mul(totalMaxSizeTransfers, 32)))

        }

        ctx.transferData = ptr;

        ctx.transferPtr = ptr;

    }



    function updateOrdersStats(

        Data.Context memory ctx,

        Data.Order[] memory orders

        )

        internal

    {

        // Store the data directly in the call data format as expected by batchUpdateFilled:

        // - 0x00: batchUpdateFilled selector (4 bytes)

        // - 0x04: parameter offset (batchUpdateFilled has a single function parameter) (32 bytes)

        // - 0x24: length of the array passed into the function (32 bytes)

        // - 0x44: the array data (32 bytes x length)

        // For every (valid) order we store 2 words:

        // - order.hash

        // - order.filledAmountS after all rings

        bytes4 batchUpdateFilledSelector = ctx.tradeHistory.batchUpdateFilled.selector;

        address _tradeHistoryAddress = address(ctx.tradeHistory);

        assembly {

            let data := mload(0x40)

            mstore(data, batchUpdateFilledSelector)

            mstore(add(data, 4), 32)

            let ptr := add(data, 68)

            let arrayLength := 0

            for { let i := 0 } lt(i, mload(orders)) { i := add(i, 1) } {

                let order := mload(add(orders, mul(add(i, 1), 32)))

                let filledAmount := mload(add(order, 928))                               // order.filledAmountS

                let initialFilledAmount := mload(add(order, 960))                        // order.initialFilledAmountS

                let filledAmountChanged := iszero(eq(filledAmount, initialFilledAmount))

                // if (order.valid && filledAmountChanged)

                if and(gt(mload(add(order, 992)), 0), filledAmountChanged) {             // order.valid

                    mstore(add(ptr,   0), mload(add(order, 864)))                        // order.hash

                    mstore(add(ptr,  32), filledAmount)



                    ptr := add(ptr, 64)

                    arrayLength := add(arrayLength, 2)

                }

            }



            // Only do the external call if the list is not empty

            if gt(arrayLength, 0) {

                mstore(add(data, 36), arrayLength)      // filledInfo.length



                let success := call(

                    gas,                                // forward all gas

                    _tradeHistoryAddress,               // external address

                    0,                                  // wei

                    data,                               // input start

                    sub(ptr, data),                     // input length

                    data,                               // output start

                    0                                   // output length

                )

                if eq(success, 0) {

                    // Propagate the revert message

                    returndatacopy(0, 0, returndatasize())

                    revert(0, returndatasize())

                }

            }

        }

    }



    function batchGetFilledAndCheckCancelled(

        Data.Context memory ctx,

        Data.Order[] memory orders

        )

        internal

    {

        // Store the data in the call data format as expected by batchGetFilledAndCheckCancelled:

        // - 0x00: batchGetFilledAndCheckCancelled selector (4 bytes)

        // - 0x04: parameter offset (batchGetFilledAndCheckCancelled has a single function parameter) (32 bytes)

        // - 0x24: length of the array passed into the function (32 bytes)

        // - 0x44: the array data (32 bytes x length)

        // For every order we store 5 words:

        // - order.broker

        // - order.owner

        // - order.hash

        // - order.validSince

        // - The trading pair of the order: order.tokenS ^ order.tokenB

        bytes4 batchGetFilledAndCheckCancelledSelector = ctx.tradeHistory.batchGetFilledAndCheckCancelled.selector;

        address _tradeHistoryAddress = address(ctx.tradeHistory);

        assembly {

            let data := mload(0x40)

            mstore(data, batchGetFilledAndCheckCancelledSelector)

            mstore(add(data,  4), 32)

            mstore(add(data, 36), mul(mload(orders), 5))                // orders.length

            let ptr := add(data, 68)

            for { let i := 0 } lt(i, mload(orders)) { i := add(i, 1) } {

                let order := mload(add(orders, mul(add(i, 1), 32)))     // orders[i]

                mstore(add(ptr,   0), mload(add(order, 320)))           // order.broker

                mstore(add(ptr,  32), mload(add(order,  32)))           // order.owner

                mstore(add(ptr,  64), mload(add(order, 864)))           // order.hash

                mstore(add(ptr,  96), mload(add(order, 192)))           // order.validSince

                // bytes20(order.tokenS) ^ bytes20(order.tokenB)        // tradingPair

                mstore(add(ptr, 128), mul(

                    xor(

                        mload(add(order, 64)),                 // order.tokenS

                        mload(add(order, 96))                  // order.tokenB

                    ),

                    0x1000000000000000000000000)               // shift left 12 bytes (bytes20 is padded on the right)

                )

                ptr := add(ptr, 160)                                    // 5 * 32

            }

            // Return data is stored just like the call data without the signature:

            // 0x00: Offset to data

            // 0x20: Array length

            // 0x40: Array data

            let returnDataSize := mul(add(2, mload(orders)), 32)

            let success := call(

                gas,                                // forward all gas

                _tradeHistoryAddress,               // external address

                0,                                  // wei

                data,                               // input start

                sub(ptr, data),                     // input length

                data,                               // output start

                returnDataSize                      // output length

            )

            // Check if the call was successful and the return data is the expected size

            if or(eq(success, 0), iszero(eq(returndatasize(), returnDataSize))) {

                if eq(success, 0) {

                    // Propagate the revert message

                    returndatacopy(0, 0, returndatasize())

                    revert(0, returndatasize())

                }

                revert(0, 0)

            }

            for { let i := 0 } lt(i, mload(orders)) { i := add(i, 1) } {

                let order := mload(add(orders, mul(add(i, 1), 32)))     // orders[i]

                let fill := mload(add(data,  mul(add(i, 2), 32)))       // fills[i]

                mstore(add(order, 928), fill)                           // order.filledAmountS

                mstore(add(order, 960), fill)                           // order.initialFilledAmountS

                // If fills[i] == ~uint(0) the order was cancelled

                // order.valid = order.valid && (order.filledAmountS != ~uint(0))

                mstore(add(order, 992),                                 // order.valid

                    and(

                        gt(mload(add(order, 992)), 0),                  // order.valid

                        iszero(eq(fill, not(0)))                        // fill != ~uint(0

                    )

                )

            }

        }

    }



    function batchBrokerTransferTokens(Data.Context memory ctx, Data.Order[] memory orders) internal {

        Data.BrokerInterceptorReport[] memory reportQueue = new Data.BrokerInterceptorReport[](orders.length);

        uint reportCount = 0;



        for (uint i = 0; i < ctx.numBrokerActions; i++) {

            Data.BrokerAction memory action = ctx.brokerActions[i];

            Data.BrokerApprovalRequest memory request = Data.BrokerApprovalRequest({

                orders: new Data.BrokerOrder[](action.numOrders),

                tokenS: action.tokenS,

                tokenB: action.tokenB,

                feeToken: action.feeToken,

                totalFillAmountB: 0,

                totalRequestedAmountS: 0,

                totalRequestedFeeAmount: 0

            });

            

            for (uint b = 0; b < action.numOrders; b++) {

                request.orders[b] = ctx.brokerOrders[action.orderIndices[b]];

                request.totalFillAmountB += request.orders[b].fillAmountB;

                request.totalRequestedAmountS += request.orders[b].requestedAmountS;

                request.totalRequestedFeeAmount += request.orders[b].requestedFeeAmount;

            }



            bool requiresReport = IBrokerDelegate(action.broker).brokerRequestAllowance(request);

            

            if (requiresReport) {

                for (uint k = 0; k < request.orders.length; k++) {

                    reportQueue[reportCount] = Data.BrokerInterceptorReport({

                        owner: request.orders[k].owner,

                        broker: action.broker,

                        orderHash: request.orders[k].orderHash,

                        tokenB: action.tokenB,

                        tokenS: action.tokenS,

                        feeToken: action.feeToken,

                        fillAmountB: request.orders[k].fillAmountB,

                        spentAmountS: request.orders[k].requestedAmountS,

                        spentFeeAmount: request.orders[k].requestedFeeAmount,

                        tokenRecipient: request.orders[k].tokenRecipient,

                        extraData: request.orders[k].extraData

                    });

                    reportCount += 1;

                }

            }



            for (uint j = 0; j < action.numTransfers; j++) {

                Data.BrokerTransfer memory transfer = ctx.brokerTransfers[action.transferIndices[j]];



                if (transfer.recipient != action.broker) {

                    require(transfer.token.safeTransferFrom(

                        action.broker, 

                        transfer.recipient, 

                        transfer.amount

                    ), TRANSFER_FAILURE);

                }

            }

        }



        for (uint m = 0; m < reportCount; m++) {

            IBrokerDelegate(reportQueue[m].broker).onOrderFillReport(reportQueue[m]);

        }

    }



    function batchTransferTokens(

        Data.Context memory ctx

        )

        internal

    {

        // Check if there are any transfers

        if (ctx.transferData == ctx.transferPtr) {

            return;

        }

        // We stored the token transfers in the call data as expected by batchTransfer.

        // The only thing we still need to do is update the final length of the array and call

        // the function on the TradeDelegate contract with the generated data.

        address _tradeDelegateAddress = address(ctx.delegate);

        uint arrayLength = (ctx.transferPtr - ctx.transferData) / 32;

        uint data = ctx.transferData - 68;

        uint ptr = ctx.transferPtr;

        assembly {

            mstore(add(data, 36), arrayLength)      // batch.length



            let success := call(

                gas,                                // forward all gas

                _tradeDelegateAddress,              // external address

                0,                                  // wei

                data,                               // input start

                sub(ptr, data),                     // input length

                data,                               // output start

                0                                   // output length

            )

            if eq(success, 0) {

                // Propagate the revert message

                returndatacopy(0, 0, returndatasize())

                revert(0, returndatasize())

            }

        }

    }



    function batchPayFees(

        Data.Context memory ctx

        )

        internal

    {

        // Check if there are any fee payments

        if (ctx.feeData == ctx.feePtr) {

            return;

        }

        // We stored the fee payments in the call data as expected by batchAddFeeBalances.

        // The only thing we still need to do is update the final length of the array and call

        // the function on the FeeHolder contract with the generated data.

        address _feeHolderAddress = address(ctx.feeHolder);

        uint arrayLength = (ctx.feePtr - ctx.feeData) / 32;

        uint data = ctx.feeData - 68;

        uint ptr = ctx.feePtr;

        assembly {

            mstore(add(data, 36), arrayLength)      // batch.length



            let success := call(

                gas,                                // forward all gas

                _feeHolderAddress,                  // external address

                0,                                  // wei

                data,                               // input start

                sub(ptr, data),                     // input length

                data,                               // output start

                0                                   // output length

            )

            if eq(success, 0) {

                // Propagate the revert message

                returndatacopy(0, 0, returndatasize())

                revert(0, returndatasize())

            }

        }

    }



}