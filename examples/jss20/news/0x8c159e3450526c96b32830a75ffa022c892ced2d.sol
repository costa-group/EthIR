pragma solidity ^0.5.0;

contract ExpTokenProxy {
    bytes32 private constant proxyOwner = keccak256("exptoken.proxy.owner");
    bytes32 private constant proxyImplementation = keccak256("exptoken.proxy.implementation");
    bytes32 private constant proxyVersion = keccak256("exptoken.proxy.version");

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event UpdateContract(address indexed implAddress, uint256 version);
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "failure");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == getOwner();
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(getOwner(), address(0));
        address _address = address(0);
        bytes32 position = proxyOwner;
        assembly {
            sstore(position, _address)
        }
    }

    function getOwner() public view returns (address owner) {
        bytes32 position = proxyOwner;
        assembly {
            owner := sload(position)
        }
    }

    constructor() public {
        bytes32 position = proxyOwner;
        address owner = msg.sender;
        assembly {
            sstore(position, owner)
        }
        emit OwnershipTransferred(address(0), owner);
    }

    function setImplementation(address _address, uint256 _version) public onlyOwner {
        bytes32 implPosition = proxyImplementation;
        bytes32 versionPosition = proxyVersion;
        assembly {
            sstore(implPosition, _address)
            sstore(versionPosition, _version)
        }
        emit UpdateContract(_address, _version);
    }

    function getImplementation() public view returns (address implementaion) {
        bytes32 position = proxyImplementation;
        assembly {
            implementaion := sload(position)
        }
    }

    function getVersion() public view returns (uint256 version) {
        bytes32 position = proxyVersion;
        assembly {
            version := sload(position)
        }
    }

    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    function () external payable {
        address _impl = getImplementation();
        require(_impl != address(0), "failure");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}