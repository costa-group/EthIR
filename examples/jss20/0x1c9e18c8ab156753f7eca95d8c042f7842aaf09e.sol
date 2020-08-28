// File: ../../mosaic-contracts/contracts/lib/BytesLib.sol

pragma solidity ^0.5.0;

library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure returns (bytes memory bytes_)
    {
        /* solium-disable-next-line */
        assembly {
            // Get a location of some free memory and store it in bytes_ as
            // Solidity does for memory variables.
            bytes_ := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for bytes_.
            let length := mload(_preBytes)
            mstore(bytes_, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(bytes_, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the bytes_ memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of bytes_
            // and store it as the new length in the first 32 bytes of the
            // bytes_ memory.
            length := mload(_postBytes)
            mstore(bytes_, add(length, mload(bytes_)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of bytes_ to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }
    }

    // Pad a bytes array to 32 bytes
    function leftPad(
        bytes memory _bytes
    )
        internal
        pure
        returns (bytes memory padded_)
    {
        bytes memory padding = new bytes(32 - _bytes.length);
        padded_ = concat(padding, _bytes);
    }

    /**
     * @notice Convert bytes32 to bytes
     *
     * @param _inBytes32 bytes32 value
     *
     * @return bytes value
     */
    function bytes32ToBytes(bytes32 _inBytes32)
        internal
        pure
        returns (bytes memory bytes_)
    {
        bytes_ = new bytes(32);

        /* solium-disable-next-line */
        assembly {
            mstore(add(32, bytes_), _inBytes32)
        }
    }

}

// File: ../../mosaic-contracts/contracts/lib/RLP.sol

pragma solidity ^0.5.0;

/**
* @title RLPReader
*
* RLPReader is used to read and parse RLP encoded data in memory.
*
* @author Andreas Olofsson (androlo1980@gmail.com)
*/
library RLP {

    /** Constants */
    uint constant DATA_SHORT_START = 0x80;
    uint constant DATA_LONG_START = 0xB8;
    uint constant LIST_SHORT_START = 0xC0;
    uint constant LIST_LONG_START = 0xF8;

    uint constant DATA_LONG_OFFSET = 0xB7;
    uint constant LIST_LONG_OFFSET = 0xF7;

    /** Storage */
    struct RLPItem {
        uint _unsafe_memPtr;    // Pointer to the RLP-encoded bytes.
        uint _unsafe_length;    // Number of bytes. This is the full length of the string.
    }

    struct Iterator {
        RLPItem _unsafe_item;   // Item that's being iterated over.
        uint _unsafe_nextPtr;   // Position of the next item in the list.
    }

    /* Internal Functions */

    /** Iterator */

    function next(
        Iterator memory self
    )
        internal
        pure
        returns (RLPItem memory subItem_)
    {
        require(hasNext(self));
        uint ptr = self._unsafe_nextPtr;
        uint itemLength = _itemLength(ptr);
        subItem_._unsafe_memPtr = ptr;
        subItem_._unsafe_length = itemLength;
        self._unsafe_nextPtr = ptr + itemLength;
    }

    function next(
        Iterator memory self,
        bool strict
    )
        internal
        pure
        returns (RLPItem memory subItem_)
    {
        subItem_ = next(self);
        require(!(strict && !_validate(subItem_)));
    }

    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self._unsafe_item;
        return self._unsafe_nextPtr < item._unsafe_memPtr + item._unsafe_length;
    }

    /** RLPItem */

    /**
    *  @dev Creates an RLPItem from an array of RLP encoded bytes.
    *
    *  @param self The RLP encoded bytes.
    *
    *  @return An RLPItem.
    */
    function toRLPItem(
        bytes memory self
    )
        internal
        pure
        returns (RLPItem memory)
    {
        uint len = self.length;
        if (len == 0) {
            return RLPItem(0, 0);
        }
        uint memPtr;

        /* solium-disable-next-line */
        assembly {
            memPtr := add(self, 0x20)
        }

        return RLPItem(memPtr, len);
    }

    /**
    *  @dev Creates an RLPItem from an array of RLP encoded bytes.
    *
    *  @param self The RLP encoded bytes.
    *  @param strict Will throw if the data is not RLP encoded.
    *
    *  @return An RLPItem.
    */
    function toRLPItem(
        bytes memory self,
        bool strict
    )
        internal
        pure
        returns (RLPItem memory)
    {
        RLPItem memory item = toRLPItem(self);
        if(strict) {
            uint len = self.length;
            require(_payloadOffset(item) <= len);
            require(_itemLength(item._unsafe_memPtr) == len);
            require(_validate(item));
        }
        return item;
    }

    /**
    *  @dev Check if the RLP item is null.
    *
    *  @param self The RLP item.
    *
    *  @return 'true' if the item is null.
    */
    function isNull(RLPItem memory self) internal pure returns (bool ret) {
        return self._unsafe_length == 0;
    }

    /**
    *  @dev Check if the RLP item is a list.
    *
    *  @param self The RLP item.
    *
    *  @return 'true' if the item is a list.
    */
    function isList(RLPItem memory self) internal pure returns (bool ret) {
        if (self._unsafe_length == 0) {
            return false;
        }
        uint memPtr = self._unsafe_memPtr;

        /* solium-disable-next-line */
        assembly {
            ret := iszero(lt(byte(0, mload(memPtr)), 0xC0))
        }
    }

    /**
    *  @dev Check if the RLP item is data.
    *
    *  @param self The RLP item.
    *
    *  @return 'true' if the item is data.
    */
    function isData(RLPItem memory self) internal pure returns (bool ret) {
        if (self._unsafe_length == 0) {
            return false;
        }
        uint memPtr = self._unsafe_memPtr;

        /* solium-disable-next-line */
        assembly {
            ret := lt(byte(0, mload(memPtr)), 0xC0)
        }
    }

    /**
    *  @dev Check if the RLP item is empty (string or list).
    *
    *  @param self The RLP item.
    *
    *  @return 'true' if the item is null.
    */
    function isEmpty(RLPItem memory self) internal pure returns (bool ret) {
        if(isNull(self)) {
            return false;
        }
        uint b0;
        uint memPtr = self._unsafe_memPtr;

        /* solium-disable-next-line */
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        return (b0 == DATA_SHORT_START || b0 == LIST_SHORT_START);
    }

    /**
    *  @dev Get the number of items in an RLP encoded list.
    *
    *  @param self The RLP item.
    *
    *  @return The number of items.
    */
    function items(RLPItem memory self) internal pure returns (uint) {
        if (!isList(self)) {
            return 0;
        }
        uint b0;
        uint memPtr = self._unsafe_memPtr;

        /* solium-disable-next-line */
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        uint pos = memPtr + _payloadOffset(self);
        uint last = memPtr + self._unsafe_length - 1;
        uint itms;
        while(pos <= last) {
            pos += _itemLength(pos);
            itms++;
        }
        return itms;
    }

    /**
    *  @dev Create an iterator.
    *
    *  @param self The RLP item.
    *
    *  @return An 'Iterator' over the item.
    */
    function iterator(
        RLPItem memory self
    )
        internal
        pure
        returns (Iterator memory it_)
    {
        require (isList(self));
        uint ptr = self._unsafe_memPtr + _payloadOffset(self);
        it_._unsafe_item = self;
        it_._unsafe_nextPtr = ptr;
    }

    /**
    *  @dev Return the RLP encoded bytes.
    *
    *  @param self The RLPItem.
    *
    *  @return The bytes.
    */
    function toBytes(
        RLPItem memory self
    )
        internal
        pure
        returns (bytes memory bts_)
    {
        uint len = self._unsafe_length;
        if (len == 0) {
            return bts_;
        }
        bts_ = new bytes(len);
        _copyToBytes(self._unsafe_memPtr, bts_, len);
    }

    /**
    *  @dev Decode an RLPItem into bytes. This will not work if the RLPItem is a list.
    *
    *  @param self The RLPItem.
    *
    *  @return The decoded string.
    */
    function toData(
        RLPItem memory self
    )
        internal
        pure
        returns (bytes memory bts_)
    {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        bts_ = new bytes(len);
        _copyToBytes(rStartPos, bts_, len);
    }

    /**
    *  @dev Get the list of sub-items from an RLP encoded list.
    *       Warning: This is inefficient, as it requires that the list is read twice.
    *
    *  @param self The RLP item.
    *
    *  @return Array of RLPItems.
    */
    function toList(
        RLPItem memory self
    )
        internal
        pure
        returns (RLPItem[] memory list_)
    {
        require(isList(self));
        uint numItems = items(self);
        list_ = new RLPItem[](numItems);
        Iterator memory it = iterator(self);
        uint idx = 0;
        while(hasNext(it)) {
            list_[idx] = next(it);
            idx++;
        }
    }

    /**
    *  @dev Decode an RLPItem into an ascii string. This will not work if the
    *       RLPItem is a list.
    *
    *  @param self The RLPItem.
    *
    *  @return The decoded string.
    */
    function toAscii(
        RLPItem memory self
    )
        internal
        pure
        returns (string memory str_)
    {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        bytes memory bts = new bytes(len);
        _copyToBytes(rStartPos, bts, len);
        str_ = string(bts);
    }

    /**
    *  @dev Decode an RLPItem into a uint. This will not work if the
    *  RLPItem is a list.
    *
    *  @param self The RLPItem.
    *
    *  @return The decoded string.
    */
    function toUint(RLPItem memory self) internal pure returns (uint data_) {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        if (len > 32 || len == 0) {
            revert();
        }

        /* solium-disable-next-line */
        assembly {
            data_ := div(mload(rStartPos), exp(256, sub(32, len)))
        }
    }

    /**
    *  @dev Decode an RLPItem into a boolean. This will not work if the
    *       RLPItem is a list.
    *
    *  @param self The RLPItem.
    *
    *  @return The decoded string.
    */
    function toBool(RLPItem memory self) internal pure returns (bool data) {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        require(len == 1);
        uint temp;

        /* solium-disable-next-line */
        assembly {
            temp := byte(0, mload(rStartPos))
        }
        require (temp <= 1);

        return temp == 1 ? true : false;
    }

    /**
    *  @dev Decode an RLPItem into a byte. This will not work if the
    *       RLPItem is a list.
    *
    *  @param self The RLPItem.
    *
    *  @return The decoded string.
    */
    function toByte(RLPItem memory self) internal pure returns (byte data) {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        require(len == 1);
        uint temp;

        /* solium-disable-next-line */
        assembly {
            temp := byte(0, mload(rStartPos))
        }

        return byte(uint8(temp));
    }

    /**
    *  @dev Decode an RLPItem into an int. This will not work if the
    *       RLPItem is a list.
    *
    *  @param self The RLPItem.
    *
    *  @return The decoded string.
    */
    function toInt(RLPItem memory self) internal pure returns (int data) {
        return int(toUint(self));
    }

    /**
    *  @dev Decode an RLPItem into a bytes32. This will not work if the
    *       RLPItem is a list.
    *
    *  @param self The RLPItem.
    *
    *  @return The decoded string.
    */
    function toBytes32(
        RLPItem memory self
    )
        internal
        pure
        returns (bytes32 data)
    {
        return bytes32(toUint(self));
    }

    /**
    *  @dev Decode an RLPItem into an address. This will not work if the
    *       RLPItem is a list.
    *
    *  @param self The RLPItem.
    *
    *  @return The decoded string.
    */
    function toAddress(
        RLPItem memory self
    )
        internal
        pure
        returns (address data)
    {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        require (len == 20);

        /* solium-disable-next-line */
        assembly {
            data := div(mload(rStartPos), exp(256, 12))
        }
    }

    /**
    *  @dev Decode an RLPItem into an address. This will not work if the
    *       RLPItem is a list.
    *
    *  @param self The RLPItem.
    *
    *  @return Get the payload offset.
    */
    function _payloadOffset(RLPItem memory self) private pure returns (uint) {
        if(self._unsafe_length == 0)
            return 0;
        uint b0;
        uint memPtr = self._unsafe_memPtr;

        /* solium-disable-next-line */
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        if(b0 < DATA_SHORT_START)
            return 0;
        if(b0 < DATA_LONG_START || (b0 >= LIST_SHORT_START && b0 < LIST_LONG_START))
            return 1;
        if(b0 < LIST_SHORT_START)
            return b0 - DATA_LONG_OFFSET + 1;
        return b0 - LIST_LONG_OFFSET + 1;
    }

    /**
    *  @dev Decode an RLPItem into an address. This will not work if the
    *       RLPItem is a list.
    *
    *  @param memPtr Memory pointer.
    *
    *  @return Get the full length of an RLP item.
    */
    function _itemLength(uint memPtr) private pure returns (uint len) {
        uint b0;

        /* solium-disable-next-line */
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        if (b0 < DATA_SHORT_START) {
            len = 1;
        } else if (b0 < DATA_LONG_START) {
            len = b0 - DATA_SHORT_START + 1;
        } else if (b0 < LIST_SHORT_START) {
            /* solium-disable-next-line */
            assembly {
                let bLen := sub(b0, 0xB7) // bytes length (DATA_LONG_OFFSET)
                let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen))) // data length
                len := add(1, add(bLen, dLen)) // total length
            }
        } else if (b0 < LIST_LONG_START) {
            len = b0 - LIST_SHORT_START + 1;
        } else {
            /* solium-disable-next-line */
            assembly {
                let bLen := sub(b0, 0xF7) // bytes length (LIST_LONG_OFFSET)
                let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen))) // data length
                len := add(1, add(bLen, dLen)) // total length
            }
        }
    }

    /**
    *  @dev Decode an RLPItem into an address. This will not work if the
    *       RLPItem is a list.
    *
    *  @param self The RLPItem.
    *
    *  @return Get the full length of an RLP item.
    */
    function _decode(
        RLPItem memory self
    )
        private
        pure
        returns (uint memPtr_, uint len_)
    {
        require(isData(self));
        uint b0;
        uint start = self._unsafe_memPtr;

        /* solium-disable-next-line */
        assembly {
            b0 := byte(0, mload(start))
        }
        if (b0 < DATA_SHORT_START) {
            memPtr_ = start;
            len_ = 1;

            return (memPtr_, len_);
        }
        if (b0 < DATA_LONG_START) {
            len_ = self._unsafe_length - 1;
            memPtr_ = start + 1;
        } else {
            uint bLen;

            /* solium-disable-next-line */
            assembly {
                bLen := sub(b0, 0xB7) // DATA_LONG_OFFSET
            }
            len_ = self._unsafe_length - 1 - bLen;
            memPtr_ = start + bLen + 1;
        }
    }

    /**
    *  @dev Assumes that enough memory has been allocated to store in target.
    *       Gets the full length of an RLP item.
    *
    *  @param btsPtr Bytes pointer.
    *  @param tgt Last item to be allocated.
    *  @param btsLen Bytes length.
    */
    function _copyToBytes(
        uint btsPtr,
        bytes memory tgt,
        uint btsLen
    )
        private
        pure
    {
        // Exploiting the fact that 'tgt' was the last thing to be allocated,
        // we can write entire words, and just overwrite any excess.
        /* solium-disable-next-line */
        assembly {
                let i := 0 // Start at arr + 0x20
                let stopOffset := add(btsLen, 31)
                let rOffset := btsPtr
                let wOffset := add(tgt, 32)
                for {} lt(i, stopOffset) { i := add(i, 32) }
                {
                    mstore(add(wOffset, i), mload(add(rOffset, i)))
                }
        }
    }

    /**
    *  @dev Check that an RLP item is valid.
    *
    *  @param self The RLPItem.
    */
    function _validate(RLPItem memory self) private pure returns (bool ret) {
        // Check that RLP is well-formed.
        uint b0;
        uint b1;
        uint memPtr = self._unsafe_memPtr;

        /* solium-disable-next-line */
        assembly {
            b0 := byte(0, mload(memPtr))
            b1 := byte(1, mload(memPtr))
        }
        if(b0 == DATA_SHORT_START + 1 && b1 < DATA_SHORT_START)
            return false;
        return true;
    }
}

