
// File: contracts/ACE/validators/joinSplitFluid/JoinSplitFluidABIEncoder.sol

pragma solidity >=0.5.0 <0.6.0;


/**
 * @title JoinSplitFluidABIEncoder
 * @author AZTEC
 * @dev
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
library JoinSplitFluidABIEncoder {
    /**
     * Calldata map
     * 0x04:0x24      = calldata location of proofData byte array
     * 0x24:0x44      = message sender
     * 0x44:0x64      = h_x
     * 0x64:0x84      = h_y
     * 0x84:0xa4      = t2_x0
     * 0xa4:0xc4      = t2_x1
     * 0xc4:0xe4      = t2_y0
     * 0xe4:0x104     = t2_y1
     * 0x104:0x124    = length of proofData byte array
     * 0x124:0x144    = challenge
     * 0x144:0x164    = offset in byte array to notes
     * 0x164:0x184    = offset in byte array to inputOwners
     * 0x184:0x1a4    = offset in byte array to outputOwners
     * 0x1a4:0x1c4    = offset in byte array to metadata
     */


    function encodeAndExit() internal pure {
        assembly {
            // set up initial variables
            let notes := add(0x104, calldataload(0x144))
            let n := calldataload(notes)
            let inputOwners := add(0x124, calldataload(0x164)) // one word after input owners = 1st
            let outputOwners := add(0x124, calldataload(0x184)) // one word after outputOwners = 1st
            let metadata := add(0x144, calldataload(0x1a4)) // two words after metadata = 1st

            // memory map of `proofOutputs`

            // `returndata` starts at 0x160
            // `proofOutputs` starts at 0x180
            // 0x160 - 0x180 = relative offset in returndata to first bytes argument (0x20)
            // 0x180 - 0x1a0 = byte length of `proofOutputs`
            // 0x1a0 - 0x1c0 = number of `proofOutputs` entries (2)
            // 0x1c0 - 0x1e0 = relative memory offset between `v` and start of `proofOutput`

            // `proofOutput A` - t, starts at 0x1e0
            // 0x1e0 - 0x200 = length of `proofOutputA`
            // 0x200 - 0x220 = relative offset between `t` and `inputNotes`
            // 0x220 - 0x240 = relative offset between `t` and `outputNotes`
            // 0x240 - 0x260 = `publicOwner`
            // 0x260 - 0x280 = `publicValue`
            // 0x280 - 0x2a0 = `challenge`

            // `inputNotes A` starts at 0x2a0
            // structure of `inputNotes` and `outputNotes`
            // 0x00 - 0x20 = byte length of notes array
            // 0x20 - 0x40 = number of notes `i`
            // the next `i` consecutive blocks of 0x20-sized memory contain relative offset between
            // start of notes array and the location of the `note`

            // `proofOutput B` - r
            // 0x00 - 0x20 = length of `proofOutput B`
            // 0x20 - 0x40 = relative offset between `r` and `inputNotes`
            // 0x40 - 0x60 = relative offset between `r` and `outputNotes`
            // 0x60 - 0x80 = `publicOwner`
            // 0x80 - 0xa0 = `publicValue`
            // 0xa0 - 0xc0 = `challenge`

            // 'inputNotes B'
            // structure of `inputNotes` and `outputNotes`
            // 0x00 - 0x20 = byte length of notes array
            // 0x20 - 0x40 = number of notes `i`
            // the next `i` consecutive blocks of 0x20-sized memory contain relative offset between
            // start of notes array and the location of the `note`

            // structure of a `note`
            // 0x00 - 0x20 = size of `note`
            // 0x20 - 0x40 = `noteType`
            // 0x40 - 0x60 = `owner`
            // 0x60 - 0x80 = `noteHash`
            // 0x80 - 0xa0 = size of note `data`
            // 0xa0 - 0xc0 = compressed note coordinate `gamma` (part of `data`)
            // 0xc0 - 0xe0 = compressed note coordinate `sigma` (part of `data`)
            // 0xe0 - ???? = remaining note metadata

            // `proofOutputs` must form a monolithic block of memory that we can return.
            // `s` points to the memory location of the start of the current note
            // `inputPtr` points to the start of the current `notes` dynamic bytes array

            // length of proofOutputs is at s
            mstore(0x1a0, 0x02)                            // there are two proofOutput objects for a join-split fluid
            mstore(0x1c0, 0x80)                            // offset to 1st proof
            // 0x1e0 = offset to 2nd proof
            // length of proofOutput is at s + 0x60
            mstore(0x220, 0xc0)                            // location of inputNotes
            mstore(0x260, 0x00)                            // publicOwner is 0
            mstore(0x280, 0x00)                            // publicValue is 0

            mstore(0x2a0, calldataload(0x124))

            // set note pointer, offsetting lookup indices for each input note

            /////////////////// PROOF OUTPUT A: START OF INPUT NOTES //////////////////
            // 0x2c0 = number of bytes in `inputNotes` (leave blank for now)
            // 0x2e0 = number of input notes
            mstore(0x2e0, 0x01)

            // 0x300 = relative offset to 1st input note (0x60)
            mstore(0x300, 0x60)

            // Start of inputNote[0]
            // get pointer to metadata
            let metadataIndex := calldataload(metadata)

            // copy note data to 0x20 - 0xa0
            mstore(0x00, 0x01)
            calldatacopy(0x20, add(notes, 0x120), 0x80) // get gamma, sigma

            // store note length in `s` = 0x320
            mstore(0x320, 0xc0)
            // store note type (UXTO type, 0x01) in `s + 0x20`
            mstore(0x340, 0x01)
            // store the owner of the note in `s + 0x40`
            mstore(0x360, calldataload(outputOwners))
            // store note hash
            mstore(0x380, keccak256(0x00, 0xa0))
            // store noteData length in `s + 0x80`
            mstore(0x3a0, 0x40)
            // store compressed note coordinate gamma in `s + 0xa0`
            mstore(
                0x3c0,
                or(
                    mload(0x20),
                    shl(255, and(mload(0x40), 0x01))
                )
            )
            // store compressed note coordinate sigma in `s + 0xc0`
            mstore(
                0x3e0,
                or(
                    mload(0x60),
                    shl(255, and(mload(0x80), 0x01))
                )
            )
            // inputNote, so no metaData to store

            // store relative memory offset to outputNotes
            mstore(0x240, 0x200)
            // store the length of inputNotes at 0x2c0
            mstore(0x2c0, 0x120)
            ///////////////// PROOF OUTPUT A: START OF OUTPUT NOTES (1) ///////////////////

            // transition between input and output notes

            // 0x400 + metadataLength = byte length of output notes (0x120)
            // 0x420 + metadataLength = # of output notes (1)
            // 0x440 + metadataLength = offset to outputNotes[0] (0x60)
            let metadataLength := calldataload(add(metadataIndex, sub(metadata, 0x40)))

            mstore(0x400, add(0x120, metadataLength)) // store length of output notes
            mstore(0x420, 0x01) // store number of output notes
            mstore(0x440, 0x60) // store offset to outputNotes[0]

            // construct note hash
            // copy 1st note note to 0x20 - 0xa0
            calldatacopy(0x20, add(notes, 0x60), 0x80) // get gamma, sigma

            // store note length in `s`
            mstore(0x460, add(0xc0, metadataLength))
            // store note type (UXTO type, 0x01) in `s + 0x20`
            mstore(0x480, 0x01)
            // store note owner in `s + 0x40`
            mstore(0x4a0, calldataload(inputOwners))
            // store note hash in `s + 0x60`
            mstore(0x4c0, keccak256(0x00, 0xa0))
            // store note metadata length in `s + 0x80` (just the coordinates)
            mstore(0x4e0, add(0x40, metadataLength))
            // store compressed note coordinate gamma in `s + 0xa0`
            mstore(
                0x500,
                or(
                    mload(0x20),
                    shl(255, and(mload(0x40), 0x01))
                )
            )
            // store compressed note coordinate sigma in `s + 0xc0`
            mstore(
                0x520,
                or(
                    mload(0x60),
                    shl(255, and(mload(0x80), 0x01))
                )
            )

            calldatacopy(0x540, add(metadataIndex, sub(metadata, 0x20)), metadataLength)

            // compute the relative offset to index this note in our returndata
            mstore(add(0x440, 0), 0x60) // relative offset to note

            // now we need to transition between first and second proofOutput
            // s is going to point to the end of the outputNotes array
            // so, s is our absolute pointer to the start of the 2nd proofOutputs entry
            // we know that 'proofOutputs' starts at 0x180
            // so (s - 0x180) = relative offset to second proofOutputs entry
            let startOfProofOutput := add(0x540, metadataLength)

            // proofOutput[0].length = start of proofOutput[1] - start of proofOutput[0] - 0x20
            // proofOutput[0].length = (0x540 + metadataLength) - 0x200 - 0x20 = 0x320 + metadataLength
            mstore(0x200, add(0x320, metadataLength)) // length of proofOutput
            mstore(0x1e0, add(0x3c0, metadataLength)) // offset to get to second proofOutput

            // s points to the start of proofOutputs[0]
            let s := startOfProofOutput
            mstore(add(s, 0x20), 0xc0)   // location of inputNotes
            mstore(add(s, 0x40), 0x100)  // location of outputNotes
            mstore(add(s, 0x60), 0x00)   // publicOwner
            mstore(add(s, 0x80), 0x00)   // publicValue

            // compute challenge = kecck256(challenge)
            mstore(0x20, calldataload(0x124))
            mstore(add(s, 0xa0), keccak256(0x20, 0x20)) // challenge
            // 0x00 length of proofOutput
            // 0x20 location of inputNotes
            // 0x40 location of outputNotes
            // 0x60 publicOwner
            // 0x80 publicValue
            // 0xa0 = inputNoteData
            mstore(add(s, 0xc0), 0x20) // length of input notes array (1 word)
            mstore(add(s, 0xe0), 0x00) // number of entries (0 words)

            // set notesPtr = proofOutputs[1].outputNotes
            let notesPtr := add(s, 0x100)

            // s + 0x20 = number of notes = n - 2
            mstore(add(notesPtr, 0x20), sub(n, 2))

            // set s to point to proofOutputs[1].outputNotes[0]
            s := add(add(s, 0x140), mul(0x20, sub(n, 2)))

            // Output notes:
            // first output note needs to go into the first proofOutput object
            // second output note onwards, needs to go into the second proofOutput object
            for { let i := 0x02 } lt(i, n) { i := add(i, 0x01) } {

            /////////////////// START OF PROOF OUTPUT B  ////////////////////

                // get pointer to metadata
                metadataIndex := calldataload(add(metadata, mul(sub(i, 0x01), 0x20)))
                // get size of metadata
                metadataLength := calldataload(add(sub(metadata, 0x40), metadataIndex))

                mstore(0x00, 0x01)
                // copy note data to 0x20 - 0xa0
                calldatacopy(
                    0x20,
                    add(add(notes, 0x60), mul(i, 0xc0)),
                    0x80
                ) // get gamma, sigma

                // store note length in `s`
                mstore(s, add(0xc0, metadataLength))
                // store note type (UXTO type, 0x01) in `s + 0x20`
                mstore(add(s, 0x20), 0x01)
                // store the owner of the note in `s + 0x40`
                mstore(add(s, 0x40), calldataload(add(outputOwners, mul(sub(i, 0x01), 0x20))))
                // store note hash
                mstore(add(s, 0x60), keccak256(0x00, 0xa0))
                // store note metadata length if `s + 0x80`
                mstore(add(s, 0x80), add(0x40, metadataLength))
                // store compressed note coordinate gamma in `s + 0xa0`
                mstore(
                    add(s, 0xa0),
                    or(
                        mload(0x20),
                        shl(255, and(mload(0x40), 0x01))
                    )
                )
                // store compressed note coordinate sigma in `s + 0xc0`
                mstore(
                    add(s, 0xc0),
                    or(
                        mload(0x60),
                        shl(255, and(mload(0x80), 0x01))
                    )
                )
                // copy metadata into `s + 0xe0`
                calldatacopy(add(s, 0xe0), add(metadataIndex, sub(metadata, 0x20)), metadataLength)
                // compute the relative offset to index this note in our returndata
                mstore(add(notesPtr, mul(i, 0x20)), sub(s, notesPtr)) // relative offset to note

                // increase s by note length
                s := add(s, add(mload(s), 0x20))
            }

            // inputPtr used to point to start of inputNotes for proofOutputs[0]
            // now we want inputPtr to point to start of inputNotes for proofOutputs[1]
            // 1. length of proofOutput
            // 2. length of outputNotes
            // length of outputNotes = s - inputPtr, stored at inputPtr
            mstore(notesPtr, sub(sub(s, notesPtr), 0x20)) // store length of outputNotes at start of outputNotes
            // length of proofOutput
            let proofOutputLength := sub(s, startOfProofOutput)
            mstore(startOfProofOutput, sub(proofOutputLength, 0x20))
            mstore(0x180, sub(s, 0x1a0)) // store length of proofOutputs at 0x100
            mstore(0x160, 0x20)
            return(0x160, sub(s, 0x160)) // return the final byte array
        }
    }
}

