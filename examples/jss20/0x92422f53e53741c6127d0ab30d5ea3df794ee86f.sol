pragma solidity 0.5.11;

/**
 * @title Gods Unchained - Fission Pool
 * @author Mythic Titan
 */
contract FissionPool {
    // Create a pool by sending a Shadow, Gold, or Diamond Gods Unchained Card
    // Set how many lower tier cards are required to select a Champion
    // Players send a lower tier Gods Unchained Card to the pool
    // One Champion selected at random wins the higher tier card

    // ==== EVENTS ==== //

    /**
     * @dev OnAddPlayer emits an event when a player enters a pool
     *
     * @param _poolId - The ID of the pool
     * @param _owner - Token owner
     * @param _tokenId - The Gods Unchained Token ID
     */
    event OnAddPlayer(
        uint256 indexed _poolId,
        address indexed _owner,
        uint256 _tokenId
    );

    /**
     * @dev OnCancelPool emits an event when a host cancels a pool
     *
     * @param _poolId - The ID of the pool
     */
    event OnCancelPool(
        uint256 indexed _poolId
    );

    /**
     * @dev OnCollect emits an event when the host collects their cards from a pool
     *
     * @param _poolId - The ID of the pool
     */
    event OnCollect(
        uint256 indexed _poolId
    );

    /**
     * @dev OnCreatePool emits an event when a host creates a new pool
     *
     * @param _poolId - The ID of the pool
     * @param _host - Address of the pool Host
     * @param _proto - Gods Unchained proto ID
     * @param _quality - Gods Unchained card quality
     * @param _quorum - Number of cards required to activate
     * @param _tokenId - The Gods Unchained Token ID
     */
    event OnCreatePool(
        uint256 indexed _poolId,
        address indexed _host,
        uint16 _proto,
        uint8 _quality,
        uint256 _quorum,
        uint256 _tokenId
    );

    /**
     * @dev OnRemovePlayer emits an event when a player leaves a pool
     *
     * @param _poolId - The ID of the pool
     * @param _index - The index of the Player removed
     */
    event OnRemovePlayer(
        uint256 indexed _poolId,
        uint256 _index
    );

    /**
     * @dev OnWinner emits an event when a winner is selected
     *
     * @param _poolId - The ID of the pool
     * @param _winner - The player's address that won
     * @param _random - The randomly selected index
     */
    event OnWinner(
        uint256 indexed _poolId,
        address indexed _winner,
        uint256 _random
    );

    // ==== STRUCT ==== //
    struct Pool {
        address host;
        Player[] players;
        uint16 proto;
        uint8 quality;
        uint256 quorum;
        uint256 tokenId;
    }

    struct Player {
        address owner;
        uint256 tokenId;
    }

    // ==== PUBLIC VARIABLES ==== //

    // Mapping pool ID to Pool
    mapping(uint256 => Pool) public pools;

    /**
     * @dev tokenAddress is the ERC721 Token address
     */
    address public tokenAddress;

    /**
     * @dev tokenInterface interfaces with the ERC721
     */
    interfaceERC721 public tokenInterface;

    /**
     * @dev totalPools increments each time a new pool is created
     */
    uint256 public totalPools;

    // ==== CONSTRUCTOR ==== //

    /**
     * @dev constructor runs once during contract deployment
     *
     * @param _tokenAddress - The Gods Unchained contract address
     */
    constructor(address _tokenAddress)
        public
    {
        tokenInterface = interfaceERC721(_tokenAddress);
    }

    // ==== MODIFIERS ==== //

    /**
     * @dev onlyEOA requires msg.sender to be an externally owned account
     */
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "only externally owned accounts");
        _;
    }

    // ==== PUBLIC WRITE FUNCTIONS ==== //

    /**
     * @dev activatePool selects a winner
     *
     * @param poolId - The ID of the pool
     */
    function activatePool(uint256 poolId)
        public
        onlyEOA
    {
        // Reference the pool
        Pool storage pool = pools[poolId];

        // Require pool is ready to activate
        require( pool.quorum > 0 && pool.players.length == pool.quorum, "requires minimum number of players");

        // Select Winner at random
        uint256 random = getRandom(pool.quorum, poolId);

        // Winner
        address winner = pool.players[random].owner;

        // Invalidate the Pool
        delete pool.quorum;

        // Transfer prize to the winner
        tokenInterface.transferFrom(address(this), winner, pool.tokenId);

        // Emit an event log when a winner is selected
        emit OnWinner(poolId, winner, random);
    }

    function cancelPool(uint256 poolId)
        public
        onlyEOA
    {
        // Reference the pool
        Pool storage pool = pools[poolId];

        // Check pool is active
        require(pool.quorum > 0, "must be an active pool");

        // Check msg.sender is the host
        require(pool.host == msg.sender, "must be the host");

        // Refund all cards in the pool
        if (pool.players.length > 0) {
            for(uint256 i = pool.players.length - 1; i >= 0; i--) {
                tokenInterface.transferFrom(address(this), pool.players[i].owner, pool.players[i].tokenId);
                pool.players.pop();
            }
        }

        // Store reference to the host and token
        address host = pool.host;
        uint256 tokenId = pool.tokenId;

        // Delete the pool
        delete pools[poolId];

        // Refund the host's card
        tokenInterface.transferFrom(address(this), host, tokenId);

        emit OnCancelPool(poolId);
    }

    /**
     * @dev collectCards enables a host to collect their cards after a pool activates
     *
     * @param poolId - The ID of the pool
     */
    function collectCards(uint256 poolId)
        public
    {
        // Reference the pool
        Pool storage pool = pools[poolId];

        // Require msg.sender is the host
        require(pool.host == msg.sender, "must be the host");

        // Require pool was activated
        require(pool.quorum == 0, "pool not activated");

        // Send all cards in the pool to the host
        for(uint256 i = pool.players.length - 1; i >= 0; i--) {
            tokenInterface.transferFrom(address(this), pool.host, pool.players[i].tokenId);
            pool.players.pop();
        }

        // Delete the pool
        delete pools[poolId];

        emit OnCollect(poolId);
    }

    /**
     * @dev exitPool allows a player to remove a card from a Pool
     *
     * @param poolId - The ID of the pool
     */
    function exitPool(uint256 poolId, uint256 index)
        public
        onlyEOA
    {
        // Reference players in the pool
        Player[] storage players = pools[poolId].players;

        // Require msg.sender is the player
        require(players[index].owner == msg.sender, "Must be the player");

        // Store the token ID
        uint256 tokenId = players[index].tokenId;

        // Set the last index equal to the removed player
        players[index] = players[players.length - 1];

        // Remove last element in the list of players
        players.pop();

        // Transfer the token to the owner
        tokenInterface.transferFrom(address(this), msg.sender, tokenId);

        // Emit an event when a player leaves a pool
        emit OnRemovePlayer(poolId, index);
    }

    // ==== PUBLIC READ FUNCTIONS ==== //

    /**
     * @dev exitPool allows a player to remove a card from a Pool
     *
     * @param poolId - The ID of the pool
     *
     * @return _tokenId - The host's token ID
     * @return _host - The pool host
     * @return _proto - The proto
     * @return _quality - The quality player's send to the pool
     * @return _quorum - Number of tokens required to activate
     * @return _players - List of players in the pool
     * @return _tokenIds - List of token ids in the pool
     */
    function getPool(uint256 poolId)
        public
        view
        returns(uint256 _tokenId, address _host, uint16 _proto, uint8 _quality, uint256 _quorum, address[] memory _players, uint256[] memory _tokenIds)
    {
        // Reference the pool
        Pool storage pool = pools[poolId];

        _host = pool.host;
        _proto = pool.proto;
        _quality = pool.quality;
        _quorum = pool.quorum;
        _tokenId = pool.tokenId;

        for(uint256 i = 0; i < pool.players.length; i++) {
            _players[i] = pool.players[i].owner;
            _tokenIds[i] = pool.players[i].tokenId;
        }
    }

    // ==== EXTERNAL FUNCTIONS ==== //

    /**
     * @dev onERC721Received handles receiving an ERC721 token
     *
     * _operator - The address which called `safeTransferFrom` function
     * @param _from - The address which previously owned the token
     * @param _tokenId - The NFT IDentifier which is being transferred
     * @param _data - Additional data with no specified format
     *
     * @return Receipt
     */
    function onERC721Received(address /*_operator*/, address _from, uint256 _tokenId, bytes calldata _data)
        external
        returns(bytes4)
    {
        // Require token address is authorized
        require(msg.sender == tokenAddress, "must be the token address");

        // Require token holder is an externally owned account
        require(tx.origin == _from, "token owner must be an externally owned account");

        // Parse data payload
        (uint256 poolId, uint256 quorum) = abi.decode(_data, (uint256, uint256));

        // Get the Gods Unchained Proto and Quality from Token ID
        (uint16 proto, uint8 quality) = tokenInterface.getDetails(_tokenId);

        // Create or Join a Fusion Pool
        if (poolId == 0) {
            // Create new pool
            createPool(_from, proto, quality, quorum, _tokenId);
        } else {
            // Join existing pool
            joinPool(poolId, _from, proto, quality, _tokenId);
        }

        // ERC721_RECEIVED Receipt (magic value)
        return 0x150b7a02;
    }

    // ==== PRIVATE FUNCTIONS ==== //

    /**
     * @dev createPool creates a new pool
     *
     * @param host - The host of the pool
     * @param proto - Gods Unchained proto
     * @param quality - Gods Unchained quality
     * @param quorum - Number of players needed to activate a pool
     * @param tokenId - ERC721 Token ID
     */
    function createPool(address host, uint16 proto, uint8 quality, uint256 quorum, uint256 tokenId)
        private
    {
        // Check token quality
        require(proto < 4, "Must be Shadow, Gold, or Diamond");

        // Check quorum
        require(quorum > 0 && quorum < 11, "must be an integer from 1 to 10");

        // Increment total number of pools
        totalPools = totalPools + 1;

        // Reference the pool
        Pool storage pool = pools[totalPools];

        // Create new pool
        pool.host = host;
        pool.proto = proto;
        pool.quality = quality + 1;
        pool.quorum = quorum;
        pool.tokenId = tokenId;

        // Emit event when a pool is created
        emit OnCreatePool(totalPools, host, proto, quality, quorum, tokenId);
    }

    /**
     * @dev joinPool adds a card to a pool
     *
     * @param poolId - The host of the pool
     * @param owner - Card Owner
     * @param proto - Gods Unchained proto
     * @param quality - Gods Unchained quality
     * @param tokenId - ERC721 Token ID
     */
    function joinPool(uint256 poolId, address owner, uint16 proto, uint8 quality, uint256 tokenId)
        private
    {
        // Reference to the pool
        Pool storage pool = pools[poolId];

        // Require a valid pool
        require(pool.quorum > 0, "invalid pool");

        // Require an opening in the pool
        require(pool.players.length < pool.quorum, "full pool");

        // Require valid proto
        require(proto == pool.proto, "proto must match");

        // Require valid quality
        require(quality == pool.quality, "quality must match");

        // Add player to the pool
        pool.players.push(Player(owner, tokenId));

        // Emit event when a new player joins a pool
        emit OnAddPlayer(poolId, owner, tokenId);
    }

    /**
     * @dev getRandom generates a random integer from 0 to (max - 1)
     *
     * @param max - Maximum number of integers to select from
     * @param poolId - ID of the Pool
     * @return random - The randomly selected integer
     */
    function getRandom(uint256 max, uint256 poolId)
        private
        view
        returns(uint256 random)
    {
        // Blockhash from last block
        uint256 blockhash_ = uint256(blockhash(block.number - 1));

        // Randomly generated integer
        random = uint256(keccak256(abi.encodePacked(
            // Unix timestamp in seconds
            block.timestamp,
            // Address of the block miner
            block.coinbase,
            // Difficulty of the block
            block.difficulty,
            // Blockhash from last block
            blockhash_,
            // Pool ID
            poolId
        ))) % max;
    }
}

// ==== INTERFACE ==== //
/**
 * @title Abstract Contract Interface
 */
contract interfaceERC721 {
    function getDetails(uint256 _tokenId) public view returns (uint16, uint8);
    function transferFrom(address from, address to, uint256 tokenId) public;
}