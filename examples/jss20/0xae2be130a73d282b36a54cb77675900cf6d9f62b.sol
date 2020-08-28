pragma solidity ^0.5.13;

/**
 * @dev ERC20200206, another Non-Fungible Token Standard interface, JUST for Doctor Li
 * https://etherscan.io/address/0x6e46d3ab7335fffb0d14927e0b418cc08fe60505#code
 * https://shimo.im/docs/rW99CpvkTVxGwcV6
 * https://ipfs.io/ipfs/QmQZC741wpPjDNWJnMDMxFjsBnxsvXSBAVwSmSwXTJfv8z
 */
contract ERC20200206  {
    event Mint(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    function name()   external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);

    function totalSupply() public view returns (uint256);
    function exists(uint256 _tokenId) public view returns (bool _exists);
    function minerOf(uint256 _tokenId) public view returns (address _miner);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function tokenURI(uint256 _tokenId) public view returns (string memory _uri);

    function amountOf(address _miner) public view returns (uint256 _amount);
    function tokenOfMinerByIndex(
        address _miner,
        uint256 _index
    )
        public
        view
        returns (uint256 _tokenId);
    function tokenByIndex(uint256 _index) public view returns (uint256 _tokenId);

    function setTokenURI(uint256 _tokenId, string memory _uri) public;
    function mint(string memory _uri) public;
}

contract NFT {
    using SafeMath for uint256;

    // Token name
    string internal name_;

    // Token symbol
    string internal symbol_;

    // Mapping from miner to list of minted token IDs
    mapping(address => uint256[]) internal mintedTokens;

    // Mapping from token ID to index of the miner tokens list
    mapping(uint256 => uint256) internal mintedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] internal allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) internal allTokensIndex;

    // Optional mapping for token URIs
    mapping(uint256 => string) internal tokenURIs;

    // Mapping from token ID to miner
    mapping (uint256 => address) internal tokenMiner;

    // Mapping from miner to number of minted token
    mapping (address => uint256) internal mintedTokensCount;

    // Mapping from token ID to owner
    mapping (uint256 => address) internal tokenOwner;

    //
    mapping (address => uint256) internal lastMintMoment;

    event Mint(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );


    /**
     * @dev Constructor function
     */
    constructor(string memory _name, string memory _symbol) 
        public 
    {
        name_ = _name;
        symbol_ = _symbol;
    }

    /**
     * @dev Gets the token name
     * @return _name string representing the token name
     */
    function name() external  view returns (string memory _name) 
    {
        _name = name_;
    }

    /**
     * @dev Gets the token symbol
     * @return _symbol string representing the token symbol
     */
    function symbol() 
        external 
        view 
        returns (string memory _symbol) 
    {
        _symbol = symbol_;
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract
     * @return _amount uint256 representing the total amount of tokens
     */
    function totalSupply() 
        public 
        view 
        returns (uint256 _amount) 
    {
        _amount = allTokens.length;
    }

    /**
     * @dev Returns whether the specified token exists
     * @param _tokenId uint256 ID of the token to query the existence of
     * @return _exists whether the token exists
     */
    function exists(uint256 _tokenId) 
        public 
        view 
        returns (bool _exists) 
    {
        address miner = tokenMiner[_tokenId];
        _exists = (miner != address(0));
    }

    /**
     * @dev Gets the miner of the specified token ID
     * @param _tokenId uint256 ID of the token to query the miner of
     * @return _miner miner address currently marked as the miner of the given token ID
     */
    function minerOf(uint256 _tokenId) 
        public 
        view 
        returns (address _miner) 
    {
        _miner = tokenMiner[_tokenId];
    }

    /**
     * @dev Gets the owner of the specified token ID
     * @param _tokenId uint256 ID of the token to query the owner of
     * @return _owner owner address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 _tokenId) 
        public 
        view 
        returns (address _owner) 
    {
        require(exists(_tokenId));
        _owner = tokenOwner[_tokenId];
    }

    /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param _tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 _tokenId) 
        public 
        view 
        returns (string memory _uri) 
    {
        require(exists(_tokenId));
        _uri = tokenURIs[_tokenId];
    }

    /**
     * @dev Gets the amount of the specified address
     * @param _miner address to query the balance of
     * @return _amount uint256 representing the amount minted by the passed address
     */
    function amountOf(address _miner) 
        public 
        view 
        returns (uint256 _amount) 
    {
        require(_miner != address(0));
        _amount = mintedTokensCount[_miner];
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested miner
     * @param _miner address mining the tokens list to be accessed
     * @param _index uint256 representing the index to be accessed of the requested tokens list
     * @return _tokenId uint256 token ID at the given index of the tokens list minted by the requested address
     */
    function tokenOfMinerByIndex(
        address _miner,
        uint256 _index
    )
        public
        view
        returns (uint256 _tokenId)
    {
        require(_index < amountOf(_miner));
        _tokenId = mintedTokens[_miner][_index];
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens
     * @param _index uint256 representing the index to be accessed of the tokens list
     * @return _tokenId uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 _index) 
        public 
        view 
        returns (uint256 _tokenId) 
    {
        require(_index < totalSupply());
        _tokenId = allTokens[_index];
    }


    /**
     * @dev public function to set the token URI for a given token
     * Reverts if the token ID does not exist
     * @param _tokenId uint256 ID of the token to set its URI
     * @param _uri string URI to assign
     */
    function setTokenURI(uint256 _tokenId, string memory _uri) 
        public
    {
        require(exists(_tokenId),"TokenId is not exist");
        require(minerOf(_tokenId) == msg.sender,"Only Miner can reset URI");
        tokenURIs[_tokenId] = _uri;
    }

    /**
     * @dev public function to mint a new token
     * Reverts if the msg.sender already have minted in a day.
     * @param _uri  the token's URI string.
     */
    function mint(string memory _uri) 
        public
    {
        require(canMint(msg.sender));

        uint256 _tokenId = totalSupply().add(1);
        require(tokenMiner[_tokenId] == address(0));
        tokenMiner[_tokenId] = msg.sender;
        mintedTokensCount[msg.sender] = mintedTokensCount[msg.sender].add(1);

        uint256 length = mintedTokens[msg.sender].length;
        mintedTokens[msg.sender].push(_tokenId);
        mintedTokensIndex[_tokenId] = length;
        tokenOwner[_tokenId] = address(0);

        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
        tokenURIs[_tokenId] = _uri;

        lastMintMoment[msg.sender] = now;

        emit Mint(msg.sender, address(0), _tokenId);
    }

    /**
     * @dev public function to revert eth transfer to this contract.
     * Reverts if any eth transfer to this contract
     */
    function() external payable {
        revert();
    }

    /**
     * @dev public function to judge whether the address can mint
     * every address can minted once a day.
     * 1581264000 2020/02/10/00:00:00
     * 24*3600 = 86400
     * @param _miner the address to be judged
     * @return _canmint the bool.
     */
    function canMint(address _miner) 
        public 
        view 
        returns(bool _canmint) 
    {
        if (lastMintMoment[_miner] == 0) {
            _canmint = true;
        } else {
            uint256 _last = lastMintMoment[_miner];
            uint256 _lastutc_8 = _last.sub(1581264000);
            uint256 _lastspec = _lastutc_8 % 86400;
            if (now.sub(_last).add(_lastspec) > 86400) {
                _canmint = true;
            } else {
                _canmint = false;
            }
        }
    }
}


/**
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}