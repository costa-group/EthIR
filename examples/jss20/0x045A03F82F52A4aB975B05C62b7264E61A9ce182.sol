// File: @aragon/os/contracts/common/UnstructuredStorage.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


library UnstructuredStorage {
    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly { data := sload(position) }
    }

    function getStorageAddress(bytes32 position) internal view returns (address data) {
        assembly { data := sload(position) }
    }

    function getStorageBytes32(bytes32 position) internal view returns (bytes32 data) {
        assembly { data := sload(position) }
    }

    function getStorageUint256(bytes32 position) internal view returns (uint256 data) {
        assembly { data := sload(position) }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageAddress(bytes32 position, address data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageBytes32(bytes32 position, bytes32 data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageUint256(bytes32 position, uint256 data) internal {
        assembly { sstore(position, data) }
    }
}

// File: @aragon/os/contracts/acl/IACL.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


interface IACL {
    function initialize(address permissionsCreator) external;

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);
}

// File: @aragon/os/contracts/common/IVaultRecoverable.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


interface IVaultRecoverable {
    event RecoverToVault(address indexed vault, address indexed token, uint256 amount);

    function transferToVault(address token) external;

    function allowRecoverability(address token) external view returns (bool);
    function getRecoveryVault() external view returns (address);
}

// File: @aragon/os/contracts/kernel/IKernel.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;




interface IKernelEvents {
    event SetApp(bytes32 indexed namespace, bytes32 indexed appId, address app);
}


// This should be an interface, but interfaces can't inherit yet :(
contract IKernel is IKernelEvents, IVaultRecoverable {
    function acl() public view returns (IACL);
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);

    function setApp(bytes32 namespace, bytes32 appId, address app) public;
    function getApp(bytes32 namespace, bytes32 appId) public view returns (address);
}

// File: @aragon/os/contracts/apps/AppStorage.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;




contract AppStorage {
    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_POSITION = keccak256("aragonOS.appStorage.kernel");
    bytes32 internal constant APP_ID_POSITION = keccak256("aragonOS.appStorage.appId");
    */
    bytes32 internal constant KERNEL_POSITION = 0x4172f0f7d2289153072b0a6ca36959e0cbe2efc3afe50fc81636caa96338137b;
    bytes32 internal constant APP_ID_POSITION = 0xd625496217aa6a3453eecb9c3489dc5a53e6c67b444329ea2b2cbc9ff547639b;

    function kernel() public view returns (IKernel) {
        return IKernel(KERNEL_POSITION.getStorageAddress());
    }

    function appId() public view returns (bytes32) {
        return APP_ID_POSITION.getStorageBytes32();
    }

    function setKernel(IKernel _kernel) internal {
        KERNEL_POSITION.setStorageAddress(address(_kernel));
    }

    function setAppId(bytes32 _appId) internal {
        APP_ID_POSITION.setStorageBytes32(_appId);
    }
}

// File: @aragon/os/contracts/acl/ACLSyntaxSugar.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


contract ACLSyntaxSugar {
    function arr() internal pure returns (uint256[]) {
        return new uint256[](0);
    }

    function arr(bytes32 _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(bytes32 _a, bytes32 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(address _a, address _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c);
    }

    function arr(address _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c, _d);
    }

    function arr(address _a, uint256 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, address _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), _c, _d, _e);
    }

    function arr(address _a, address _b, address _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(address _a, address _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(uint256 _a) internal pure returns (uint256[] r) {
        r = new uint256[](1);
        r[0] = _a;
    }

    function arr(uint256 _a, uint256 _b) internal pure returns (uint256[] r) {
        r = new uint256[](2);
        r[0] = _a;
        r[1] = _b;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        r = new uint256[](3);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        r = new uint256[](4);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        r = new uint256[](5);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
        r[4] = _e;
    }
}


contract ACLHelpers {
    function decodeParamOp(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 30));
    }

    function decodeParamId(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 31));
    }

    function decodeParamsList(uint256 _x) internal pure returns (uint32 a, uint32 b, uint32 c) {
        a = uint32(_x);
        b = uint32(_x >> (8 * 4));
        c = uint32(_x >> (8 * 8));
    }
}

// File: @aragon/os/contracts/common/Uint256Helpers.sol

pragma solidity ^0.4.24;


