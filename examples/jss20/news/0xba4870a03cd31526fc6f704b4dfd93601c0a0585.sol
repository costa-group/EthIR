pragma solidity 0.4.26;

contract Math {

    ////////////////////////
    // Internal functions
    ////////////////////////

    // absolute difference: |v1 - v2|
    function absDiff(uint256 v1, uint256 v2)
        internal
        pure
        returns(uint256)
    {
        return v1 > v2 ? v1 - v2 : v2 - v1;
    }

    // divide v by d, round up if remainder is 0.5 or more
    function divRound(uint256 v, uint256 d)
        internal
        pure
        returns(uint256)
    {
        return add(v, d/2) / d;
    }

    // computes decimal decimalFraction 'frac' of 'amount' with maximum precision (multiplication first)
    // both amount and decimalFraction must have 18 decimals precision, frac 10**18 represents a whole (100% of) amount
    // mind loss of precision as decimal fractions do not have finite binary expansion
    // do not use instead of division
    function decimalFraction(uint256 amount, uint256 frac)
        internal
        pure
        returns(uint256)
    {
        // it's like 1 ether is 100% proportion
        return proportion(amount, frac, 10**18);
    }

    // computes part/total of amount with maximum precision (multiplication first)
    // part and total must have the same units
    function proportion(uint256 amount, uint256 part, uint256 total)
        internal
        pure
        returns(uint256)
    {
        return divRound(mul(amount, part), total);
    }

    //
    // Open Zeppelin Math library below
    //

    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a > b ? a : b;
    }
}

/// @title uniquely identifies deployable (non-abstract) platform contract
/// @notice cheap way of assigning implementations to knownInterfaces which represent system services
///         unfortunatelly ERC165 does not include full public interface (ABI) and does not provide way to list implemented interfaces
///         EIP820 still in the making
/// @dev ids are generated as follows keccak256("neufund-platform:<contract name>")
///      ids roughly correspond to ABIs
contract IContractId {
    /// @param id defined as above
    /// @param version implementation version
    function contractId() public pure returns (bytes32 id, uint256 version);
}

// version history as per contract id
// 0 - initial version
// 1 - added SHARE_NOMINAL_VALUE_ULPS, SHARE_NOMINAL_VALUE_EUR_ULPS, TOKEN_NAME, TOKEN_SYMBOL, SHARE_PRICE


/// @title sets terms for tokens in ETO
contract ETOTokenTerms is Math, IContractId {

    ////////////////////////
    // Constants state
    ////////////////////////

    bytes32 private constant EMPTY_STRING_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // equity tokens decimals (precision)
    uint8 public constant EQUITY_TOKENS_PRECISION = 0; // indivisible

    ////////////////////////
    // Immutable state
    ////////////////////////

    // equity token metadata
    string public EQUITY_TOKEN_NAME;
    string public EQUITY_TOKEN_SYMBOL;

    // minimum number of tokens being offered. will set min cap
    uint256 public MIN_NUMBER_OF_TOKENS;
    // maximum number of tokens being offered. will set max cap
    uint256 public MAX_NUMBER_OF_TOKENS;
    // base token price in EUR-T, without any discount scheme
    uint256 public TOKEN_PRICE_EUR_ULPS;
    // maximum number of tokens in whitelist phase
    uint256 public MAX_NUMBER_OF_TOKENS_IN_WHITELIST;
    // sets nominal value of newly issued shares in currency of share capital as per ISHA
    // will be embedded in the equity token (IEquityToken interface)
    uint256 public SHARE_NOMINAL_VALUE_ULPS;
    // sets nominal value of newly issued shares in euro, used to withdraw share capital to Nominee
    uint256 public SHARE_NOMINAL_VALUE_EUR_ULPS;
    // equity tokens per share
    uint256 public EQUITY_TOKENS_PER_SHARE;


    ////////////////////////
    // Constructor
    ////////////////////////

    constructor(
        string equityTokenName,
        string equityTokenSymbol,
        uint256 minNumberOfTokens,
        uint256 maxNumberOfTokens,
        uint256 tokenPriceEurUlps,
        uint256 maxNumberOfTokensInWhitelist,
        uint256 shareNominalValueUlps,
        uint256 shareNominalValueEurUlps,
        uint256 equityTokensPerShare
    )
        public
    {
        require(maxNumberOfTokens >= maxNumberOfTokensInWhitelist, "NF_WL_TOKENS_GT_MAX_TOKENS");
        require(maxNumberOfTokens >= minNumberOfTokens, "NF_MIN_TOKENS_GT_MAX_TOKENS");
        // min cap must be > single share
        require(minNumberOfTokens >= equityTokensPerShare, "NF_ETO_TERMS_ONE_SHARE");
        // maximum number of tokens are full shares
        require(maxNumberOfTokens % equityTokensPerShare == 0, "NF_MAX_TOKENS_FULL_SHARES");
        require(shareNominalValueUlps > 0);
        require(shareNominalValueEurUlps > 0);
        require(equityTokensPerShare > 0);
        require(keccak256(abi.encodePacked(equityTokenName)) != EMPTY_STRING_HASH);
        require(keccak256(abi.encodePacked(equityTokenSymbol)) != EMPTY_STRING_HASH);
        // overflows cannot be possible
        require(maxNumberOfTokens < 2**56, "NF_TOO_MANY_TOKENS");
        require(mul(tokenPriceEurUlps, maxNumberOfTokens) < 2**112, "NF_TOO_MUCH_FUNDS_COLLECTED");

        MIN_NUMBER_OF_TOKENS = minNumberOfTokens;
        MAX_NUMBER_OF_TOKENS = maxNumberOfTokens;
        TOKEN_PRICE_EUR_ULPS = tokenPriceEurUlps;
        MAX_NUMBER_OF_TOKENS_IN_WHITELIST = maxNumberOfTokensInWhitelist;
        SHARE_NOMINAL_VALUE_EUR_ULPS = shareNominalValueEurUlps;
        SHARE_NOMINAL_VALUE_ULPS = shareNominalValueUlps;
        EQUITY_TOKEN_NAME = equityTokenName;
        EQUITY_TOKEN_SYMBOL = equityTokenSymbol;
        EQUITY_TOKENS_PER_SHARE = equityTokensPerShare;
    }

    ////////////////////////
    // Public methods
    ////////////////////////

    function SHARE_PRICE_EUR_ULPS() public constant returns (uint256) {
        return mul(TOKEN_PRICE_EUR_ULPS, EQUITY_TOKENS_PER_SHARE);
    }

    //
    // Implements IContractId
    //

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0x591e791aab2b14c80194b729a2abcba3e8cce1918be4061be170e7223357ae5c, 1);
    }
}