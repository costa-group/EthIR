pragma solidity 0.5.7;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : dave@akomba.com
// released under Apache 2.0 licence
contract Basket {
    address[] public tokens;
    mapping(address => uint256) public weights; // unit: aqToken/RSV
    mapping(address => bool) public has;
    // INVARIANT: {addr | addr in tokens} == {addr | has[addr] == true}
    
    // SECURITY PROPERTY: The value of prev is always a Basket, and cannot be set by any user.
    
    // WARNING: A basket can be of size 0. It is the Manager's responsibility
    //                    to ensure Issuance does not happen against an empty basket.

    /// Construct a new basket from an old Basket `prev`, and a list of tokens and weights with
    /// which to update `prev`. If `prev == address(0)`, act like it's an empty basket.
    constructor(Basket trustedPrev, address[] memory _tokens, uint256[] memory _weights) public {
        require(_tokens.length == _weights.length, "Basket: unequal array lengths");

        // Initialize data from input arrays
        tokens = new address[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(!has[_tokens[i]], "duplicate token entries");
            weights[_tokens[i]] = _weights[i];
            has[_tokens[i]] = true;
            tokens[i] = _tokens[i];
        }

        // If there's a previous basket, copy those of its contents not already set.
        if (trustedPrev != Basket(0)) {
            for (uint256 i = 0; i < trustedPrev.size(); i++) {
                address tok = trustedPrev.tokens(i);
                if (!has[tok]) {
                    weights[tok] = trustedPrev.weights(tok);
                    has[tok] = true;
                    tokens.push(tok);
                }
            }
        }
        require(tokens.length <= 10, "Basket: bad length");
    }

    function getTokens() external view returns(address[] memory) {
        return tokens;
    }

    function size() external view returns(uint256) {
        return tokens.length;
    }
}