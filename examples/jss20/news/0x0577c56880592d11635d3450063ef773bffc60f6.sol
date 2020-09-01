// File: original_contracts/deployer/IPartnerDeployer.sol

pragma solidity 0.5.11;


interface IPartnerDeployer {

    function deploy(
        string calldata referralId,
        address payable feeWallet,
        uint256 fee,
        uint256 paraswapShare,
        uint256 partnerShare,
        address owner
    )
        external
        returns(address);
}

// File: original_contracts/IPartner.sol

pragma solidity 0.5.11;


interface IPartner {

    function getReferralId() external view returns(string memory);

    function getFeeWallet() external view returns(address payable);

    function getFee() external view returns(uint256);

    function getPartnerShare() external returns(uint256);

    function getParaswapShare() external returns(uint256);

    function changeFeeWallet(address payable feeWallet) external;

    function changeFee(uint256 newFee) external;
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
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
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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

// File: original_contracts/Partner.sol

pragma solidity 0.5.11;




contract Partner is Ownable {

    string private _referralId;

    address payable private _feeWallet;

    //It should be in percentage. For 1% it should be 100
    uint256 private _fee;

    //Paraswap share in the fee. For 20% it should 2000
    //It means 20% of 1% fee charged
    uint256 private _paraswapShare;

    //Partner share in the fee. For 80% it should be 8000
    uint256 private _partnerShare;

    event FeeWalletChanged(address indexed feeWallet);
    event FeeChanged(uint256 fee);

    constructor(
        string memory referralId,
        address payable feeWallet,
        uint256 fee,
        uint256 paraswapShare,
        uint256 partnerShare,
        address owner
    )
        public
    {
        _referralId = referralId;
        _feeWallet = feeWallet;
        _fee = fee;
        _paraswapShare = paraswapShare;
        _partnerShare = partnerShare;
        transferOwnership(owner);
    }

    function getReferralId() external view returns(string memory) {
        return _referralId;
    }

    function getFeeWallet() external view returns(address payable) {
        return _feeWallet;
    }

    function getFee() external view returns(uint256) {
        return _fee;
    }

    function getPartnerShare() external returns(uint256) {
        return _partnerShare;
    }

    function getParaswapShare() external returns(uint256) {
        return _paraswapShare;
    }

    function changeFeeWallet(address payable feeWallet) external onlyOwner {
        require(feeWallet != address(0), "Invalide fee wallet passed!!");
        _feeWallet = feeWallet;

        emit FeeWalletChanged(feeWallet);
    }

    function changeFee(uint256 newFee) external onlyOwner {
        require(newFee <= 10000, "Invalid fee passed!!");

        _fee = newFee;

        emit FeeChanged(newFee);
    }

}

// File: original_contracts/deployer/PartnerDeployer.sol

pragma solidity 0.5.11;



contract PartnerDeployer is IPartnerDeployer {

    function deploy(
        string calldata referralId,
        address payable feeWallet,
        uint256 fee,
        uint256 paraswapShare,
        uint256 partnerShare,
        address owner
    )
        external
        returns(address)
    {
        Partner partner = new Partner(
            referralId,
            feeWallet,
            fee,
            paraswapShare,
            partnerShare,
            owner
        );
        return address(partner);
    }
}