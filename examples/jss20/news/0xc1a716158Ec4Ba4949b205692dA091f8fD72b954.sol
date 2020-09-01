// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/interfaces/IDepositRegistry.sol

pragma solidity 0.5.12;

interface IDepositRegistry {
    struct Deposit {
        bool deposited;
        bool unlockedForWithdrawal;
    }

    event UserDepositCompleted(address depositRegistry, address indexed user);
    event UserWithdrawnCompleted(address depositRegistry, address indexed user);
    event AddressUnlockedForWithdrawal(address depositRegistry, address indexed user);
    event MigrationFinished(address depositRegistry);

    function setReferralTracker(address) external;

    function setERC20Token(address) external;

    function setKYC(address) external;

    function setAdministrator(address _admin) external;

    function migrate(address[] calldata depositors, address oldDeposit) external;

    function finishMigration() external;

    function depositFor(address from) external returns (bool);

    function depositForWithReferral(address from, address referrer) external returns (bool);

    function delegateDeposit(address to) external returns (bool);

    function withdraw(address to) external;

    function unlockAddressForWithdrawal(address user) external;

    function hasDeposited(address user) external view returns (bool);

    function isUnlocked(address user) external view returns (bool);

    function getERC20Token() external view returns (address);

    function getDepositRegistryByUser(address user) external view returns (address);
}

// File: contracts/interfaces/IKYCRegistry.sol

pragma solidity 0.5.12;

interface IKYCRegistry {
    event RemovedFromKYC(address indexed user);
    event AddedToKYC(address indexed user);

    function isConfirmed(address addr) external view returns (bool);

    function setAdministrator(address _admin) external;

    function removeAddressFromKYC(address addr) external;

    function addAddressToKYC(address addr) external;

}

// File: contracts/interfaces/IAuthorization.sol

pragma solidity 0.5.12;

interface IAuthorization {
    function getKycAddress() external view returns (address);

    function getDepositAddress() external view returns (address);

    function hasDeposited(address user) external view returns (bool);

    function isKYCConfirmed(address user) external view returns (bool);

    function setKYCRegistry(address _kycAddress) external returns (bool);

    function setDepositRegistry(address _depositAddress) external returns (bool);
}

// File: contracts/Authorization.sol

pragma solidity 0.5.12;






contract Authorization is IAuthorization, Ownable {
    address internal kycAddress;
    address internal depositAddress;

    constructor(address _kycAddress, address _depositAddress) public {
        kycAddress = _kycAddress;
        depositAddress = _depositAddress;
    }

    function getKycAddress() external view returns (address) {
        return kycAddress;
    }

    function getDepositAddress() external view returns (address) {
        return depositAddress;
    }

    function hasDeposited(address user) external view returns (bool) {
        return IDepositRegistry(depositAddress).hasDeposited(user);
    }

    function isKYCConfirmed(address user) external view returns (bool) {
        return IKYCRegistry(kycAddress).isConfirmed(user);
    }

    function setKYCRegistry(address _kycAddress) external onlyOwner returns (bool) {
        kycAddress = _kycAddress;
        return true;
    }

    function setDepositRegistry(address _depositAddress) external onlyOwner returns (bool) {
        depositAddress = _depositAddress;
        return true;
    }
}