// File: contracts/libs/LibEIP712.sol

pragma solidity >=0.5.0 <0.6.0;


/**
 * @title Library of EIP712 utility constants and functions
 * @author AZTEC
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
contract LibEIP712 {

    // EIP712 Domain Name value
    string constant internal EIP712_DOMAIN_NAME = "AZTEC_CRYPTOGRAPHY_ENGINE";

    // EIP712 Domain Version value
    string constant internal EIP712_DOMAIN_VERSION = "1";

    // Hash of the EIP712 Domain Separator Schema
    bytes32 constant internal EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(abi.encodePacked(
        "EIP712Domain(",
            "string name,",
            "string version,",
            "address verifyingContract",
        ")"
    ));

    // Hash of the EIP712 Domain Separator data
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public EIP712_DOMAIN_HASH;

    constructor ()
        public
    {
        EIP712_DOMAIN_HASH = keccak256(abi.encode(
            EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
            keccak256(bytes(EIP712_DOMAIN_NAME)),
            keccak256(bytes(EIP712_DOMAIN_VERSION)),
            address(this)
        ));
    }

    /// @dev Calculates EIP712 encoding for a hash struct in this EIP712 Domain.
    /// @param _hashStruct The EIP712 hash struct.  
    /// @return EIP712 hash applied to this EIP712 Domain.
    function hashEIP712Message(bytes32 _hashStruct)
        internal
        view
        returns (bytes32 _result)
    {
        bytes32 eip712DomainHash = EIP712_DOMAIN_HASH;

        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     EIP191_HEADER,
        //     EIP712_DOMAIN_HASH,
        //     hashStruct
        // ));

        assembly {
            // Load free memory pointer. We're not going to use it - we're going to overwrite it!
            // We need 0x60 bytes of memory for this hash,
            // cheaper to overwrite the free memory pointer at 0x40, and then replace it, than allocating free memory
            let memPtr := mload(0x40)
            mstore(0x00, 0x1901)               // EIP191 header
            mstore(0x20, eip712DomainHash)     // EIP712 domain hash
            mstore(0x40, _hashStruct)          // Hash of struct
            _result := keccak256(0x1e, 0x42)   // compute hash
            // replace memory pointer
            mstore(0x40, memPtr)
        }
    }

    /// @dev Extracts the address of the signer with ECDSA.
    /// @param _message The EIP712 message.
    /// @param _signature The ECDSA values, v, r and s.
    /// @return The address of the message signer.
    function recoverSignature(
        bytes32 _message,
        bytes memory _signature
    ) internal view returns (address _signer) {
        bool result;
        assembly {
            // Here's a little trick we can pull. We expect `_signature` to be a byte array, of length 0x60, with
            // 'v', 'r' and 's' located linearly in memory. Preceeding this is the length parameter of `_signature`.
            // We *replace* the length param with the signature msg to get a memory block formatted for the precompile
            // load length as a temporary variable

            let byteLength := mload(_signature)

            // store the signature message
            mstore(_signature, _message)

            // load 'v' - we need it for a condition check
            // add 0x60 to jump over 3 words - length of bytes array, r and s
            let v := mload(add(_signature, 0x60))
            v := shr(248, v) // bitshifting, to resemble padLeft

            /**
            * Original memory map for input to precompile
            *
            * _signature : _signature + 0x20            message 
            * _signature + 0x20 : _signature + 0x40     r
            * _signature + 0x40 : _signature + 0x60     s
            * _signature + 0x60 : _signature + 0x80     v

            * Desired memory map for input to precompile
            *
            * _signature : _signature + 0x20            message 
            * _signature + 0x20 : _signature + 0x40     v
            * _signature + 0x40 : _signature + 0x60     r
            * _signature + 0x60 : _signature + 0x80     s
            */

            // move s to v position
            mstore(add(_signature, 0x60), mload(add(_signature, 0x40)))
            // move r to s position
            mstore(add(_signature, 0x40), mload(add(_signature, 0x20)))
            // move v to r position
            mstore(add(_signature, 0x20), v)
            result := and(
                and(
                    // validate signature length == 0x41
                    eq(byteLength, 0x41),
                    // validate v == 27 or v == 28
                    or(eq(v, 27), eq(v, 28))
                ),
                // validate call to precompile succeeds
                staticcall(gas, 0x01, _signature, 0x80, _signature, 0x20) 
            )
            // save the _signer only if the first word in _signature is not `_message` anymore
            switch eq(_message, mload(_signature))
            case 0 {
                _signer := mload(_signature)
            }
            mstore(_signature, byteLength) // and put the byte length back where it belongs
        }
        // wrap Failure States in a single if test, so that happy path only has 1 conditional jump
        if (!(result && (_signer != address(0x0)))) {
            require(_signer != address(0x0), "signer address cannot be 0");
            require(result, "signature recovery failed");
        }
    }
}

