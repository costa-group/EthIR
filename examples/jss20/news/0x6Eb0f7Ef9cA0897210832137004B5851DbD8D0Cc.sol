pragma solidity ^0.4.24;

/*
    Bet2Moon Dice Game Verifier
    Author: GMEB
*/

interface Verifier {
    function DICE_VERIFIER(bytes calldata)
        external
        view
        returns (
            bytes32,
            bytes32,
            bytes32,
            uint);
}

contract DiceVerifier {
    Verifier private verifier;
    constructor () public {
        verifier = Verifier(0x85b7438d2C7728C2218f9133cFA99D44608599B0);
    }

    function DICE_VERIFIER(bytes memory PASTE_YOUR_PROOF_HERE)
        public
        view
        returns(
            bytes32 Commited_Hash,
            bytes32 Secret,
            string memory Network,
            bytes32 Block_Hash,
            uint DICE_RESULT)
    {
        Network = "TRON";
        (
            Commited_Hash,
            Secret,
            Block_Hash,
            DICE_RESULT) = verifier.DICE_VERIFIER(PASTE_YOUR_PROOF_HERE);
    }
}