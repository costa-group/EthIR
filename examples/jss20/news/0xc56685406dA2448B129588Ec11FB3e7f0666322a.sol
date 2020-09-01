// File: contracts/ACE/validators/swap/SwapABIEncoder.sol

pragma solidity >=0.5.0 <0.6.0;

/**
 * @title SwapABIEncoder
 * @author AZTEC
 * @dev Library to ABI encode the output of a Swap proof verification
 * Don't include this as an internal library. This contract uses a static memory table to cache
 * elliptic curve primitives and hashes.
 * Calling this internally from another function will lead to memory mutation and undefined behaviour.
 * The intended use case is to call this externally via `staticcall`.
 * External calls to OptimizedAZTEC can be treated as pure functions as this contract contains no
 * storage and makes no external calls (other than to precompiles)
 * 
 * Copyright 2020 Spilsbury Holdings Ltd 
 *
 * Licensed under the GNU Lesser General Public Licence, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/

library SwapABIEncoder {

    /**
    * Calldata map
    * 0x04:0x24      = calldata location of proofData byte array - pointer to the proofData.
    * 0x24:0x44      = message sender // sender
    * 0x44:0x64      = h_x     // crs
    * 0x64:0x84      = h_y     // crs
    * 0x84:0xa4      = t2_x0   // crs
    * 0xa4:0xc4      = t2_x1   // crs
    * 0xc4:0xe4      = t2_y0   // crs
    * 0xe4:0x104     = t2_y1   // crs
    * 0x104:0x124    = length of proofData byte array
    * 0x124:0x144    = challenge
    * 0x144:0x164    = offset in byte array to notes
    * 0x164:0x184    = offset in byte array to inputOwners
    * 0x184:0x1a4    = offset in byte array to outputOwners
    * 0x1a4:0x1c4    = offset in byte array to metadata
    **/

    function encodeAndExit() internal pure {
        assembly {
            // set up initial variables
            let notes := add(0x104, calldataload(0x144))
            let noteOwners := add(0x124, calldataload(0x164)) // // one word after inputOwners = 1st
            let metadataPtr := add(0x144, calldataload(0x184)) // two words after metadata = 1st

            // First up, we need to do some checks to ensure we have been provided with correct data.
            // We should only have 2 entries inside `bytes metadata` (only 2 output notes in total),
            // and only 4 entries inside `noteOwners` (4 notes in a Swap proof)
            if iszero(and(
                eq(0x02, calldataload(sub(metadataPtr, 0x20))),
                eq(0x04, calldataload(sub(noteOwners, 0x20)))
            )) {
                revert(0x00, 0x00) // no! bad! come back with good inputs!
            }

            // memory map of `proofOutputs`
            // 0x00 - 0x160  = scratch data for note hash computation

            // `returndata` starts at 0x160
            // `proofOutputs` starts at 0x180
            // 0x160 - 0x180 = relative offset in returndata to first bytes argument (0x20)
            // 0x180 - 0x1a0 = byte length of `proofOutputs`
            // 0x1a0 - 0x1c0 = number of `proofOutputs` entries (2)
            // 0x1c0 - 0x1e0 = relative memory offset between `v` and start of `proofOutputs[0]` (0x80)
            // 0x1e0 - 0x200 = relative memory offset between `v` and start of `proofOutputs[1]`

            // `proofOutput` - t, starts at 0x200
            // 0x200 - 0x220 = length of `proofOutput`
            // 0x220 - 0x240 = relative offset between `t` and `inputNotes`
            // 0x240 - 0x260 = relative offset between `t` and `outputNotes`
            // 0x260 - 0x280 = `publicOwner`
            // 0x280 - 0x2a0 = `publicValue`
            // 0x2a0 - 0x2c0 = `challenge`

            // `inputNotes` starts at 0x2c0
            // structure of `inputNotes` and `outputNotes`
            // 0x00 - 0x20 = byte length of notes array
            // 0x20 - 0x40 = number of notes = 1
            // 0x40 - 0x60 = offset to start of input note (0x60)

            // structure of a `note`
            // 0x00 - 0x20 = size of `note`
            // 0x20 - 0x40 = `owner`
            // 0x40 - 0x60 = `noteHash`
            // 0x60 - 0x80 = size of note `data`
            // 0x80 - 0xa0 = compressed note coordinate `gamma` (part of `data`)
            // 0xa0 - 0xc0 = compressed note coordinate `sigma` (part of `data`)
            // 0xc0 - ???? = remaining note metadata

            // Note organisation...
            // The Swap proof proves the following:
            //   1. note[0].value == note[2].value
            //   2. note[1].value == note[3].value
            // In other words...
            // note[0] = maker bid note
            // note[1] = maker ask note
            // note[2] = taker ask note
            // note[3] = taker bid note

            // We therefore have 2 balancing relationships
            // 1. The maker bid note is destroyed and replaced with the taker ask note
            // 2. The taker bid note is destroyed and replaced with the maker ask note

            // Finally, we can translate this into 2 proofOutputs entries...
            // In the first entry, `inputNotes` = [note[0]] and `outputNotes` = [note[2]]
            // In the second entry, `inputNotes` = [note[3]] and `outputNotes` = [note[1]]

            // `proofOutputs` must form a monolithic block of memory that we can return.
            // `s` points to the memory location of the start of the current note
            // `inputPtr` points to the start of the current `notes` dynamic bytes array

            // length of proofOutputs is at 0x180

            // we use memory from 0x00 - 0x140 as scratch memory

            // return data starts at 0x160. As return data is `bytes proofOutputs`,
            // the first word is the relative offset to the start of `proofOutputs` (i.e. 0x20)
            mstore(0x160, 0x20)

            /**
            * Encoding of proofOutputs
            * abi encoding of proofOutputs
            * 0x00 : 0x20 = byte length of `proofOutputs` = 0x60 + L1 + L2
            * 0x20 : 0x40 = number of `proofOutputs` entries (2)
            * 0x40 : 0x60 = relative memory offset between `v` and start of `proofOutputs[0]` (0x80)
            * 0x60 : 0x80 = relative memory offset between `v` and start of `proofOutputs[1]`
            * 0x80 : 0x80 + L1    = start of proofOutputs[0]
            * 0x80 + L1   : 0x80 + L1 + L2 = start of proofOutputs[1]
            **/

            // 0x180 stores the total size of `bytes proofOutputs`. We don't know that yet, so leave blank

            // 0x1a0 = number of proof outputs (2)
            mstore(0x1a0, 0x02)                            // number of proofs

            // 0x1c0 = relative offset to 1st entry (0x80, 4 words)
            mstore(0x1c0, 0x80)                            // offset to 1st proof

            /**
            * Encoding of proofOutput
            * 0x00 : 0x20 = byte length of `proofOutput` = 0x60 + L1 + L2
            * 0x20 : 0x40 = relative offset to `bytes inputNotes`
            * 0x40 : 0x60 = relative offset to `bytes outputNotes`
            * 0x60 : 0x80 = publicOwner
            * 0x80 : 0xa0 = publicValue
            * 0xa0 : 0xc0 = challenge
            * 0xc0 : 0xc0 + L1 = `bytes inputNotes` (L1 = 0x140 bytes)
            * 0xc0 + L1 : 0xc0 + L1 + L2 = `bytes inputNotes`
            *
            * Start of proofOutput = 0x200
            **/

            // length of proofOutput is at 0x200. We don't know that yet, so leave blank

            // relative offset to inputNotes = 0xc0 (6 words)
            mstore(0x220, 0xc0)                            // location of inputNotes

            // we know that inputNotes has 1 entry, and input notes don't have metadata.
            // So we actually know the complete size of `bytes inputNotes`
            // (it's 0x140 bytes, we'll get to that in a bit)
            // => relative offset to outputNotes = 0x140 + 0xc0 = 0x200
            mstore(0x240, 0x200)                           // location of outputNotes

            // Swap proof hardcodes `publicOwner` and `publicValue` to 0 (no public tokens)
            mstore(0x260, 0x00)                             // publicOwner
            mstore(0x280, 0x00)                             // publicValue
            mstore(0x2a0, calldataload(0x124))              // challenge
            /**
            * Encoding of inputNotes
            * 0x00 : 0x20 = byte length of `inputNotes` (0x120)
            * 0x20 : 0x40 = number of input notes (0x01)
            * 0x40 : 0x60 = relative offset to 1st input note (0x60)
            * 0x60 : L    = 1st input note data (L = 0xe0)
            *
            * Start of inputNotes = 0x2a0
            * Because we only have 1 note in this array, and that note has no metadata
            * we know that the size of the note is 0xe0 bytes
            * therefore, the size of inputNotes = 0xe0 + 3 words = 0x140 bytes.
            * We store the byte length as 0x120 bytes because the length parameter
            * of a dynamic bytes array does not include itself in the length calculation
            **/

            // 0x2c0 = length of inputNotes = 0x120
            mstore(0x2c0, 0x120)

            // 0x2e0 = number of notes (1)
            mstore(0x2e0, 0x01) // 1 input note

            // 0x300 = relative offset to input note (0x60)
            mstore(0x300, 0x60) // relative offset to note data

            /**
            * Encoding of input note
            * 0x00 : 0x20 = byte length of note (0xc0)
            * 0x20 : 0x40 = note type (UXTO type = 0x01)
            * 0x40 : 0x60 = note owner
            * 0x60 : 0x80 = note hash
            * 0x80 : 0xa0 = note data length (0x40)
            * 0xa0 : 0xc0 = note coordinate 'gamma' (compressed)
            * 0xc0 : 0xe0 = note coordinate 'sigma' (compressed)
            *
            * Start of note = 0x320
            * The size of this note = 0xe0 bytes, so we store 0xc0 in the length parameter
            **/

            // we use memory from 0x00 - 0xa0 as scratch memory to compute note hash
            // Note hash = keccak256(abi.encode(noteType, gammaX, gammaY, sigmaX, sigmaY))
            mstore(0x00, 0x01) // store noteType at 0x01

            // We want to copy note coordinate data into memory from 0x20 - 0xa0
            // 'notes' points to the start of the notes array
            // i.e. notes + 0x20 will point to the start of the data of the first entry
            // first two entries are \bar{k} and \bar{a}, which we wish to skip over
            // input note is notes[0] => we need to point to notes + 0x60
            calldatacopy(0x20, add(notes, 0x60), 0x80) // copy gamma, sigma into 0x20 - 0xa0

            // 0x320 = length of note (0xc0)
            mstore(0x320, 0xc0)

            // 0x340 = note type (UXTO type, 0x01)
            mstore(0x340, 0x01) // note type

            // 0x360 = note owners. We want the 1st entry in `noteOwners` (calldataload(noteOwners))
            mstore(0x360, calldataload(noteOwners)) // note owner

            // 0x380 = note hash, which is the hash of memory from 0x00 - 0xa0
            mstore(0x380, keccak256(0x00, 0xa0)) // note hash

            // 0x3a0 = noteData length (0x40, no metadata)
            mstore(0x3a0, 0x40)

            // We now need to store compressed note coordinates.
            // We store them in compressed form, as this stuff will be emitted as an event and is not required
            // for additional smart contract logic. Compressing reduces the event data size and saves a fair bit of gas

            // To compress, we determine if the y-coordinate is odd.
            // If it is, we set the 256th bit of the x-coordinate to 'true'.
            // bn128 field elements are only 254 bits long, so we know that we won't override x-coordinate data
            // (we already have the note coords in memory, so we load from memory instead of calldata)

            // 0x3c0 = gamma
            mstore(
                0x3c0,
                or(
                    mload(0x20), // load x coordinate
                    mul(         // multiply by (y & 1 ? 2^255 : 0)
                        and(mload(0x40), 0x01),
                        0x8000000000000000000000000000000000000000000000000000000000000000
                    )
                )
            )

            // 0x3e0 = sigma
            mstore(
                0x3e0,
                or(
                    mload(0x60),
                    mul(
                    and(mload(0x80), 0x01),
                    0x8000000000000000000000000000000000000000000000000000000000000000
                    )
                )
            )

            /**
            * Encoding of output notes
            *
            * abi format is identical to input notes, but now we don't know the total size
            * (because of variable length metadata)
            * 0x00 : 0x20 = byte length of `outputNotes` (0x40 + L)
            * 0x20 : 0x40 = number of output notes (0x01)
            * 0x40 : 0x60 = relative offset to 1st output note (0x60)
            * 0x60 : 0x60 + L    = 1st output note data
            *
            * Start of outputNotes = 0x400
            **/

            // 0x400 = byte length of output notes. We don't know what this is so leave blank for now

            // 0x420 = number of output notes (0x01)
            mstore(0x420, 0x01)

            // 0x440 = relative offset to output note data (0x60)
            mstore(0x440, 0x60)

            /**
            * Encoding of output note
            * 0x00 : 0x20 = byte length of note (0xc0 + L)
            * 0x20 : 0x40 = note type (UXTO type = 0x01)
            * 0x40 : 0x60 = note owner
            * 0x60 : 0x80 = note hash
            * 0x80 : 0xa0 = note data length (0x40 + L)
            * 0xa0 : 0xc0 = note coordinate 'gamma' (compressed)
            * 0xc0 : 0xe0 = note coordinate 'sigma' (compressed)
            * 0xe0 : 0xe0 + L = note metadata
            *
            * Start of note = 0x460
            * The size of this note = 0xe0 bytes, so we store 0xc0 in the length parameter
            **/

            // next, copy note coordinates into memory to compute hash.
            // We already stored the noteType at position 0x00, no need to do that again
            // We need to copy data from notes[2].
            // 1. notes + 0x20 = start of 1st entry data
            // 2. size of a note entry = 0xc0 bytes
            // 3. we want to point to 3rd word in our note entry, to skip over \bar{k}, \bar{a}
            //    (i.e. add 0x40 to caldlata pointer)
            // => offset = notes + 0x20 + 0x40 + (0xc0 * 2) = notes + 0x1e0
            // => calldata pointer = notes + 0x1e0
            calldatacopy(0x20, add(notes, 0x1e0), 0x80) // get gamma, sigma

            // 0x460 = byte length of output note. Leave blank for now

            // 0x480 = note type (0x01)
            mstore(0x480, 0x01)      // note type

            // 0x4a0 = note owner. We are accessing `notes[2]`, therefore
            // the note owner = noteOwners[2].
            // i.e. noteOwners + 0x40
            mstore(0x4a0, calldataload(add(noteOwners, 0x40))) // note owner

            // 0x4c0 = note hash
            mstore(0x4c0, keccak256(0x00, 0xa0))

            // 0x4e0 = noteData length. To get this, we need to identify our metadata length
            // `metadataPtr` points to the relative offset, in the `metadata` array, to the first metadata entry
            // ABI encoding of the input data should encode 2 metadata entries.
            // => relative offset to this note's metadata = `calldataload(metadataPtr)`
            let metadataIndex := calldataload(metadataPtr)
    
            // To convert this into a calldata offset, we must add the number of bytes of calldata
            // that preceeds the start of the `metadata` array.

            // `bytes metadata` abi encoding:
            // 0x00 : 0x20 = size of bytes array
            // 0x20 : 0x40 = number of metadata entries (i)
            // 0x40 : 0x40 + (0x20 * j) = relative offsets to each metadata entry
            // 0x40 + (0x20 * j) : ??? = metadata entries

            // The `metadata` pointer points to the 3rd word (at 0x40), the 1st relative offset
            // Therefore, to compute the calldata offset to the metadata entry,
            // we need to add `metadataPtr - 0x40` to `calldataload(metadataPtr)`.
            // i.e. metadataCalldataPtr = calldataload(add(sub(metadataPtr, 0x40), metadataIndex))

            // Because each metadata entry is itself a dynamic bytes array, the first word will
            // be the length of the metadata entry. This is what we want, so we directly call
            // `calldataload` on our offset
            let metadataLength := calldataload(add(metadataIndex, sub(metadataPtr, 0x40)))

            // 0x4e0 = noteData length = 0x40 + metadata length
            mstore(0x4e0, add(0x40, metadataLength))

            // 0x500 = compressed note coordinate gamma
            mstore(
                0x500,
                or(
                    mload(0x20),
                    mul(
                        and(mload(0x40), 0x01),
                        0x8000000000000000000000000000000000000000000000000000000000000000
                    )
                )
            )

            // 0x520 = compressed note coordinate sigma
            mstore(
                0x520,
                or(
                    mload(0x60),
                    mul(
                        and(mload(0x80), 0x01),
                        0x8000000000000000000000000000000000000000000000000000000000000000
                    )
                )
            )

            // To complete `noteData`, we need to copy note metadata into memory (0x540)
            // We know that metadataIndex + metadataPtr - 0x40 points to the start of the metadata entry in calldata.
            // But the first word is the length of the metadata entry, which we don't want.
            // So we need to point to the second word (the byte array data).
            // i.e. we want to start copying at (metadataIndex + metadataPtr - 0x20)
            // and we want to copy `metadataLength` number of bytes.
            calldatacopy(0x540, add(metadataIndex, sub(metadataPtr, 0x20)), metadataLength)

            // We now need to work backwards and fill in the parts of `bytes proofOutput` that we left blank,
            // as we now can identify the size of the array

            // 0x460 points to the size of the output note. The actual size is 0xe0 + metadataLength.
            // So we record 0xc0 + metadataLength
            // (because the 'size' of a byte array does not take into account the word needed to record the size)
            mstore(0x460, add(0xc0, metadataLength))  // update size of note

            // 0x400 = the size of `bytes outputNotes`.
            // Raw size = 0x140 + metadataLength, so record 0x120 + metadataLength
            mstore(0x400, add(0x120, metadataLength)) // update size of outputNotes

            // 0x200 = the size of `bytes proofOutput`
            // Raw size = 0x340 + metadataLength, so record 0x340 + metadataLength
            mstore(0x200, add(0x320, metadataLength))

            // Great! We've now finished writing the 1st proof output.
            // We now need to write the ABI encoding of the 2nd proof output entry.

            // 0x1e0 points to the relative offset in `bytes proofOutputs` to the second proof entry.
            // This will be equal to the size of the 1st proof, plus the 0x80 preceeding bytes
            // that are used to record `bytes proofOutputs`
            // i.e. relative offset = 0x340 + 0x80 + metadataLength = 0x3c0 + metadataLength
            mstore(0x1e0, add(0x3c0, metadataLength))

            /**
            * proofOutput[1]
            **/

            // When writing data into proofOutputs[1], we cannot use an absolute offset as
            // metadataLength is not known at compile time.
            // `proofPtr` points to the start of `proofOutputs[1]`
            let proofPtr := add(0x540, metadataLength)

            // (proofPtr) = size of proofOutput (leave blank for now)

            // (proofPtr + 0x20) = offset to inputNotes (0xc0)
            mstore(add(proofPtr, 0x20), 0xc0)

            // (proofPtr + 0x40) = offset to outputNotes (0x200)
            mstore(add(proofPtr, 0x40), 0x200)

            // (proofPtr + 0x60) = publicOwner (0)
            mstore(add(proofPtr, 0x60), 0x00) // publicOwner

            // (proofPtr + 0x80) = publicValue (0)
            mstore(add(proofPtr, 0x80), 0x00) // publicValue

            // (proofPtr + 0xa0) = challenge
            // we hash the challenge to get the second proof output's challenge - to preserve uniqueness
            mstore(0xe0, calldataload(0x124))
            mstore(add(proofPtr, 0xa0), keccak256(0xe0, 0x20)) // challenge

            /**
            * proofOutput[1].inputNotes
            *
            * starts at (proofPtr + 0xc0)
            **/

            // (proofPtr + 0xc0) = byte size of inputNotes (0x120)
            mstore(add(proofPtr, 0xc0), 0x120)

            // (proofPtr + 0xe0) = number of input notes (0x01)
            mstore(add(proofPtr, 0xe0), 0x01)

            // (proofPtr + 0x100) = relative offset to input note data (0x60)
            mstore(add(proofPtr, 0x100), 0x60)

            /**
            * proofOutput[1].inputNotes[0]
            *
            * starts at (proofPtr + 0x120)
            **/

            // input note = notes[3]
            // => offset = notes + 0x60 + (0xc0 * 3) = notes + 0x2a0
            // copy note data into scratch memory to hash
            calldatacopy(0x20, add(notes, 0x2a0), 0x80)

            // (proofPtr + 0x120) = byte length of input note (0xc0)
            mstore(add(proofPtr, 0x120), 0xc0) // length of input note

            // (proofPtr + 0x140) = note type (UXTO type, 0x01)
            mstore(add(proofPtr, 0x140), 0x01) // note type

            // (proofPtr + 0x160) = note owner = noteOwners[3]
            mstore(add(proofPtr, 0x160), calldataload(add(noteOwners, 0x60))) // note owner

            // (proofPtr + 0x180) = note hash
            mstore(add(proofPtr, 0x180), keccak256(0x00, 0xa0)) // note hash

            // (proofPtr + 0x1a0) = noteData length (0x40 bytes)
            mstore(add(proofPtr, 0x1a0), 0x40)

            // (proofPtr + 0x1c0) = compressed coordinate 'gamma'
            mstore(
                add(proofPtr, 0x1c0),
                or(
                    mload(0x20),
                    mul(
                        and(mload(0x40), 0x01),
                        0x8000000000000000000000000000000000000000000000000000000000000000
                    )
                )
            )

            // (proofPtr + 0x1e0) = compressed coordinate 'sigma'
            mstore(
                add(proofPtr, 0x1e0),
                or(
                    mload(0x60),
                    mul(
                        and(mload(0x80), 0x01),
                        0x8000000000000000000000000000000000000000000000000000000000000000
                    )
                )
            )

            /**
            * proofOutput[1].outputNotes
            *
            * starts at (proofPtr + 0x200)
            **/

            // (proofPtr + 0x200) = byte length of output notes, leave blank for now

            // (proofPtr + 0x220) = number of output notes (0x01)
            mstore(add(proofPtr, 0x220), 0x01)

            // (proofPtr + 0x240) = offset to output notes (0x60)
            mstore(add(proofPtr, 0x240), 0x60)

            /**
            * proofOutput[1].outputNotes[0]
            *
            * starts at (proofPtr + 0x260)
            **/
            // output note = notes[1]
            // => offset = notes + 0x60 + 0xc0 = notes + 0x120
            // copy note data into scratch memory to hash
            calldatacopy(0x20, add(notes, 0x120), 0x80)

            // (proofPtr + 0x260) = length of note, leave blank for now

            // (proofPtr + 0x280) = note type (UXTO type, 0x01)
            mstore(add(proofPtr, 0x280), 0x01) // note type

            // (proofPtr + 0x2a0) = note owner (noteOwners[1])
            mstore(add(proofPtr, 0x2a0), calldataload(add(noteOwners, 0x20)))

            // (proofPtr + 0x2c0) = note hash
            mstore(add(proofPtr, 0x2c0), keccak256(0x00, 0xa0))

            // We now need to compute the metadata length. We want to access the 2nd metadata entry,
            // at (metadataPtr + 0x20)
            metadataIndex := calldataload(add(metadataPtr, 0x20))
            metadataLength := calldataload(add(metadataIndex, sub(metadataPtr, 0x40)))
            // (proofPtr + 0x2e0) = noteData length (0x40 + metadataLength)
            mstore(add(proofPtr, 0x2e0), add(0x40, metadataLength))

            // (proofPtr + 0x300) = compressed coordinate 'gamma'
            mstore(
                add(proofPtr, 0x300),
                or(
                    mload(0x20),
                    mul(
                        and(mload(0x40), 0x01),
                        0x8000000000000000000000000000000000000000000000000000000000000000
                    )
                )
            )

            // (proofPtr + 0x320) = compressed coordinate 'sigma'
            mstore(
                add(proofPtr, 0x320),
                or(
                    mload(0x60),
                    mul(
                        and(mload(0x80), 0x01),
                        0x8000000000000000000000000000000000000000000000000000000000000000
                    )
                )
            )

            // (proofPtr + 0x340) = start of note metadata
            calldatacopy(add(proofPtr, 0x340), add(metadataIndex, sub(metadataPtr, 0x20)), metadataLength)

            // Next, work backwards and fill in the remaining gaps
            // (proofPtr + 0x260) = proofOutputs[1].outputNotes[0].length (0xc0 + metadataLength)
            mstore(add(proofPtr, 0x260), add(0xc0, metadataLength))

            // (proofPtr + 0x200) = proofOutputs[1].outputNotes.length (0x120 + metadataLength)
            mstore(add(proofPtr, 0x200), add(0x120, metadataLength))

            // (proofPtr) = proofOutputs[1].length = (0x320 + metadataLength)
            mstore(proofPtr, add(0x320, metadataLength))

            // (0x180) = proofOutputs.length
            // We previously stored proofOutputs[0].length at 0x200
            // Total length = combination of
            // 1. proofOutputs[0].length + 0x20 (extra word because of length variable)
            // 2. proofOutputs[1].length + 0x20 (^^)
            // 3. data to record relative offsets (0x20 * number of outputs) = (0x40)
            // 4. data to record number of entries (0x20)

            // We stored proofOutputs[0].length at 0x200
            // and we know that proofOutputs[1].length = 0x320 + metadataLength
            // => length = mload(0x200) + metadataLength + 0x320 + 0x40 + 0x40 + 0x20
            // => length = mload(0x200) + metadataLength + 0x3c0
            mstore(0x180, add(add(0x3c0, metadataLength), mload(0x200)))

            // Great, we've done it! Now all that is left is to return from this transaction.
            // Our return data starts at 0x160.
            // Total size of `bytes proofOutpust` = proofOutputs.length + 0x20
            // We need 1 extra word (at 0x160) for the relative offset to get to `bytes proofOutputs`
            // => returndata size = proofOutputs.length + 0x40
            // = mload(0x180) + 0x40
            return(0x160, add(mload(0x180), 0x40)) // *kazoo noises*
        }
    }
}