// File: contracts/interfaces/JoinSplitFluidInterface.sol

pragma solidity >=0.5.0 <0.6.0;


/**
 * @title JoinSplitFluidInterface
 * @author AZTEC
 * @dev Interface for the JoinSplitFluid validator contract
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
contract JoinSplitFluidInterface is LibEIP712 {
    /* solhint-disable-next-line var-name-mixedcase */

    constructor() public {}

    function validateJoinSplitFluid(
        bytes calldata, // proof data
        address, // sender address
        uint[6] calldata // common reference string
    )
        external
        pure
        returns (bytes memory) // returns a series of transfer instructions
    {}
}

// File: contracts/ACE/validators/joinSplitFluid/JoinSplitFluid.sol

pragma solidity >=0.5.0 <0.6.0;




/**
 * @title JoinSplitFluid
 * @author AZTEC
 * @dev Library to validate AZTEC JoinSplitFluid zero-knowledge proofs
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
contract JoinSplitFluid is LibEIP712 {
    /**
     * @dev AZTEC will take any transaction sent to it and attempt to validate a zero knowledge proof.
     * If the proof is not valid, the transaction throws.
     * @notice See AZTECInterface for how method calls should be constructed.
     * 'Cost' of raw elliptic curve primitives for a transaction:
     * 260,700 gas + (124,500 * number of input notes) + (167,600 * number of output notes).
     * For a basic 'JoinSplitFluid' with 2 inputs and 2 outputs = 844,900 gas.
     * AZTEC is written in YUL to enable manual memory management and for other efficiency savings.
     **/
    function() external payable {
        assembly {
            // We don't check for function signatures,
            // there's only one function that ever gets called: validateJoinSplitFluid()
            // We still assume calldata is offset by 4 bytes so that we can represent this contract
            // through a compatible ABI
            validateJoinSplitFluid()

            /**
             * New calldata map
             * 0x04:0x24      = calldata location of proofData byte array
             * 0x24:0x44      = message sender
             * 0x44:0x64      = h_x
             * 0x64:0x84      = h_y
             * 0x84:0xa4      = t2_x0
             * 0xa4:0xc4      = t2_x1
             * 0xc4:0xe4      = t2_y0
             * 0xe4:0x104     = t2_y1
             * 0x104:0x124    = length of proofData byte array
             * 0x124:0x144    = challenge
             * 0x144:0x164    = offset in byte array to notes
             * 0x164:0x184    = offset in byte array to inputOwners
             * 0x184:0x1a4    = offset in byte array to outputOwners
             * 0x1a4:0x1c4    = offset in byte array to metadata
             */
            function validateJoinSplitFluid() {
                mstore(0x80, calldataload(0x44))
                mstore(0xa0, calldataload(0x64))
                let notes := add(0x104, calldataload(0x144)) // get the length of notes
                let m := 1
                let n := calldataload(notes)
                let gen_order := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
                let challenge := mod(calldataload(0x124), gen_order)


                // validate m < n
                if gt(m, n) {
                    mstore(0x00, 404)
                    revert(0x00, 0x20)
                }

                if eq(m, n) {
                    mstore(0x00, 404)
                    revert(0x00, 0x20)
                }

                let kn := 0

                // add sender final hash table
                mstore(0x2a0, calldataload(0x24))
                mstore(0x2c0, 0) // add kPublic = 0 to hash table
                mstore(0x2e0, m) // add m to final hash table

                hashCommitments(notes, n)  // notes = length of proof data array, n = number of notes
                let b := add(0x300, mul(n, 0x80))

                let x := 1
                // Iterate over every note and calculate the blinding factor B_i = \gamma_i^{kBar}h^{aBar}\sigma_i^{-c}.
                // We use the AZTEC protocol pairing optimization to reduce the number of pairing comparisons to 1,
                //  which adds some minor alterations
                for { let i := 0 } lt(i, n) { i := add(i, 0x01) } {

                // Get the calldata index of this note
                let noteIndex := add(add(notes, 0x20), mul(i, 0xc0))

                // Define variables k, a and c.
                // If i <= m then
                //   k = kBar_i
                //   a = aBar_i
                //   c = challenge
                // If i > m then we add a modification for the pairing optimization
                //   k = kBar_i * x_i
                //   a = aBar_i * x_i
                //   c = challenge * x_i
                // Set j = i - (m + 1).
                // x_0 = 1
                // x_1 = keccak256(input string)
                // all other x_{j} = keccak256(x_{j-1})
                // The reason for doing this is that the point  \sigma_i^{-cx_j} can be re-used in the pairing check
                // Instead of validating e(\gamma_i, t_2) == e(\sigma_i, g_2) for all i = [m+1,\ldots,n]
                // We validate e(\Pi_{i=m+1}^{n}\gamma_i^{-cx_j}, t_2) == e(\Pi_{i=m+1}^{n}\sigma_i^{cx_j}, g_2).
                // x_j is a pseudorandom variable whose entropy source is the input string, allowing for
                // a sum of commitment points to be evaluated in one pairing comparison
                let k
                let a := calldataload(add(noteIndex, 0x20))
                let c := challenge

                switch eq(add(i, 0x01), n)
                    case 1 {
                        k := kn
                    }
                    case 0 { k := calldataload(noteIndex) }


                // Check this commitment is well formed...
                validateCommitment(noteIndex, k, a)


                x := mulmod(x, mload(0x00), gen_order)
                // If i > m then this is an output note.
                // Set k = kx_j, a = ax_j, c = cx_j, where j = i - (m+1)
                switch gt(add(i, 0x01), m)
                case 1 {
                    // before we update k, update kn = \sum_{i=0}^{m-1}k_i - \sum_{i=m}^{n-1}k_i
                    kn := addmod(kn, sub(gen_order, k), gen_order)

                    k := mulmod(k, x, gen_order)
                    a := mulmod(a, x, gen_order)
                    c := mulmod(challenge, x, gen_order)
                }

                case 0 {

                    // nothing to do here except update kn = \sum_{i=0}^{m-1}k_i - \sum_{i=m}^{n-1}k_i
                    kn := addmod(kn, k, gen_order)
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

                // We have \sigma^{-c} at 0x1a0:0x200
                // And \sigma_{acc} at 0x1e0:0x200
                // If i = m + 1 (i.e. first output note)
                // then we set \gamma_{acc} and \sigma_{acc} to \gamma_i, -\sigma_i
                if eq(i, m) {
                    mstore(0x260, mload(0x20))
                    mstore(0x280, mload(0x40))
                    mstore(0x1e0, mload(0xe0))
                    mstore(0x200, sub(0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47, mload(0x100)))
                }

                // If i > m + 1 (i.e. subsequent output notes)
                // then we add \sigma^{-c} and \sigma_{acc} and store result at \sigma_{acc} (0x1e0:0x200)
                // we then calculate \gamma^{cx} and add into \gamma_{acc}
                if gt(i, m) {
                    mstore(0x60, c)
                    result := and(result, staticcall(gas, 7, 0x20, 0x60, 0x220, 0x40))

                    // \gamma_i^{cx} now at 0x220:0x260, \gamma_{acc} is at 0x260:0x2a0
                    result := and(result, staticcall(gas, 6, 0x220, 0x80, 0x260, 0x40))

                    // add \sigma_i^{-cx} and \sigma_{acc} into \sigma_{acc} at 0x1e0
                    result := and(result, staticcall(gas, 6, 0x1a0, 0x80, 0x1e0, 0x40))
                }


                // throw transaction if any calls to precompiled contracts failed
                if iszero(result) { mstore(0x00, 400) revert(0x00, 0x20) }
                    b := add(b, 0x40) // increase B pointer by 2 words
                }

                // If the AZTEC protocol is implemented correctly then any input notes were previously outputs of
                // a JoinSplitFluid transaction. We can inductively assume that all input notes
                // are well-formed AZTEC commitments and do not need to validate the implicit range proof
                // This is not the case for any output commitments, so if (m < n) call validatePairing()
                if lt(m, n) {
                    validatePairing(0x84)
                }


                // We now have the note commitments and the calculated blinding factors in a block of memory
                // starting at 0x2a0, of size (b - 0x2a0).
                // Hash this block to reconstruct the initial challenge and validate that they match

                let expected := mod(keccak256(0x2a0, sub(b, 0x2a0)), gen_order)

                if iszero(eq(expected, challenge)) {

                    // No! Bad! No soup for you!
                    mstore(0x00, 404)
                    revert(0x00, 0x20)
                }

                // Great! All done. This is a valid proof, so fall through out of the assembly block
                // so that we can call `ABIEncoder.encodeAndExit`

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
             * and that signatures 'k' and 'a' are modulo the order of the curve.
             * Transaction throws if this is not the case.
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
                            addmod(
                                mulmod(mulmod(sigmaX, sigmaX, field_order), sigmaX, field_order),
                                3,
                                field_order
                            ),
                            mulmod(sigmaY, sigmaY, field_order)
                        ),
                        eq( // y^2 ?= x^3 + 3
                            addmod(
                                mulmod(mulmod(gammaX, gammaX, field_order), gammaX, field_order),
                                3,
                                field_order
                            ),
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
             * @dev Calculate the keccak256 hash of the commitments for both input notes and output notes.
             * This is used both as an input to validate the challenge `c` and also to
             * generate pseudorandom relationships
             * between commitments for different outputNotes, so that we can combine them
             * into a single multi-exponentiation for the purposes of validating the bilinear pairing relationships.
             * @param notes calldata location notes
             * @param n number of notes
             **/
            function hashCommitments(notes, n) {
                for { let i := 0 } lt(i, n) { i := add(i, 0x01) } {
                let index := add(add(notes, mul(i, 0xc0)), 0x60)
                calldatacopy(add(0x300, mul(i, 0x80)), index, 0x80)
                }
                mstore(0x00, keccak256(0x300, mul(n, 0x80)))
            }
        }

        // if we've reached here, we've validated the join-split transaction and haven't thrown an error.
        // Encode the output according to the ACE standard and exit.
        JoinSplitFluidABIEncoder.encodeAndExit();
    }
}