// File: ../../mosaic-contracts/contracts/lib/MerklePatriciaProof.sol

pragma solidity ^0.5.0;
/**
 * @title MerklePatriciaVerifier
 * @author Sam Mayo (sammayo888@gmail.com)
 *
 * @dev Library for verifing merkle patricia proofs.
 */


library MerklePatriciaProof {
    /**
     * @dev Verifies a merkle patricia proof.
     * @param value The terminating value in the trie.
     * @param encodedPath The path in the trie leading to value.
     * @param rlpParentNodes The rlp encoded stack of nodes.
     * @param root The root hash of the trie.
     * @return The boolean validity of the proof.
     */
    function verify(
        bytes32 value,
        bytes calldata encodedPath,
        bytes calldata rlpParentNodes,
        bytes32 root
    )
        external
        pure
        returns (bool)
    {
        RLP.RLPItem memory item = RLP.toRLPItem(rlpParentNodes);
        RLP.RLPItem[] memory parentNodes = RLP.toList(item);

        bytes memory currentNode;
        RLP.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint pathPtr = 0;

        bytes memory path = _getNibbleArray2(encodedPath);
        if(path.length == 0) {return false;}

        for (uint i=0; i<parentNodes.length; i++) {
            if(pathPtr > path.length) {return false;}

            currentNode = RLP.toBytes(parentNodes[i]);
            if(nodeKey != keccak256(abi.encodePacked(currentNode))) {return false;}
            currentNodeList = RLP.toList(parentNodes[i]);

            if(currentNodeList.length == 17) {
                if(pathPtr == path.length) {
                    if(keccak256(abi.encodePacked(RLP.toBytes(currentNodeList[16]))) == value) {
                        return true;
                    } else {
                        return false;
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if(nextPathNibble > 16) {return false;}
                nodeKey = RLP.toBytes32(currentNodeList[nextPathNibble]);
                pathPtr += 1;
            } else if(currentNodeList.length == 2) {

                // Count of matching node key nibbles in path starting from pathPtr.
                uint traverseLength = _nibblesToTraverse(RLP.toData(currentNodeList[0]), path, pathPtr);

                if(pathPtr + traverseLength == path.length) { //leaf node
                    if(keccak256(abi.encodePacked(RLP.toData(currentNodeList[1]))) == value) {
                        return true;
                    } else {
                        return false;
                    }
                } else if (traverseLength == 0) { // error: couldn't traverse path
                    return false;
                } else { // extension node
                    pathPtr += traverseLength;
                    nodeKey = RLP.toBytes32(currentNodeList[1]);
                }

            } else {
                return false;
            }
        }
    }

    function verifyDebug(
        bytes32 value,
        bytes memory not_encodedPath,
        bytes memory rlpParentNodes,
        bytes32 root
    )
        public
        pure
        returns (bool res_, uint loc_, bytes memory path_debug_)
    {
        RLP.RLPItem memory item = RLP.toRLPItem(rlpParentNodes);
        RLP.RLPItem[] memory parentNodes = RLP.toList(item);

        bytes memory currentNode;
        RLP.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint pathPtr = 0;

        bytes memory path = _getNibbleArray2(not_encodedPath);
        path_debug_ = path;
        if(path.length == 0) {
            loc_ = 0;
            res_ = false;
            return (res_, loc_, path_debug_);
        }

        for (uint i=0; i<parentNodes.length; i++) {
            if(pathPtr > path.length) {
                loc_ = 1;
                res_ = false;
                return (res_, loc_, path_debug_);
            }

            currentNode = RLP.toBytes(parentNodes[i]);
            if(nodeKey != keccak256(abi.encodePacked(currentNode))) {
                res_ = false;
                loc_ = 100 + i;
                return (res_, loc_, path_debug_);
            }
            currentNodeList = RLP.toList(parentNodes[i]);

            loc_ = currentNodeList.length;

            if(currentNodeList.length == 17) {
                if(pathPtr == path.length) {
                    if(keccak256(abi.encodePacked(RLP.toBytes(currentNodeList[16]))) == value) {
                        res_ = true;
                        return (res_, loc_, path_debug_);
                    } else {
                        loc_ = 3;
                        return (res_, loc_, path_debug_);
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if(nextPathNibble > 16) {
                    loc_ = 4;
                    return (res_, loc_, path_debug_);
                }
                nodeKey = RLP.toBytes32(currentNodeList[nextPathNibble]);
                pathPtr += 1;
            } else if(currentNodeList.length == 2) {
                pathPtr += _nibblesToTraverse(RLP.toData(currentNodeList[0]), path, pathPtr);

                if(pathPtr == path.length) {//leaf node
                    if(keccak256(abi.encodePacked(RLP.toData(currentNodeList[1]))) == value) {
                        res_ = true;
                        return (res_, loc_, path_debug_);
                    } else {
                        loc_ = 5;
                        return (res_, loc_, path_debug_);
                    }
                }
                //extension node
                if(_nibblesToTraverse(RLP.toData(currentNodeList[0]), path, pathPtr) == 0) {
                    loc_ = 6;
                    res_ = (keccak256(abi.encodePacked()) == value);
                    return (res_, loc_, path_debug_);
                }

                nodeKey = RLP.toBytes32(currentNodeList[1]);
            } else {
                loc_ = 7;
                return (res_, loc_, path_debug_);
            }
        }

        loc_ = 8;
    }

    function _nibblesToTraverse(
        bytes memory encodedPartialPath,
        bytes memory path,
        uint pathPtr
    )
        private
        pure
        returns (uint len_)
    {
        // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
        // and slicedPath have elements that are each one hex character (1 nibble)
        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);

        // pathPtr counts nibbles in path
        // partialPath.length is a number of nibbles
        for(uint i=pathPtr; i<pathPtr+partialPath.length; i++) {
            byte pathNibble = path[i];
            slicedPath[i-pathPtr] = pathNibble;
        }

        if(keccak256(abi.encodePacked(partialPath)) == keccak256(abi.encodePacked(slicedPath))) {
            len_ = partialPath.length;
        } else {
            len_ = 0;
        }
    }

    // bytes b must be hp encoded
    function _getNibbleArray(
        bytes memory b
    )
        private
        pure
        returns (bytes memory nibbles_)
    {
        if(b.length>0) {
            uint8 offset;
            uint8 hpNibble = uint8(_getNthNibbleOfBytes(0,b));
            if(hpNibble == 1 || hpNibble == 3) {
                nibbles_ = new bytes(b.length*2-1);
                byte oddNibble = _getNthNibbleOfBytes(1,b);
                nibbles_[0] = oddNibble;
                offset = 1;
            } else {
                nibbles_ = new bytes(b.length*2-2);
                offset = 0;
            }

            for(uint i=offset; i<nibbles_.length; i++) {
                nibbles_[i] = _getNthNibbleOfBytes(i-offset+2,b);
            }
        }
    }

    // normal byte array, no encoding used
    function _getNibbleArray2(
        bytes memory b
    )
        private
        pure
        returns (bytes memory nibbles_)
    {
        nibbles_ = new bytes(b.length*2);
        for (uint i = 0; i < nibbles_.length; i++) {
            nibbles_[i] = _getNthNibbleOfBytes(i, b);
        }
    }

    function _getNthNibbleOfBytes(
        uint n,
        bytes memory str
    )
        private
        pure returns (byte)
    {
        return byte(n%2==0 ? uint8(str[n/2])/0x10 : uint8(str[n/2])%0x10);
    }
}

// File: ../../mosaic-contracts/contracts/lib/GatewayLib.sol

pragma solidity ^0.5.0;

// Copyright 2019 OpenST Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//



library GatewayLib {

    /* Constants */

    bytes32 constant public STAKE_INTENT_TYPEHASH = keccak256(
        abi.encode(
            "StakeIntent(uint256 amount,address beneficiary,address gateway)"
        )
    );

    bytes32 constant public REDEEM_INTENT_TYPEHASH = keccak256(
        abi.encode(
            "RedeemIntent(uint256 amount,address beneficiary,address gateway)"
        )
    );


    /* External Functions */

    /**
     * @notice Merkle proof verification of account.
     *
     * @param _rlpAccount RLP encoded data of account.
     * @param _rlpParentNodes Path from root node to leaf in merkle tree.
     * @param _encodedPath Encoded path to search account node in merkle tree.
     * @param _stateRoot State root for given block height.
     *
     * @return bytes32 Storage path of the variable.
     */
    function proveAccount(
        bytes calldata _rlpAccount,
        bytes calldata _rlpParentNodes,
        bytes calldata _encodedPath,
        bytes32 _stateRoot
    )
        external
        pure
        returns (bytes32 storageRoot_)
    {
        // Decode RLP encoded account value.
        RLP.RLPItem memory accountItem = RLP.toRLPItem(_rlpAccount);

        // Convert to list.
        RLP.RLPItem[] memory accountArray = RLP.toList(accountItem);

        // Array 3rd position is storage root.
        storageRoot_ = RLP.toBytes32(accountArray[2]);

        // Hash the rlpValue value.
        bytes32 hashedAccount = keccak256(
            abi.encodePacked(_rlpAccount)
        );

        /*
         * Verify the remote OpenST contract against the committed state
         * root with the state trie Merkle proof.
         */
        require(
            MerklePatriciaProof.verify(
                hashedAccount,
                _encodedPath,
                _rlpParentNodes,
                _stateRoot
            ),
            "Account proof is not verified."
        );

    }

    /**
     * @notice Creates the hash of a stake intent struct based on its fields.
     *
     * @param _amount Stake amount.
     * @param _beneficiary The beneficiary address on the auxiliary chain.
     * @param _gateway The address of the  gateway where the staking took place.
     *
     * @return stakeIntentHash_ The hash that represents this stake intent.
     */
    function hashStakeIntent(
        uint256 _amount,
        address _beneficiary,
        address _gateway
    )
        external
        pure
        returns (bytes32 stakeIntentHash_)
    {
        stakeIntentHash_ = keccak256(
            abi.encode(
                STAKE_INTENT_TYPEHASH,
                _amount,
                _beneficiary,
                _gateway
            )
        );
    }

    /**
     * @notice Creates the hash of a redeem intent struct based on its fields.
     *
     * @param _amount Redeem amount.
     * @param _beneficiary The beneficiary address on the origin chain.
     * @param _gateway The address of the  gateway where the redeeming happened.
     *
     * @return redeemIntentHash_ The hash that represents this stake intent.
     */
    function hashRedeemIntent(
        uint256 _amount,
        address _beneficiary,
        address _gateway
    )
        external
        pure
        returns (bytes32 redeemIntentHash_)
    {
        redeemIntentHash_ = keccak256(
            abi.encode(
                REDEEM_INTENT_TYPEHASH,
                _amount,
                _beneficiary,
                _gateway
            )
        );
    }
}