// File: contracts/ACE/validators/swap/Swap.sol

pragma solidity >=0.5.0 <0.6.0;


/**
 * @title Swap
 * @author AZTEC
 * @dev Library to validate Swap proofs
 * Don't include this as an internal library. This contract uses
 * a static memory table to cache elliptic curve primitives and hashes.
 * Calling this internally from another function will lead to memory
 * mutation and undefined behaviour.
 * The intended use case is to call this externally via `staticcall`. External
 * calls to OptimizedAZTEC can be treated as pure functions as this contract
 * contains no storage and makes no external calls (other than to precompiles)
 * 
 * Copyright 2020 Spilsbury Holdings Ltd 
 *
 * Licensed under the GNU Lesser General Public Licence, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/
contract Swap {

    /**
     * @dev Swap will take any transaction sent to it and attempt to validate a zero knowledge proof.
     * If the proof is not valid, the transaction throws.
     * @notice See SwapInterface for how method calls should be constructed.
     * This contract is written in YUL to enable manual memory management and for other efficiency savings.
     **/
    // solhint-disable payable-fallback
    function() external {
        assembly {

            // We don't check for function signatures, there's only one function that
            // ever gets called: validateSwap()
            // We still assume calldata is offset by 4 bytes so that we can represent
            // this contract through a comp\atible ABI
            validateSwap()

            // if we get to here, the proof is valid. We now 'fall through' the assembly block
            // and into JoinSplitABI.validateJoinSplit()
            // reset the free memory pointer because we're touching Solidity code again
            mstore(0x40, 0x60)
            /**
             * New calldata map
             * 0x04:0x24      = calldata location of proofData byte array
             * 0x24:0x44      = message sender // sender
             * 0x44:0x64      = h_x     // crs
             * 0x64:0x84      = h_y     // crs
             * 0x84:0xa4      = t2_x0   // crs
             * 0xa4:0xc4      = t2_x1   // crs
             * 0xa4:0xc4      = t2_x1   // crs
             * 0xc4:0xe4      = t2_y0   // crs
             * 0xe4:0x104     = t2_y1   // crs
             * 0x104:0x124    = length of proofData byte array
             * 0x124:0x144    = challenge
             * 0x144:0x164    = offset in byte array to notes
             * 0x164:0x184    = offset in byte array to inputOwners
             * 0x184:0x1a4    = offset in byte array to outputOwners
             * 0x1a4:0x1c4    = offset in byte array to metadata
             *
             *
             * Note data map (uint[6]) is
             * 0x00:0x20       = Z_p element \bar{k}_i
             * 0x20:0x40       = Z_p element \bar{a}_i
             * 0x40:0x80       = G1 element \gamma_i
             * 0x80:0xc0       = G1 element \sigma_i
             *
             * We use a hard-coded memory map to reduce gas costs - if this is not called as an
             * external contract then terrible things will happen!
             *
             * 0x00:0x20       = scratch data to store result of keccak256 calls
             * 0x20:0x80       = scratch data to store \gamma_i and a multiplication scalar
             * 0x80:0xc0       = x-coordinate of generator h
             * 0xc0:0xe0       = y-coordinate of generator h
             * 0xe0:0x100      = scratch data to store a scalar we plan to multiply h by
             * 0x100:0x160     = scratch data to store \sigma_i and a multiplication scalar
             * 0x160:0x1a0     = stratch data to store result of G1 point additions
             * 0x1a0:0x1c0     = scratch data to store result of \sigma_i^{-cx_{i-m-1}}
             * 0x220:0x260     = scratch data to store \gamma_i^{cx_{i-m-1}}
             * 0x2e0:0x300     = msg.sender (contract should be called via delegatecall/staticcall)
             * 0x300:???       = block of memory that contains (\gamma_i, \sigma_i)_{i=0}^{n-1}
             *                   concatenated with (B_i)_{i=0}^{n-1}
             **/
            function validateSwap() {
                /*
                ///////////////////////////////////////////  SETUP  //////////////////////////////////////////////
                */

                mstore(0x80, calldataload(0x44)) // h_x
                mstore(0xa0, calldataload(0x64)) // h_y
                let notes := add(0x104, calldataload(0x144)) // start position of notes
                let n := calldataload(notes) // first element of the notes array is it's length

                if iszero(eq(n, 0x04)) { // eq(n, 4) will resolve to 0 if n != 4

                    mstore(0x00, 400) // 400 error code - due to incorrect number of notes supplied
                    revert(0x00, 0x20)

                }

                let gen_order := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
                let challenge := mod(calldataload(0x124), gen_order)

                mstore(0x2e0, calldataload(0x24)) // store the msg.sender, to be hashed later

                hashCommitments(notes, n)
                let b := add(0x300, mul(n, 0x80)) // set pointer to memory location of commitments where the commitments

                /*
                ///////////////////////////  CALCULATE BLINDING FACTORS  /////////////////////////////////////
                */
                let x := 1
                // Iterate over every note and calculate the blinding factor B_i = \gamma_i^{kBar}h^{aBar}\sigma_i^{-c}.
                for { let i := 0 } lt(i, n) { i := add(i, 0x01) } {

                    // Get the calldata index of this note and associated parameters
                    let noteIndex := add(add(notes, 0x20), mul(i, 0xc0))
                    let k
                    let a := calldataload(add(noteIndex, 0x20))
                    let c := challenge

                    switch gt(i, 1) // i (an indexer) > 1 denotes a taker note
                    case 1 { // if it's a taker note

                        // indexing the k value of the note that is 2 indices behind the current note
                        k := calldataload(sub(noteIndex, 0x180))
                    }

                    case 0 { // if it's a maker note
                        k := calldataload(noteIndex)
                    }


                    // Check this commitment is well formed
                    validateCommitment(noteIndex, k, a)

                    x := mulmod(x, mload(0x00), gen_order)
                    // Set k = kx_j, a = ax_j, c = cx_j, where j = note index
                    if gt(i, 0) {
                        k := mulmod(k, x, gen_order)
                        a := mulmod(a, x, gen_order)
                        c := mulmod(challenge, x, gen_order)
                    } 

                    // Calculate the G1 element \gamma_i^{k}h^{a}\sigma_i^{-c} = B_i
                    // Memory map:
                    // 0x20: \gamma_iX
                    // 0x40: \gamma_iY
                    // 0x60: k_i
                    // 0x80: hX
                    // 0xa0: hY
                    // 0xc0: a_i
                    // 0xe0: \sigma_iX
                    // 0x100: \sigma_iY
                    // 0x120: -c

                    // loading into memory
                    calldatacopy(0xe0, add(noteIndex, 0x80), 0x40)
                    calldatacopy(0x20, add(noteIndex, 0x40), 0x40)
                    mstore(0x120, sub(gen_order, c))
                    mstore(0x60, k)
                    mstore(0xc0, a)

                    // Call bn128 scalar multiplication precompiles
                    // Represent point + multiplication scalar in 3 consecutive blocks of memory
                    // Store \sigma_i^{-c} at 0x1a0:0x200
                    // Store \gamma_i^{k} at 0x120:0x160
                    // Store h^{a} at 0x160:0x1a0
                    let result := staticcall(gas, 7, 0xe0, 0x60, 0x1a0, 0x40)
                    result := and(result, staticcall(gas, 7, 0x20, 0x60, 0x120, 0x40))
                    result := and(result, staticcall(gas, 7, 0x80, 0x60, 0x160, 0x40))

                    // Call bn128 group addition precompiles
                    // \gamma_i^{k} and h^{a} in memory block 0x120:0x1a0
                    // Store result of addition at 0x160:0x1a0
                    result := and(result, staticcall(gas, 6, 0x120, 0x80, 0x160, 0x40))

                    // \gamma_i^{k}h^{a} and \sigma^{-c} in memory block 0x160:0x1e0
                    // Store resulting point B at memory index b
                    result := and(result, staticcall(gas, 6, 0x160, 0x80, b, 0x40))

                    if eq(i, 0) { // m = 0
                        mstore(0x260, mload(0x20)) //  gamma_iX
                        mstore(0x280, mload(0x40)) // gamma_iY
                        mstore(0x1e0, mload(0xe0)) // sigma_iX
                        mstore(
                            0x200,
                            sub(0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47, mload(0x100))
                            )
                    }

                    // If i > 0 (i.e. all notes other than the first)
                    // then we add \sigma^{-c} and \sigma_{acc} and store result at \sigma_{acc} (0x1e0:0x200)
                    // we then calculate \gamma^{cx} and add into \gamma_{acc}
                    if gt(i, 0) {
                        mstore(0x60, c)

                        result := and(
                            result,
                            and(
                                and(
                                    staticcall(gas, 6, 0x1a0, 0x80, 0x1e0, 0x40), // \sigma_i^{-cx_{i-m-1}}
                                    staticcall(gas, 6, 0x220, 0x80, 0x260, 0x40) // \gamma_i^{cx_{i-m-1}}
                                ),
                                staticcall(gas, 7, 0x20, 0x60, 0x220, 0x40) // \gamma_i^k
                            )
                        )
                    }


                    // throw transaction if any calls to precompiled contracts failed
                    if iszero(result) { mstore(0x00, 400) revert(0x00, 0x20) }
                    b := add(b, 0x40) // increase B pointer by 2 words
                }
                
                validatePairing(0x84)


                /*
                ////////////////////  RECONSTRUCT INITIAL CHALLENGE AND VERIFY A MATCH  ////////////////////////////////
                */

                // We now have the note commitments and the calculated blinding factors in a block of memory
                // starting at 0x2e0, of size (b - 0x2e0).
                // Hash this block to reconstruct the initial challenge and validate that they match
                let expected := mod(keccak256(0x2e0, sub(b, 0x2e0)), gen_order)

                if iszero(eq(expected, challenge)) {

                    // No! Bad! No soup for you!
                    mstore(0x00, 404)
                    revert(0x00, 0x20)
                }
            }

             /**        
             * @dev evaluate if e(P1, t2) . e(P2, g2) == 0.
             * @notice we don't hard-code t2 so that contracts that call this library can use
             * different trusted setups.
             **/
            function validatePairing(t2) {
                let field_order := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                let t2_x_1 := calldataload(t2)
                let t2_x_2 := calldataload(add(t2, 0x20))
                let t2_y_1 := calldataload(add(t2, 0x40))
                let t2_y_2 := calldataload(add(t2, 0x60))

                // check provided setup pubkey is not zero or g2
                if or(or(or(or(or(or(or(
                    iszero(t2_x_1),
                    iszero(t2_x_2)),
                    iszero(t2_y_1)),
                    iszero(t2_y_2)),
                    eq(t2_x_1, 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed)),
                    eq(t2_x_2, 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2)),
                    eq(t2_y_1, 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa)),
                    eq(t2_y_2, 0x90689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b))
                {
                    mstore(0x00, 400)
                    revert(0x00, 0x20)
                }

                // store coords in memory
                // indices are a bit off, scipr lab's libff limb ordering (c0, c1) is opposite
                // to what precompile expects
                // We can overwrite the memory we used previously as this function is called at the
                // end of the validation routine.
                mstore(0x20, mload(0x1e0)) // sigma accumulator x
                mstore(0x40, mload(0x200)) // sigma accumulator y
                mstore(0x80, 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed)
                mstore(0x60, 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2)
                mstore(0xc0, 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa)
                mstore(0xa0, 0x90689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b)
                mstore(0xe0, mload(0x260)) // gamma accumulator x
                mstore(0x100, mload(0x280)) // gamma accumulator y
                mstore(0x140, t2_x_1)
                mstore(0x120, t2_x_2)
                mstore(0x180, t2_y_1)
                mstore(0x160, t2_y_2)

                let success := staticcall(gas, 8, 0x20, 0x180, 0x20, 0x20)

                if or(iszero(success), iszero(mload(0x20))) {
                    mstore(0x00, 400)
                    revert(0x00, 0x20)
                }
            }

            /**
             * @dev check that this note's points are on the altbn128 curve(y^2 = x^3 + 3)
             * and that signatures 'k' and 'a' are modulo the order of the curve. Transaction
             * throws if this is not the case.
             * @param note the calldata loation of the note
             **/
            function validateCommitment(note, k, a) {
                let gen_order := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
                let field_order := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                let gammaX := calldataload(add(note, 0x40))
                let gammaY := calldataload(add(note, 0x60))
                let sigmaX := calldataload(add(note, 0x80))
                let sigmaY := calldataload(add(note, 0xa0))
                if iszero(
                    and(
                        and(
                            and(
                                eq(mod(a, gen_order), a), // a is modulo generator order?
                                gt(a, 1)                  // can't be 0 or 1 either!
                            ),
                            and(
                                eq(mod(k, gen_order), k), // k is modulo generator order?
                                gt(k, 1)                  // and not 0 or 1
                            )
                        ),
                        and(
                            eq( // y^2 ?= x^3 + 3
                                addmod(mulmod(
                                    mulmod(sigmaX, sigmaX, field_order), sigmaX, field_order),
                                    3,
                                    field_order),
                                mulmod(sigmaY, sigmaY, field_order)
                            ),
                            eq( // y^2 ?= x^3 + 3
                                addmod(mulmod(
                                    mulmod(gammaX, gammaX, field_order),
                                    gammaX,
                                    field_order),
                                    3, field_order),
                                mulmod(gammaY, gammaY, field_order)
                            )
                        )
                    )
                ) {
                    mstore(0x00, 400)
                    revert(0x00, 0x20)
                }
            }

            /**
             * @dev Calculate the keccak256 hash of the commitments for both
             * input notes and output notes. This is used both as an input to
             * validate the challenge `c` and also to generate pseudorandom relationships
             * between commitments for different outputNotes, so that we can combine
             * them into a single multi-exponentiation for the purposes of validating
             * the bilinear pairing relationships.
             * @param notes calldata location notes
             * @param n number of notes
             **/
            function hashCommitments(notes, n) {
                for { let i := 0 } lt(i, n) { i := add(i, 0x01) } {
                let index := add(add(notes, mul(i, 0xc0)), 0x60)
                calldatacopy(add(0x300, mul(i, 0x80)), index, 0x80)
                }
                // storing at position 0x00 in memory, the kecca hash of everything from
                // start of the commitments to the end
                mstore(0x00, keccak256(0x300, mul(n, 0x80)))
            }
        }
        // if we've reached here, we've validated the Swap and haven't thrown an error.
        // Encode the output according to the ACE standard and exit.
        SwapABIEncoder.encodeAndExit();
    }
}