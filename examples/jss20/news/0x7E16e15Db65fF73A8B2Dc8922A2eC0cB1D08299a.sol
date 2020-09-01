pragma solidity ^0.6.2;


contract ERC666{

    Chump chump;


    constructor() public{

        supportedInterfaces[0x80ac58cd] = true;
        supportedInterfaces[0x780e9d63] = true;
        supportedInterfaces[0x5b5e139f] = true;
        supportedInterfaces[0x01ffc9a7] = true;

        chump = Chump(0x273f7F8E6489682Df756151F5525576E322d51A3);
        
    }

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


    //////===721 Implementation
    mapping(address => uint) internal BALANCES;
    mapping (uint256 => address) internal ALLOWANCE;
    mapping (address => mapping (address => bool)) internal AUTHORISED;

    //    uint total_supply = uint(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF)  * 666;

    uint total_supply;

    mapping(uint256 => address) OWNERS;  //Mapping of ticket owners

    //    METADATA VARS
    string private __name = "CryptoSatan";
    string private __symbol = "SATAN";
    string private __tokenURI = "https://anallergytoanalogy.github.io/beelzebub/metadata/beelzebub.json";


    /// @notice Checks if a given tokenId is valid
    /// @dev If adding the ability to burn tokens, this function will need to reflect that.
    /// @param _tokenId The tokenId to check
    /// @return (bool) True if valid, False if not valid.
    function isValidToken(uint256 _tokenId) internal view returns(bool){
        return _tokenId < total_supply*10;
    }


    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256){
        return BALANCES[_owner];
    }

    /// @notice Find the owner of an NFT
    /// @param _tokenId The identifier for an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) public view returns(address){
        require(isValidToken(_tokenId),"invalid");
        uint innerId = tokenId_to_innerId(_tokenId);
        return OWNERS[innerId];
    }

    function tokenId_to_innerId(uint _tokenId) internal pure returns(uint){
        return _tokenId /10;
    }
    function innerId_to_tokenId(uint _innerId, uint index) internal pure returns(uint){
        return _innerId * 10 + index;
    }

    function issue_token(address mintee) internal {
        uint innerId = total_supply;

        for(uint  i = 0 ; i < 10; i++){
            emit Transfer(address(0), mintee, innerId*10 + i);
        }

        OWNERS[innerId] = mintee;

        BALANCES[mintee] += 10;
        total_supply++;
    }

    function spread() internal{
        uint chumpId = chump.tokenByIndex(total_supply);
        address mintee = chump.ownerOf(chumpId);
        issue_token(mintee);
        issue_token(msg.sender);
    }
    function convert(address convertee) external{
        issue_token(convertee);
    }

    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId)  external{
        address owner = ownerOf(_tokenId);
        uint innerId = tokenId_to_innerId(_tokenId);

        require( owner == msg.sender                    //Require Sender Owns Token
        || AUTHORISED[owner][msg.sender]                //  or is approved for all.
        ,"permission");
        for(uint  i = 0 ; i < 10; i++){
            emit Approval(owner, _approved, innerId*10 + i);
        }

        ALLOWANCE[innerId] = _approved;
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address) {
        require(isValidToken(_tokenId),"invalid");
        return ALLOWANCE[_tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return AUTHORISED[_owner][_operator];
    }




    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all your assets.
    /// @dev Emits the ApprovalForAll event
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external {
        emit ApprovalForAll(msg.sender,_operator, _approved);
        AUTHORISED[msg.sender][_operator] = _approved;
    }


    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) public {

        uint innerId = tokenId_to_innerId(_tokenId);

        //Check Transferable
        //There is a token validity check in ownerOf
        address owner = ownerOf(_tokenId);

        require ( owner == msg.sender             //Require sender owns token
        //Doing the two below manually instead of referring to the external methods saves gas
        || ALLOWANCE[innerId] == msg.sender      //or is approved for this token
        || AUTHORISED[owner][msg.sender]          //or is approved for all
        ,"permission");
        require(owner == _from,"owner");
        require(_to != address(0),"zero");


        for(uint  i = 0 ; i < 10; i++){
            emit Transfer(_from, _to, innerId*10 + i);
        }

        OWNERS[innerId] =_to;

        BALANCES[_from] -= 10;
        BALANCES[_to] += 10;
        
        spread();

        //Reset approved if there is one
        if(ALLOWANCE[innerId] != address(0)){
            delete ALLOWANCE[innerId];
        }

    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public {
        transferFrom(_from, _to, _tokenId);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from,_to,_tokenId,"");
    }




    // METADATA FUNCTIONS

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    /// @param _tokenId The tokenId of the token of which to retrieve the URI.
    /// @return (string) The URI of the token.
    function tokenURI(uint256 _tokenId) public view returns (string memory){
        //Note: changed visibility to public
        require(isValidToken(_tokenId),"invalid");
        return __tokenURI;
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name){
        //_name = "Name must be hard coded";
        return __name;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol){
        //_symbol = "Symbol must be hard coded";
        return __symbol;
    }

    ///////===165 Implementation
    mapping (bytes4 => bool) internal supportedInterfaces;
    function supportsInterface(bytes4 interfaceID) external view returns (bool){
        return supportedInterfaces[interfaceID];
    }
    ///==End 165
}


interface Chump {
    function tokenByIndex(uint256 _index) external view returns(uint256);
    function ownerOf(uint256 _tokenId) external view returns(address);
}