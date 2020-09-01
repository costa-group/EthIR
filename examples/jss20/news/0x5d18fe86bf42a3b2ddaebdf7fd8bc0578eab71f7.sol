pragma solidity 0.5.13;

contract Resolver {
    function setName(bytes32 node, string memory name) public;
}

contract ReverseRegistrar {
    function setName(string memory name) public returns (bytes32 node);
    function claim(address owner) public returns (bytes32 node);
    function claimWithResolver(address owner, address resolver) public returns (bytes32 node);
    function node(address addr) public pure returns (bytes32);
}

contract OrchidCurator {
    function good(address, bytes calldata) external view returns (uint128);
}

contract OrchidList is OrchidCurator {
    ReverseRegistrar constant private ens_ = ReverseRegistrar(0x9062C0A6Dbd6108336BcBe4593a3D1cE05512069);

    address private owner_;

    constructor() public {
        ens_.claim(msg.sender);
        owner_ = msg.sender;
    }

    function hand(address owner) external {
        require(msg.sender == owner_);
        owner_ = owner;
    }

    struct Entry {
        uint128 adjust_;
        bool valid_;
    }

    mapping (address => Entry) private entries_;

    function kill(address provider) external {
        require(msg.sender == owner_);
        delete entries_[provider];
    }

    function tend(address provider, uint128 adjust) public {
        require(msg.sender == owner_);
        Entry storage entry = entries_[provider];
        entry.adjust_ = adjust;
        entry.valid_ = true;
    }

    function list(address provider) external {
        return tend(provider, uint128(-1));
    }

    function good(address provider, bytes calldata) external view returns (uint128) {
        Entry storage entry = entries_[provider];
        require(entry.valid_);
        return entry.adjust_;
    }
}

contract OrchidSelect is OrchidCurator {
    ReverseRegistrar constant private ens_ = ReverseRegistrar(0x9062C0A6Dbd6108336BcBe4593a3D1cE05512069);

    constructor() public {
        ens_.claim(msg.sender);
    }

    function good(address provider, bytes calldata argument) external view returns (uint128) {
        require(argument.length == 20);
        address allowed;
        bytes memory copy = argument;
        assembly { allowed := mload(add(copy, 20)) }
        require(provider == allowed);
        return uint128(-1);
    }
}

contract OrchidUntrusted is OrchidCurator {
    ReverseRegistrar constant private ens_ = ReverseRegistrar(0x9062C0A6Dbd6108336BcBe4593a3D1cE05512069);

    constructor() public {
        ens_.claim(msg.sender);
    }

    function good(address, bytes calldata) external view returns (uint128) {
        return uint128(-1);
    }
}


// note: this interface defines book as a view function instead of pure
interface OrchidVerifier {
    function book(bytes calldata shared, address target, bytes calldata receipt) external view;
}


contract OrchidListVerifier is OrchidVerifier {

    OrchidList internal curator_;

    constructor(OrchidList curator) public {
        curator_ = curator;
    }

    function book(bytes calldata, address target, bytes calldata receipt) external view {
        require(curator_.good(target, receipt) != uint128(0));
    }
    
}