library Uint256Helpers {
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

// File: @aragon/os/contracts/common/TimeHelpers.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;



contract TimeHelpers {
    using Uint256Helpers for uint256;

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
    * @dev Returns the current block number, converted to uint64.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber64() internal view returns (uint64) {
        return getBlockNumber().toUint64();
    }

    /**
    * @dev Returns the current timestamp.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /**
    * @dev Returns the current timestamp, converted to uint64.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}

// File: @aragon/os/contracts/common/Initializable.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;




contract Initializable is TimeHelpers {
    using UnstructuredStorage for bytes32;

    // keccak256("aragonOS.initializable.initializationBlock")
    bytes32 internal constant INITIALIZATION_BLOCK_POSITION = 0xebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e;

    string private constant ERROR_ALREADY_INITIALIZED = "INIT_ALREADY_INITIALIZED";
    string private constant ERROR_NOT_INITIALIZED = "INIT_NOT_INITIALIZED";

    modifier onlyInit {
        require(getInitializationBlock() == 0, ERROR_ALREADY_INITIALIZED);
        _;
    }

    modifier isInitialized {
        require(hasInitialized(), ERROR_NOT_INITIALIZED);
        _;
    }

    /**
    * @return Block number in which the contract was initialized
    */
    function getInitializationBlock() public view returns (uint256) {
        return INITIALIZATION_BLOCK_POSITION.getStorageUint256();
    }

    /**
    * @return Whether the contract has been initialized by the time of the current block
    */
    function hasInitialized() public view returns (bool) {
        uint256 initializationBlock = getInitializationBlock();
        return initializationBlock != 0 && getBlockNumber() >= initializationBlock;
    }

    /**
    * @dev Function to be called by top level contract after initialization has finished.
    */
    function initialized() internal onlyInit {
        INITIALIZATION_BLOCK_POSITION.setStorageUint256(getBlockNumber());
    }

    /**
    * @dev Function to be called by top level contract after initialization to enable the contract
    *      at a future block number rather than immediately.
    */
    function initializedAt(uint256 _blockNumber) internal onlyInit {
        INITIALIZATION_BLOCK_POSITION.setStorageUint256(_blockNumber);
    }
}

// File: @aragon/os/contracts/common/Petrifiable.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;



contract Petrifiable is Initializable {
    // Use block UINT256_MAX (which should be never) as the initializable date
    uint256 internal constant PETRIFIED_BLOCK = uint256(-1);

    function isPetrified() public view returns (bool) {
        return getInitializationBlock() == PETRIFIED_BLOCK;
    }

    /**
    * @dev Function to be called by top level contract to prevent being initialized.
    *      Useful for freezing base contracts when they're used behind proxies.
    */
    function petrify() internal onlyInit {
        initializedAt(PETRIFIED_BLOCK);
    }
}

// File: @aragon/os/contracts/common/Autopetrified.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;



contract Autopetrified is Petrifiable {
    constructor() public {
        // Immediately petrify base (non-proxy) instances of inherited contracts on deploy.
        // This renders them uninitializable (and unusable without a proxy).
        petrify();
    }
}

// File: @aragon/os/contracts/common/ConversionHelpers.sol

pragma solidity ^0.4.24;


library ConversionHelpers {
    string private constant ERROR_IMPROPER_LENGTH = "CONVERSION_IMPROPER_LENGTH";

    function dangerouslyCastUintArrayToBytes(uint256[] memory _input) internal pure returns (bytes memory output) {
        // Force cast the uint256[] into a bytes array, by overwriting its length
        // Note that the bytes array doesn't need to be initialized as we immediately overwrite it
        // with the input and a new length. The input becomes invalid from this point forward.
        uint256 byteLength = _input.length * 32;
        assembly {
            output := _input
            mstore(output, byteLength)
        }
    }

    function dangerouslyCastBytesToUintArray(bytes memory _input) internal pure returns (uint256[] memory output) {
        // Force cast the bytes array into a uint256[], by overwriting its length
        // Note that the uint256[] doesn't need to be initialized as we immediately overwrite it
        // with the input and a new length. The input becomes invalid from this point forward.
        uint256 intsLength = _input.length / 32;
        require(_input.length == intsLength * 32, ERROR_IMPROPER_LENGTH);

        assembly {
            output := _input
            mstore(output, intsLength)
        }
    }
}

// File: @aragon/os/contracts/common/ReentrancyGuard.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;



contract ReentrancyGuard {
    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 internal constant REENTRANCY_MUTEX_POSITION = keccak256("aragonOS.reentrancyGuard.mutex");
    */
    bytes32 private constant REENTRANCY_MUTEX_POSITION = 0xe855346402235fdd185c890e68d2c4ecad599b88587635ee285bce2fda58dacb;

    string private constant ERROR_REENTRANT = "REENTRANCY_REENTRANT_CALL";

    modifier nonReentrant() {
        // Ensure mutex is unlocked
        require(!REENTRANCY_MUTEX_POSITION.getStorageBool(), ERROR_REENTRANT);

        // Lock mutex before function call
        REENTRANCY_MUTEX_POSITION.setStorageBool(true);

        // Perform function call
        _;

        // Unlock mutex after function call
        REENTRANCY_MUTEX_POSITION.setStorageBool(false);
    }
}

// File: @aragon/os/contracts/lib/token/ERC20.sol

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/a9f910d34f0ab33a1ae5e714f69f9596a02b4d91/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @aragon/os/contracts/common/EtherTokenConstant.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


// aragonOS and aragon-apps rely on address(0) to denote native ETH, in
// contracts where both tokens and ETH are accepted
contract EtherTokenConstant {
    address internal constant ETH = address(0);
}

// File: @aragon/os/contracts/common/IsContract.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


contract IsContract {
    /*
    * NOTE: this should NEVER be used for authentication
    * (see pitfalls: https://github.com/fergarrui/ethereum-security/tree/master/contracts/extcodesize).
    *
    * This is only intended to be used as a sanity check that an address is actually a contract,
    * RATHER THAN an address not being a contract.
    */
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}

// File: @aragon/os/contracts/common/SafeERC20.sol

// Inspired by AdEx (https://github.com/AdExNetwork/adex-protocol-eth/blob/b9df617829661a7518ee10f4cb6c4108659dd6d5/contracts/libs/SafeERC20.sol)
// and 0x (https://github.com/0xProject/0x-monorepo/blob/737d1dc54d72872e24abce5a1dbe1b66d35fa21a/contracts/protocol/contracts/protocol/AssetProxy/ERC20Proxy.sol#L143)

pragma solidity ^0.4.24;



library SafeERC20 {
    // Before 0.5, solidity has a mismatch between `address.transfer()` and `token.transfer()`:
    // https://github.com/ethereum/solidity/issues/3544
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb;

    string private constant ERROR_TOKEN_BALANCE_REVERTED = "SAFE_ERC_20_BALANCE_REVERTED";
    string private constant ERROR_TOKEN_ALLOWANCE_REVERTED = "SAFE_ERC_20_ALLOWANCE_REVERTED";

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata)
        private
        returns (bool)
    {
        bool ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            let success := call(
                gas,                  // forward all gas
                _addr,                // address
                0,                    // no value
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                // Check number of bytes returned from last function call
                switch returndatasize

                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }

                // 32 bytes returned: check if non-zero
                case 0x20 {
                    // Only return success if returned data was true
                    // Already have output in ptr
                    ret := eq(mload(ptr), 1)
                }

                // Not sure what was returned: don't mark as success
                default { }
            }
        }
        return ret;
    }

    function staticInvoke(address _addr, bytes memory _calldata)
        private
        view
        returns (bool, uint256)
    {
        bool success;
        uint256 ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            success := staticcall(
                gas,                  // forward all gas
                _addr,                // address
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                ret := mload(ptr)
            }
        }
        return (success, ret);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transfer() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransfer(ERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            TRANSFER_SELECTOR,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(_token, transferCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transferFrom() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransferFrom(ERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferFromCallData = abi.encodeWithSelector(
            _token.transferFrom.selector,
            _from,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(_token, transferFromCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.approve() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeApprove(ERC20 _token, address _spender, uint256 _amount) internal returns (bool) {
        bytes memory approveCallData = abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _amount
        );
        return invokeAndCheckSuccess(_token, approveCallData);
    }

    /**
    * @dev Static call into ERC20.balanceOf().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticBalanceOf(ERC20 _token, address _owner) internal view returns (uint256) {
        bytes memory balanceOfCallData = abi.encodeWithSelector(
            _token.balanceOf.selector,
            _owner
        );

        (bool success, uint256 tokenBalance) = staticInvoke(_token, balanceOfCallData);
        require(success, ERROR_TOKEN_BALANCE_REVERTED);

        return tokenBalance;
    }

    /**
    * @dev Static call into ERC20.allowance().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticAllowance(ERC20 _token, address _owner, address _spender) internal view returns (uint256) {
        bytes memory allowanceCallData = abi.encodeWithSelector(
            _token.allowance.selector,
            _owner,
            _spender
        );

        (bool success, uint256 allowance) = staticInvoke(_token, allowanceCallData);
        require(success, ERROR_TOKEN_ALLOWANCE_REVERTED);

        return allowance;
    }
}

// File: @aragon/os/contracts/common/VaultRecoverable.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;







contract VaultRecoverable is IVaultRecoverable, EtherTokenConstant, IsContract {
    using SafeERC20 for ERC20;

    string private constant ERROR_DISALLOWED = "RECOVER_DISALLOWED";
    string private constant ERROR_VAULT_NOT_CONTRACT = "RECOVER_VAULT_NOT_CONTRACT";
    string private constant ERROR_TOKEN_TRANSFER_FAILED = "RECOVER_TOKEN_TRANSFER_FAILED";

    /**
     * @notice Send funds to recovery Vault. This contract should never receive funds,
     *         but in case it does, this function allows one to recover them.
     * @param _token Token balance to be sent to recovery vault.
     */
    function transferToVault(address _token) external {
        require(allowRecoverability(_token), ERROR_DISALLOWED);
        address vault = getRecoveryVault();
        require(isContract(vault), ERROR_VAULT_NOT_CONTRACT);

        uint256 balance;
        if (_token == ETH) {
            balance = address(this).balance;
            vault.transfer(balance);
        } else {
            ERC20 token = ERC20(_token);
            balance = token.staticBalanceOf(this);
            require(token.safeTransfer(vault, balance), ERROR_TOKEN_TRANSFER_FAILED);
        }

        emit RecoverToVault(vault, _token, balance);
    }

    /**
    * @dev By default deriving from AragonApp makes it recoverable
    * @param token Token address that would be recovered
    * @return bool whether the app allows the recovery
    */
    function allowRecoverability(address token) public view returns (bool) {
        return true;
    }

    // Cast non-implemented interface to be public so we can use it internally
    function getRecoveryVault() public view returns (address);
}

// File: @aragon/os/contracts/evmscript/IEVMScriptExecutor.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


interface IEVMScriptExecutor {
    function execScript(bytes script, bytes input, address[] blacklist) external returns (bytes);
    function executorType() external pure returns (bytes32);
}

// File: @aragon/os/contracts/evmscript/IEVMScriptRegistry.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;



contract EVMScriptRegistryConstants {
    /* Hardcoded constants to save gas
    bytes32 internal constant EVMSCRIPT_REGISTRY_APP_ID = apmNamehash("evmreg");
    */
    bytes32 internal constant EVMSCRIPT_REGISTRY_APP_ID = 0xddbcfd564f642ab5627cf68b9b7d374fb4f8a36e941a75d89c87998cef03bd61;
}


interface IEVMScriptRegistry {
    function addScriptExecutor(IEVMScriptExecutor executor) external returns (uint id);
    function disableScriptExecutor(uint256 executorId) external;

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function getScriptExecutor(bytes script) public view returns (IEVMScriptExecutor);
}

// File: @aragon/os/contracts/kernel/KernelConstants.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


contract KernelAppIds {
    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_CORE_APP_ID = apmNamehash("kernel");
    bytes32 internal constant KERNEL_DEFAULT_ACL_APP_ID = apmNamehash("acl");
    bytes32 internal constant KERNEL_DEFAULT_VAULT_APP_ID = apmNamehash("vault");
    */
    bytes32 internal constant KERNEL_CORE_APP_ID = 0x3b4bf6bf3ad5000ecf0f989d5befde585c6860fea3e574a4fab4c49d1c177d9c;
    bytes32 internal constant KERNEL_DEFAULT_ACL_APP_ID = 0xe3262375f45a6e2026b7e7b18c2b807434f2508fe1a2a3dfb493c7df8f4aad6a;
    bytes32 internal constant KERNEL_DEFAULT_VAULT_APP_ID = 0x7e852e0fcfce6551c13800f1e7476f982525c2b5277ba14b24339c68416336d1;
}


contract KernelNamespaceConstants {
    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_CORE_NAMESPACE = keccak256("core");
    bytes32 internal constant KERNEL_APP_BASES_NAMESPACE = keccak256("base");
    bytes32 internal constant KERNEL_APP_ADDR_NAMESPACE = keccak256("app");
    */
    bytes32 internal constant KERNEL_CORE_NAMESPACE = 0xc681a85306374a5ab27f0bbc385296a54bcd314a1948b6cf61c4ea1bc44bb9f8;
    bytes32 internal constant KERNEL_APP_BASES_NAMESPACE = 0xf1f3eb40f5bc1ad1344716ced8b8a0431d840b5783aea1fd01786bc26f35ac0f;
    bytes32 internal constant KERNEL_APP_ADDR_NAMESPACE = 0xd6f028ca0e8edb4a8c9757ca4fdccab25fa1e0317da1188108f7d2dee14902fb;
}

// File: @aragon/os/contracts/evmscript/EVMScriptRunner.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;







contract EVMScriptRunner is AppStorage, Initializable, EVMScriptRegistryConstants, KernelNamespaceConstants {
    string private constant ERROR_EXECUTOR_UNAVAILABLE = "EVMRUN_EXECUTOR_UNAVAILABLE";
    string private constant ERROR_PROTECTED_STATE_MODIFIED = "EVMRUN_PROTECTED_STATE_MODIFIED";

    /* This is manually crafted in assembly
    string private constant ERROR_EXECUTOR_INVALID_RETURN = "EVMRUN_EXECUTOR_INVALID_RETURN";
    */

    event ScriptResult(address indexed executor, bytes script, bytes input, bytes returnData);

    function getEVMScriptExecutor(bytes _script) public view returns (IEVMScriptExecutor) {
        return IEVMScriptExecutor(getEVMScriptRegistry().getScriptExecutor(_script));
    }

    function getEVMScriptRegistry() public view returns (IEVMScriptRegistry) {
        address registryAddr = kernel().getApp(KERNEL_APP_ADDR_NAMESPACE, EVMSCRIPT_REGISTRY_APP_ID);
        return IEVMScriptRegistry(registryAddr);
    }

    function runScript(bytes _script, bytes _input, address[] _blacklist)
        internal
        isInitialized
        protectState
        returns (bytes)
    {
        IEVMScriptExecutor executor = getEVMScriptExecutor(_script);
        require(address(executor) != address(0), ERROR_EXECUTOR_UNAVAILABLE);

        bytes4 sig = executor.execScript.selector;
        bytes memory data = abi.encodeWithSelector(sig, _script, _input, _blacklist);

        bytes memory output;
        assembly {
            let success := delegatecall(
                gas,                // forward all gas
                executor,           // address
                add(data, 0x20),    // calldata start
                mload(data),        // calldata length
                0,                  // don't write output (we'll handle this ourselves)
                0                   // don't write output
            )

            output := mload(0x40) // free mem ptr get

            switch success
            case 0 {
                // If the call errored, forward its full error data
                returndatacopy(output, 0, returndatasize)
                revert(output, returndatasize)
            }
            default {
                switch gt(returndatasize, 0x3f)
                case 0 {
                    // Need at least 0x40 bytes returned for properly ABI-encoded bytes values,
                    // revert with "EVMRUN_EXECUTOR_INVALID_RETURN"
                    // See remix: doing a `revert("EVMRUN_EXECUTOR_INVALID_RETURN")` always results in
                    // this memory layout
                    mstore(output, 0x08c379a000000000000000000000000000000000000000000000000000000000)         // error identifier
                    mstore(add(output, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020) // starting offset
                    mstore(add(output, 0x24), 0x000000000000000000000000000000000000000000000000000000000000001e) // reason length
                    mstore(add(output, 0x44), 0x45564d52554e5f4558454355544f525f494e56414c49445f52455455524e0000) // reason

                    revert(output, 100) // 100 = 4 + 3 * 32 (error identifier + 3 words for the ABI encoded error)
                }
                default {
                    // Copy result
                    //
                    // Needs to perform an ABI decode for the expected `bytes` return type of
                    // `executor.execScript()` as solidity will automatically ABI encode the returned bytes as:
                    //    [ position of the first dynamic length return value = 0x20 (32 bytes) ]
                    //    [ output length (32 bytes) ]
                    //    [ output content (N bytes) ]
                    //
                    // Perform the ABI decode by ignoring the first 32 bytes of the return data
                    let copysize := sub(returndatasize, 0x20)
                    returndatacopy(output, 0x20, copysize)

                    mstore(0x40, add(output, copysize)) // free mem ptr set
                }
            }
        }

        emit ScriptResult(address(executor), _script, _input, output);

        return output;
    }

    modifier protectState {
        address preKernel = address(kernel());
        bytes32 preAppId = appId();
        _; // exec
        require(address(kernel()) == preKernel, ERROR_PROTECTED_STATE_MODIFIED);
        require(appId() == preAppId, ERROR_PROTECTED_STATE_MODIFIED);
    }
}

// File: @aragon/os/contracts/apps/AragonApp.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;









// Contracts inheriting from AragonApp are, by default, immediately petrified upon deployment so
// that they can never be initialized.
// Unless overriden, this behaviour enforces those contracts to be usable only behind an AppProxy.
// ReentrancyGuard, EVMScriptRunner, and ACLSyntaxSugar are not directly used by this contract, but
// are included so that they are automatically usable by subclassing contracts
contract AragonApp is AppStorage, Autopetrified, VaultRecoverable, ReentrancyGuard, EVMScriptRunner, ACLSyntaxSugar {
    string private constant ERROR_AUTH_FAILED = "APP_AUTH_FAILED";

    modifier auth(bytes32 _role) {
        require(canPerform(msg.sender, _role, new uint256[](0)), ERROR_AUTH_FAILED);
        _;
    }

    modifier authP(bytes32 _role, uint256[] _params) {
        require(canPerform(msg.sender, _role, _params), ERROR_AUTH_FAILED);
        _;
    }

    /**
    * @dev Check whether an action can be performed by a sender for a particular role on this app
    * @param _sender Sender of the call
    * @param _role Role on this app
    * @param _params Permission params for the role
    * @return Boolean indicating whether the sender has the permissions to perform the action.
    *         Always returns false if the app hasn't been initialized yet.
    */
    function canPerform(address _sender, bytes32 _role, uint256[] _params) public view returns (bool) {
        if (!hasInitialized()) {
            return false;
        }

        IKernel linkedKernel = kernel();
        if (address(linkedKernel) == address(0)) {
            return false;
        }

        return linkedKernel.hasPermission(
            _sender,
            address(this),
            _role,
            ConversionHelpers.dangerouslyCastUintArrayToBytes(_params)
        );
    }

    /**
    * @dev Get the recovery vault for the app
    * @return Recovery vault address for the app
    */
    function getRecoveryVault() public view returns (address) {
        // Funds recovery via a vault is only available when used with a kernel
        return kernel().getRecoveryVault(); // if kernel is not set, it will revert
    }
}

// File: @aragon/os/contracts/lib/math/SafeMath.sol

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/d51e38758e1d985661534534d5c61e27bece5042/contracts/math/SafeMath.sol
// Adapted to use pragma ^0.4.24 and satisfy our linter rules

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// File: @aragon/os/contracts/lib/math/SafeMath64.sol

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/d51e38758e1d985661534534d5c61e27bece5042/contracts/math/SafeMath.sol
// Adapted for uint64, pragma ^0.4.24, and satisfying our linter rules
// Also optimized the mul() implementation, see https://github.com/aragon/aragonOS/pull/417

pragma solidity ^0.4.24;


/**
 * @title SafeMath64
 * @dev Math operations for uint64 with safety checks that revert on error
 */
library SafeMath64 {
    string private constant ERROR_ADD_OVERFLOW = "MATH64_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH64_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH64_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH64_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint256 c = uint256(_a) * uint256(_b);
        require(c < 0x010000000000000000, ERROR_MUL_OVERFLOW); // 2**64 (less gas this way)

        return uint64(c);
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint64 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint64 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint64 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// File: @aragon/os/contracts/common/DepositableStorage.sol

pragma solidity 0.4.24;



contract DepositableStorage {
    using UnstructuredStorage for bytes32;

    // keccak256("aragonOS.depositableStorage.depositable")
    bytes32 internal constant DEPOSITABLE_POSITION = 0x665fd576fbbe6f247aff98f5c94a561e3f71ec2d3c988d56f12d342396c50cea;

    function isDepositable() public view returns (bool) {
        return DEPOSITABLE_POSITION.getStorageBool();
    }

    function setDepositable(bool _depositable) internal {
        DEPOSITABLE_POSITION.setStorageBool(_depositable);
    }
}

// File: @aragon/apps-vault/contracts/Vault.sol

pragma solidity 0.4.24;







contract Vault is EtherTokenConstant, AragonApp, DepositableStorage {
    using SafeERC20 for ERC20;

    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    string private constant ERROR_DATA_NON_ZERO = "VAULT_DATA_NON_ZERO";
    string private constant ERROR_NOT_DEPOSITABLE = "VAULT_NOT_DEPOSITABLE";
    string private constant ERROR_DEPOSIT_VALUE_ZERO = "VAULT_DEPOSIT_VALUE_ZERO";
    string private constant ERROR_TRANSFER_VALUE_ZERO = "VAULT_TRANSFER_VALUE_ZERO";
    string private constant ERROR_SEND_REVERTED = "VAULT_SEND_REVERTED";
    string private constant ERROR_VALUE_MISMATCH = "VAULT_VALUE_MISMATCH";
    string private constant ERROR_TOKEN_TRANSFER_FROM_REVERTED = "VAULT_TOKEN_TRANSFER_FROM_REVERT";
    string private constant ERROR_TOKEN_TRANSFER_REVERTED = "VAULT_TOKEN_TRANSFER_REVERTED";

    event VaultTransfer(address indexed token, address indexed to, uint256 amount);
    event VaultDeposit(address indexed token, address indexed sender, uint256 amount);

    /**
    * @dev On a normal send() or transfer() this fallback is never executed as it will be
    *      intercepted by the Proxy (see aragonOS#281)
    */
    function () external payable isInitialized {
        require(msg.data.length == 0, ERROR_DATA_NON_ZERO);
        _deposit(ETH, msg.value);
    }

    /**
    * @notice Initialize Vault app
    * @dev As an AragonApp it needs to be initialized in order for roles (`auth` and `authP`) to work
    */
    function initialize() external onlyInit {
        initialized();
        setDepositable(true);
    }

    /**
    * @notice Deposit `_value` `_token` to the vault
    * @param _token Address of the token being transferred
    * @param _value Amount of tokens being transferred
    */
    function deposit(address _token, uint256 _value) external payable isInitialized {
        _deposit(_token, _value);
    }

    /**
    * @notice Transfer `_value` `_token` from the Vault to `_to`
    * @param _token Address of the token being transferred
    * @param _to Address of the recipient of tokens
    * @param _value Amount of tokens being transferred
    */
    /* solium-disable-next-line function-order */
    function transfer(address _token, address _to, uint256 _value)
        external
        authP(TRANSFER_ROLE, arr(_token, _to, _value))
    {
        require(_value > 0, ERROR_TRANSFER_VALUE_ZERO);

        if (_token == ETH) {
            require(_to.send(_value), ERROR_SEND_REVERTED);
        } else {
            require(ERC20(_token).safeTransfer(_to, _value), ERROR_TOKEN_TRANSFER_REVERTED);
        }

        emit VaultTransfer(_token, _to, _value);
    }

    function balance(address _token) public view returns (uint256) {
        if (_token == ETH) {
            return address(this).balance;
        } else {
            return ERC20(_token).staticBalanceOf(address(this));
        }
    }

    /**
    * @dev Disable recovery escape hatch, as it could be used
    *      maliciously to transfer funds away from the vault
    */
    function allowRecoverability(address) public view returns (bool) {
        return false;
    }

    function _deposit(address _token, uint256 _value) internal {
        require(isDepositable(), ERROR_NOT_DEPOSITABLE);
        require(_value > 0, ERROR_DEPOSIT_VALUE_ZERO);

        if (_token == ETH) {
            // Deposit is implicit in this case
            require(msg.value == _value, ERROR_VALUE_MISMATCH);
        } else {
            require(
                ERC20(_token).safeTransferFrom(msg.sender, address(this), _value),
                ERROR_TOKEN_TRANSFER_FROM_REVERTED
            );
        }

        emit VaultDeposit(_token, msg.sender, _value);
    }
}

// File: contracts/Allocations.sol

/*
 * SPDX-License-Identitifer: GPL-3.0-or-later
 */

pragma solidity ^0.4.24;






contract Allocations is AragonApp {

    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using SafeERC20 for ERC20;

    bytes32 public constant CREATE_ACCOUNT_ROLE = 0x9b9e262b9ea0587fdc5926b22b8ed5837efef4f4cc67bc1a7ee18f68ad83062f;
    bytes32 public constant CREATE_ALLOCATION_ROLE = 0x8af1e3d6225e5adff5174a4949cb3cc04f0f62937083325a9e302eaf5d07cdf1;
    bytes32 public constant EXECUTE_ALLOCATION_ROLE = 0x1ced0be26d1bb2db7a1a0a01064be22894ce4ca0321b6f4b28d0b1a5ce62e7ea;
    bytes32 public constant EXECUTE_PAYOUT_ROLE = 0xa5cf757319c734091fd95cf4b09938ff69ee22637eda897ea92ca59e56f00bcb;
    bytes32 public constant CHANGE_PERIOD_ROLE = 0xd35e458bacdd5343c2f050f574554b2f417a8ea38d6a9a65ce2225dbe8bb9a9d;
    bytes32 public constant CHANGE_BUDGETS_ROLE = 0xd79730e82bfef7d2f9639b9d10bf37ebb662b22ae2211502a00bdf7b2cc3a23a;
    bytes32 public constant SET_MAX_CANDIDATES_ROLE = 0xe593f1908655effa3e2eb1eab075684bd646a51d97f20646bb9ecb2df3e4f2bb;

    uint256 internal constant MAX_UINT256 = uint256(-1);
    uint64 internal constant MAX_UINT64 = uint64(-1);
    uint64 internal constant MINIMUM_PERIOD = uint64(1 days);
    uint256 internal constant MAX_SCHEDULED_PAYOUTS_PER_TX = 20;

    string private constant ERROR_NO_PERIOD = "NO_PERIOD";
    string private constant ERROR_NO_ACCOUNT = "NO_ACCOUNT";
    string private constant ERROR_NO_PAYOUT = "NO_PAYOUT";
    string private constant ERROR_NO_CANDIDATE = "NO_CANDIDATE";
    string private constant ERROR_PERIOD_SHORT = "SET_PERIOD_TOO_SHORT";
    string private constant ERROR_COMPLETE_TRANSITION = "COMPLETE_TRANSITION";
    string private constant ERROR_MIN_RECURRENCE = "RECURRENCES_BELOW_ONE";
    string private constant ERROR_CANDIDATE_NOT_RECEIVER = "CANDIDATE_NOT_RECEIVER";
    string private constant ERROR_INSUFFICIENT_FUNDS = "INSUFFICIENT_FUNDS";

    struct Payout {
        uint64 startTime;
        uint64 recurrences;
        uint64 period;
        address[] candidateAddresses;
        uint256[] supports;
        uint64[] executions;
        uint256 amount;
        string description;
    }

    struct Account {
        uint64 payoutsLength;
        bool hasBudget;
        address token;
        mapping (uint64 => Payout) payouts;
        string metadata;
        uint256 budget;
    }

    struct AccountStatement {
        mapping(address => uint256) expenses;
    }

    struct Period {
        uint64 startTime;
        uint64 endTime;
        mapping (uint256 => AccountStatement) accountStatement;
    }

    uint64 accountsLength;
    uint64 periodsLength;
    uint64 periodDuration;
    uint256 maxCandidates;
    Vault public vault;
    mapping (uint64 => Account) accounts;
    mapping (uint64 => Period) periods;
    mapping(address => uint) accountProxies; // proxy address -> account Id

    event PayoutExecuted(uint64 accountId, uint64 payoutId, uint candidateId);
    event NewAccount(uint64 accountId);
    event NewPeriod(uint64 indexed periodId, uint64 periodStarts, uint64 periodEnds);
    event FundAccount(uint64 accountId);
    event SetDistribution(uint64 accountId, uint64 payoutId);
    event PaymentFailure(uint64 accountId, uint64 payoutId, uint256 candidateId);
    event SetBudget(uint256 indexed accountId, uint256 amount, string name, bool hasBudget);
    event ChangePeriodDuration(uint64 newDuration);

    modifier periodExists(uint64 _periodId) {
        require(_periodId < periodsLength, ERROR_NO_PERIOD);
        _;
    }

    modifier accountExists(uint64 _accountId) {
        require(_accountId < accountsLength, ERROR_NO_ACCOUNT);
        _;
    }

    modifier payoutExists(uint64 _accountId, uint64 _payoutId) {
        require(_payoutId < accounts[_accountId].payoutsLength, ERROR_NO_PAYOUT);
        _;
    }

    // Modifier used by all methods that impact accounting to make sure accounting period
    // is changed before the operation if needed
    // NOTE: its use **MUST** be accompanied by an initialization check
    modifier transitionsPeriod {
        require(
            _tryTransitionAccountingPeriod(getMaxPeriodTransitions()),
            ERROR_COMPLETE_TRANSITION
        );
        _;
    }

    /**
    * @dev On initialization the contract sets a vault, and initializes the periods
    *      and accounts.
    * @param _vault The Aragon vault to pull payments from.
    * @param _periodDuration Base duration of a "period" used for value calculations.
    */
    function initialize(
        Vault _vault,
        uint64 _periodDuration
    ) external onlyInit
    {
        vault = _vault;
        require(_periodDuration >= MINIMUM_PERIOD, ERROR_PERIOD_SHORT);
        periodDuration = _periodDuration;
        _newPeriod(getTimestamp64());
        accountsLength++;  // position 0 is reserved and unused
        maxCandidates = 50;
        initialized();
    }

///////////////////////
// Getter functions
///////////////////////
    /** @notice Basic getter for accounts.
    *   @param _accountId The budget ID you'd like to get.
    */
    function getAccount(uint64 _accountId) external view accountExists(_accountId) isInitialized
    returns(string metadata, address token, bool hasBudget, uint256 budget)
    {
        Account storage account = accounts[_accountId];
        metadata = account.metadata;
        token = account.token;
        hasBudget = account.hasBudget;
        budget = account.budget;
    }

    /** @notice Basic getter for Allocations.
    *   @param _accountId The ID of the budget.
    *   @param _payoutId The ID of the allocation within the budget you'd like to retrieve.
    */
    function getPayout(uint64 _accountId, uint64 _payoutId) external view payoutExists(_accountId, _payoutId) isInitialized
    returns(uint amount, uint64 recurrences, uint startTime, uint period)
    {
        Payout storage payout = accounts[_accountId].payouts[_payoutId];
        amount = payout.amount;
        recurrences = payout.recurrences;
        startTime = payout.startTime;
        period = payout.period;
    }

    /**
    * @notice get the account's remaining budget for the current period
    * @param _accountId The account ID of the budget remaining to be calculated
    */
    function getRemainingBudget(uint64 _accountId) external view accountExists(_accountId)
    returns(uint256)
    {
        return _getRemainingBudget(_accountId);
    }

    /** @notice Basic getter for Allocation descriptions.
    *   @param _accountId The Id of the budget.
    *   @param _payoutId The Id of the allocation within the budget.
    */
    function getPayoutDescription(uint64 _accountId, uint64 _payoutId)
    external
    view
    payoutExists(_accountId, _payoutId)
    isInitialized
    returns(string description)
    {
        Payout storage payout = accounts[_accountId].payouts[_payoutId];
        description = payout.description;
    }

    /** @notice Basic getter for getting the number of options in an Allocation.
    *   @param _accountId The Id of the budget.
    *   @param _payoutId The Id of the allocation within the budget.
    */
    function getNumberOfCandidates(uint64 _accountId, uint64 _payoutId) external view isInitialized payoutExists(_accountId, _payoutId)
    returns(uint256 numCandidates)
    {
        Payout storage payout = accounts[_accountId].payouts[_payoutId];
        numCandidates = payout.supports.length;
    }

    /** @notice Basic getter for Allocation value for a specific recipient.
    *   @param _accountId The Id of the budget.
    *   @param _payoutId The Id of the allocation within the budget.
    *   @param _idx The Id of the specific recipient you'd like to retrieve information for.
    */
    function getPayoutDistributionValue(uint64 _accountId, uint64 _payoutId, uint256 _idx)
    external
    view
    isInitialized
    payoutExists(_accountId, _payoutId)
    returns(uint256 supports, address candidateAddress, uint64 executions)
    {
        Payout storage payout = accounts[_accountId].payouts[_payoutId];
        require(_idx < payout.supports.length, ERROR_NO_CANDIDATE);
        supports = payout.supports[_idx];
        candidateAddress = payout.candidateAddresses[_idx];
        executions = payout.executions[_idx];
    }

    /**
    * @dev We have to check for initialization as periods are only valid after initializing
    */
    function getCurrentPeriodId() external view isInitialized returns (uint64) {
        return _currentPeriodId();
    }

    /** @notice Basic getter for period information.
    *   @param _periodId The Id of the period you'd like to receive information for.
    */
    function getPeriod(uint64 _periodId)
    external
    view
    isInitialized
    periodExists(_periodId)
    returns (
        bool isCurrent,
        uint64 startTime,
        uint64 endTime
    )
    {
        Period storage period = periods[_periodId];

        isCurrent = _currentPeriodId() == _periodId;

        startTime = period.startTime;
        endTime = period.endTime;
    }

///////////////////////
// Allocation functions
///////////////////////
    /**
    * @dev This is the function that sets up a budget for creating allocations.
    * @notice Create "`_metadata`" budget of `@tokenAmount(_token, _budget)` per period.
    * @param _metadata The budget description
    * @param _token Token used for account payouts.
    * @param _hasBudget Whether the account uses budgeting.
    * @param _budget The budget amount
    */
    function newAccount(
        string _metadata,
        address _token,
        bool _hasBudget,
        uint256 _budget
    ) external auth(CREATE_ACCOUNT_ROLE) returns(uint64 accountId)
    {
        accountId = accountsLength++;
        Account storage account = accounts[accountId];
        account.metadata = _metadata;
        account.hasBudget = _hasBudget;
        account.budget = _budget;
        account.token = _token;
        emit NewAccount(accountId);
    }

    /**
    * @notice Change period duration to `@transformTime(_periodDuration)`, effective for next accounting period
    * @param _periodDuration Duration in seconds for accounting periods
    */
    function setPeriodDuration(uint64 _periodDuration)
        external
        auth(CHANGE_PERIOD_ROLE)
        transitionsPeriod
    {
        require(_periodDuration >= MINIMUM_PERIOD, ERROR_PERIOD_SHORT);
        periodDuration = _periodDuration;
        emit ChangePeriodDuration(_periodDuration);
    }

    /**
    * @notice Set the maximum number of candidates that can be paid out in an allocation to `_maxCandidates`.
    * @param _maxCandidates Maximum number of Candidates
    */
    function setMaxCandidates(uint256 _maxCandidates) external auth(SET_MAX_CANDIDATES_ROLE) {
        maxCandidates = _maxCandidates;
    }

    /**
    * @notice Update budget #`_accountId` to `@tokenAmount(0, _amount, false)`, effective immediately and optionally update metadata
    * @param _accountId Budget Identifier
    * @param _amount New budget amount
    * @param _metadata descriptor for the account (pass in empty string if unchanged)
    */
    function setBudget(
        uint64 _accountId,
        uint256 _amount,
        string _metadata
    )
        external
        auth(CHANGE_BUDGETS_ROLE)
        transitionsPeriod
        accountExists(_accountId)
    {
        accounts[_accountId].budget = _amount;
        // only access storage if necessary
        if (bytes(_metadata).length > 0) {
            accounts[_accountId].metadata = _metadata;
        }
        if (!accounts[_accountId].hasBudget) {
            accounts[_accountId].hasBudget = true;
        }
        emit SetBudget(_accountId, _amount, _metadata, true);
    }

    /**
    * @notice Remove budget #`_accountId`, effective immediately and optionally update budget name.
    * @param _accountId Id for the budget.
    * @param _metadata descriptor for account (pass in empty string if unchanged)
    */
    function removeBudget(uint64 _accountId, string _metadata)
        external
        auth(CHANGE_BUDGETS_ROLE)
        transitionsPeriod
        accountExists(_accountId)
    {
        accounts[_accountId].budget = 0;
        accounts[_accountId].hasBudget = false;
        // only access storage if necessary
        if (bytes(_metadata).length > 0) {
            accounts[_accountId].metadata = _metadata;
        }
        emit SetBudget(_accountId, 0, _metadata, false);
    }

    /**
    * @notice This transaction will execute the allocation for the senders address for budget #`_accountId`
    * @param _accountId The Id of the budget you'd like to take action against
    * @param _payoutId The Id of the allocation within the budget you'd like to execute
    * @param _candidateId The Candidate whose allocation you'll execute (must be sender)
    */
    function candidateExecutePayout(
        uint64 _accountId,
        uint64 _payoutId,
        uint256 _candidateId
    ) external transitionsPeriod isInitialized accountExists(_accountId) payoutExists(_accountId, _payoutId) // solium-disable-line error-reason
    {
        //Payout storage payout = accounts[_accountId].payouts[_payoutId];
        require(msg.sender == accounts[_accountId].payouts[_payoutId].candidateAddresses[_candidateId], ERROR_CANDIDATE_NOT_RECEIVER);
        _executePayoutAtLeastOnce(_accountId, _payoutId, _candidateId, 0);
    }

    /**
    * @notice This transaction will execute the allocation for candidate `_candidateId` within budget #`_accountId`
    * @param _accountId The Id of the budget you'd like to take action against
    * @param _payoutId The Id of the allocation within the budget you'd like to execute
    * @param _candidateId The Candidate whose allocation you'll execute (must be sender)
    */
    function executePayout(
        uint64 _accountId,
        uint64 _payoutId,
        uint256 _candidateId
    ) external transitionsPeriod auth(EXECUTE_PAYOUT_ROLE) accountExists(_accountId) payoutExists(_accountId, _payoutId)
    {
        _executePayoutAtLeastOnce(_accountId, _payoutId, _candidateId, 0);
    }

    /**
    * @dev This function distributes the allocations to the candidates in accordance with the distribution values
    * @notice Distribute allocation #`_payoutId` from budget #`_accountId`.
    * @param _accountId The Id of the budget you'd like to take action against
    * @param _payoutId The Id of the allocation within the budget you'd like to execute
    */
    function runPayout(uint64 _accountId, uint64 _payoutId)
    external
    auth(EXECUTE_ALLOCATION_ROLE)
    transitionsPeriod
    accountExists(_accountId)
    payoutExists(_accountId, _payoutId)
    returns(bool success)
    {
        success = _runPayout(_accountId, _payoutId);
    }

    /**
    * @dev This function is provided to circumvent situations where the transition period
    *      becomes impossible to execute
    * @param _limit Maximum number of periods to advance in this execution
    */
    function advancePeriod(uint64 _limit) external isInitialized {
        _tryTransitionAccountingPeriod(_limit);
    }

    /**
    * @dev This is the function that the DotVote will call. It doesn’t need
    *      to be called by a DotVote (options get weird if it's not)
    *      but for our use case the “CREATE_ALLOCATION_ROLE” will be given to
    *      the DotVote. This function is public for stack-depth reasons
    * @notice Create an allocation from budget #`_accountId` for "`_description`" `(_recurrences > 1) ? 'that will execute ' + _recurrences + ' times': ''`.
    * @param _candidateAddresses Array of potential addresses receiving a share of the allocation.
    * @param _supports The Array of all support values for the various candidates. These values are set in dot voting.
    * @param _description The distribution description
    * @param _accountId The Id of the budget used for the allocation
    * @param _recurrences Quantity used to indicate whether this is a recurring or one-time payout
    * @param _period Time interval between each recurring allocation
    * @param _amount The quantity of funds to be allocated
    */
    function setDistribution(
        address[] _candidateAddresses,
        uint256[] _supports,
        uint256[] /*unused_infoIndices*/,
        string /*unused_candidateInfo*/,
        string _description,
        uint256[] /*unused_level 1 ID - converted to bytes32*/,
        uint256[] /*unused_level 2 ID - converted to bytes32*/,
        uint64 _accountId,
        uint64 _recurrences,
        uint64 _startTime,
        uint64 _period,
        uint256 _amount
    ) public auth(CREATE_ALLOCATION_ROLE) returns(uint64 payoutId)
    {
        require(maxCandidates >= _candidateAddresses.length); // solium-disable-line error-reason
        Account storage account = accounts[_accountId];
        require(vault.balance(account.token) >= _amount * _recurrences); // solium-disable-line error-reason
        require(_recurrences > 0, ERROR_MIN_RECURRENCE);

        Payout storage payout = account.payouts[account.payoutsLength++];

        payout.amount = _amount;
        payout.recurrences = _recurrences;
        payout.candidateAddresses = _candidateAddresses;
        if (_recurrences > 1) {
            payout.period = _period;
            // minimum granularity is a single day
            require(payout.period >= 1 days, ERROR_PERIOD_SHORT);
        }
        payout.startTime = _startTime; // solium-disable-line security/no-block-members
        payout.supports = _supports;
        payout.description = _description;
        payout.executions.length = _supports.length;
        payoutId = account.payoutsLength - 1;
        emit SetDistribution(_accountId, payoutId);
        if (_startTime <= getTimestamp64()) {
            _runPayout(_accountId, payoutId);
        }
    }

    function _executePayoutAtLeastOnce(
        uint64 _accountId,
        uint64 _payoutId,
        uint256 _candidateId,
        uint256 _paid
    )
        internal accountExists(_accountId) returns (uint256)
    {
        Account storage account = accounts[_accountId];
        Payout storage payout = account.payouts[_payoutId];
        require(_candidateId < payout.supports.length, ERROR_NO_CANDIDATE); 

        uint256 paid = _paid;
        uint256 totalSupport = _getTotalSupport(payout);

        uint256 individualPayout = payout.supports[_candidateId].mul(payout.amount).div(totalSupport);
        if (individualPayout == 0) {
            return;
        }
        while (_nextPaymentTime(_accountId, _payoutId, _candidateId) <= getTimestamp64() && paid < MAX_SCHEDULED_PAYOUTS_PER_TX) {
            if (!_canMakePayment(_accountId, individualPayout)) {
                emit PaymentFailure(_accountId, _payoutId, _candidateId);
                break;
            }

            // The while() predicate prevents these two from ever overflowing
            paid += 1;

            // We've already checked the remaining budget with `_canMakePayment()`
            _executeCandidatePayout(_accountId, _payoutId, _candidateId, totalSupport);
        }
        return paid;
    }

    function _newPeriod(uint64 _startTime) internal returns (Period storage) {
        // There should be no way for this to overflow since each period is at least one day
        uint64 newPeriodId = periodsLength++;

        Period storage period = periods[newPeriodId];
        period.startTime = _startTime;

        // Be careful here to not overflow; if startTime + periodDuration overflows, we set endTime
        // to MAX_UINT64 (let's assume that's the end of time for now).
        uint64 endTime = _startTime + periodDuration - 1;
        if (endTime < _startTime) { // overflowed
            endTime = MAX_UINT64;
        }
        period.endTime = endTime;

        emit NewPeriod(newPeriodId, period.startTime, period.endTime);

        return period;
    }

    function _tryTransitionAccountingPeriod(uint64 _maxTransitions) internal returns (bool success) {
        Period storage currentPeriod = periods[_currentPeriodId()];
        uint64 maxTransitions = _maxTransitions;
        uint64 timestamp = getTimestamp64();

        // Transition periods if necessary
        while (timestamp > currentPeriod.endTime) {
            if (maxTransitions == 0) {
                // Required number of transitions is over allowed number, return false indicating
                // it didn't fully transition
                return false;
            }
            // We're already protected from underflowing above
            maxTransitions -= 1;

            currentPeriod = _newPeriod(currentPeriod.endTime.add(1));
        }

        return true;
    }

    function _currentPeriodId() internal view returns (uint64) {
        // There is no way for this to overflow if protected by an initialization check
        return periodsLength - 1;
    }

    function _canMakePayment(uint64 _accountId, uint256 _amount) internal view returns (bool) {
        Account storage account = accounts[_accountId];
        return _getRemainingBudget(_accountId) >= _amount && vault.balance(account.token) >= _amount && _amount > 0;
    }

    function _getRemainingBudget(uint64 _accountId) internal view returns (uint256) {
        Account storage account = accounts[_accountId];
        if (!account.hasBudget) {
            return MAX_UINT256;
        }

        uint256 budget = account.budget;
        uint256 spent = periods[_currentPeriodId()].accountStatement[_accountId].expenses[account.token];

        // A budget decrease can cause the spent amount to be greater than period budget
        // If so, return 0 to not allow more spending during period
        if (spent >= budget) {
            return 0;
        }

        // We're already protected from the overflow above
        return budget - spent;
    }

    function _runPayout(uint64 _accountId, uint64 _payoutId) internal returns(bool success) {
        Account storage account = accounts[_accountId];
        uint256[] storage supports = account.payouts[_payoutId].supports;
        uint64 i;
        uint256 paid = 0;
        uint256 length = account.payouts[_payoutId].candidateAddresses.length;
        //handle vault
        for (i = 0; i < length; i++) {
            if (supports[i] != 0 && _nextPaymentTime(_accountId, _payoutId, i) <= getTimestamp64()) {
                paid = _executePayoutAtLeastOnce(_accountId, _payoutId, i, paid);
            } else {
                emit PaymentFailure(_accountId, _payoutId, i);
            }
        }
        success = true;
    }

    function _getTotalSupport(Payout storage payout) internal view returns (uint256 totalSupport) {
        for (uint256 i = 0; i < payout.supports.length; i++) {
            totalSupport += payout.supports[i];
        }
    }

    function _nextPaymentTime(uint64 _accountId, uint64 _payoutId, uint256 _candidateIndex) internal view returns (uint64) {
        Account storage account = accounts[_accountId];
        Payout storage payout = account.payouts[_payoutId];

        if (payout.executions[_candidateIndex] >= payout.recurrences) {
            return MAX_UINT64; // re-executes in some billions of years time... should not need to worry
        }

        // Split in multiple lines to circumvent linter warning
        uint64 increase = payout.executions[_candidateIndex].mul(payout.period);
        uint64 nextPayment = payout.startTime.add(increase);
        return nextPayment;
    }

    function _executeCandidatePayout(
        uint64 _accountId,
        uint64 _payoutId,
        uint256 _candidateIndex,
        uint256 _totalSupport
    ) internal
    {
        Account storage account = accounts[_accountId];
        Payout storage payout = account.payouts[_payoutId];
        uint256 individualPayout = payout.supports[_candidateIndex].mul(payout.amount).div(_totalSupport);
        require(_canMakePayment(_accountId, individualPayout), ERROR_INSUFFICIENT_FUNDS);

        address token = account.token;
        uint256 expenses = periods[_currentPeriodId()].accountStatement[_accountId].expenses[token];
        periods[_currentPeriodId()].accountStatement[_accountId].expenses[token] = expenses.add(individualPayout);
        payout.executions[_candidateIndex] = payout.executions[_candidateIndex].add(1);
        vault.transfer(token, payout.candidateAddresses[_candidateIndex], individualPayout);
        emit PayoutExecuted(_accountId, _payoutId, _candidateIndex);
    }

    // Mocked fns (overrided during testing)
    // Must be view for mocking purposes

    function getMaxPeriodTransitions() internal view returns (uint64) { return MAX_UINT64; }
}