// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts/token/IETokenProxy.sol

/**
 * MIT License
 *
 * Copyright (c) 2019 eToroX Labs
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.4.24;

/**
 * @title Interface of an upgradable token
 * @dev See implementation for
 */
interface IETokenProxy {

    /* solium-disable zeppelin/missing-natspec-comments */

    /* Taken from ERC20Detailed in openzeppelin-solidity */
    function nameProxy(address sender) external view returns(string);

    function symbolProxy(address sender)
        external
        view
        returns(string);

    function decimalsProxy(address sender)
        external
        view
        returns(uint8);

    /* Taken from IERC20 in openzeppelin-solidity */
    function totalSupplyProxy(address sender)
        external
        view
        returns (uint256);

    function balanceOfProxy(address sender, address who)
        external
        view
        returns (uint256);

    function allowanceProxy(address sender,
                            address owner,
                            address spender)
        external
        view
        returns (uint256);

    function transferProxy(address sender, address to, uint256 value)
        external
        returns (bool);

    function approveProxy(address sender,
                          address spender,
                          uint256 value)
        external
        returns (bool);

    function transferFromProxy(address sender,
                               address from,
                               address to,
                               uint256 value)
        external
        returns (bool);

    function mintProxy(address sender, address to, uint256 value)
        external
        returns (bool);

    function changeMintingRecipientProxy(address sender,
                                         address mintingRecip)
        external;

    function burnProxy(address sender, uint256 value) external;

    function burnFromProxy(address sender,
                           address from,
                           uint256 value)
        external;

    function increaseAllowanceProxy(address sender,
                                    address spender,
                                    uint addedValue)
        external
        returns (bool success);

    function decreaseAllowanceProxy(address sender,
                                    address spender,
                                    uint subtractedValue)
        external
        returns (bool success);

    function pauseProxy(address sender) external;

    function unpauseProxy(address sender) external;

    function pausedProxy(address sender) external view returns (bool);

    function finalizeUpgrade() external;
}

// File: contracts/token/IEToken.sol

/**
 * MIT License
 *
 * Copyright (c) 2019 eToroX Labs
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.4.24;


/**
 * @title EToken interface
 * @dev The interface comprising an EToken contract
 * This interface is a superset of the ERC20 interface defined at
 * https://github.com/ethereum/EIPs/issues/20
 */
interface IEToken {

    /* solium-disable zeppelin/missing-natspec-comments */

    function upgrade(IETokenProxy upgradedToken) external;

    /* Taken from ERC20Detailed in openzeppelin-solidity */
    function name() external view returns(string);

    function symbol() external view returns(string);

    function decimals() external view returns(uint8);

    /* Taken from IERC20 in openzeppelin-solidity */
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
        external
        returns (bool);

    function transferFrom(address from, address to, uint256 value)
        external
        returns (bool);

    /* Taken from ERC20Mintable */
    function mint(address to, uint256 value) external returns (bool);

    /* Taken from ERC20Burnable */
    function burn(uint256 value) external;

    function burnFrom(address from, uint256 value) external;

    /* Taken from ERC20Pausable */
    function increaseAllowance(
        address spender,
        uint addedValue
    )
        external
        returns (bool success);

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function decreaseAllowance(
        address spender,
        uint subtractedValue
    )
        external
        returns (bool success);

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

// File: contracts/TokenManager.sol

/**
 * MIT License
 *
 * Copyright (c) 2019 eToroX Labs
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.4.24;



/**
 * @title The Token Manager contract
 * @dev Contract that keeps track of and adds new tokens to list
 */
contract TokenManager is Ownable {

    /**
     * @dev A TokenEntry defines a relation between an EToken instance and the
     * index of the names list containing the name of the token.
     */
    struct TokenEntry {
        bool exists;
        uint index;
        IEToken token;
    }

    mapping (bytes32 => TokenEntry) private tokens;
    bytes32[] private names;

    event TokenAdded(bytes32 indexed name, IEToken indexed addr);
    event TokenDeleted(bytes32 indexed name, IEToken indexed addr);
    event TokenUpgraded(bytes32 indexed name,
                        IEToken indexed from,
                        IEToken indexed to);

    /**
     * @dev Require that the token _name exists
     * @param _name Name of token that is looked for
     */
    modifier tokenExists(bytes32 _name) {
        require(_tokenExists(_name), "Token does not exist");
        _;
    }

    /**
     * @dev Require that the token _name does not exist
     * @param _name Name of token that is looked for
     */
    modifier tokenNotExists(bytes32 _name) {
        require(!(_tokenExists(_name)), "Token already exist");
        _;
    }

    /**
     * @dev Require that the token _iEToken is not null
     * @param _iEToken Token that is checked for
     */
    modifier notNullToken(IEToken _iEToken) {
        require(_iEToken != IEToken(0), "Supplied token is null");
        _;
    }

    /**
     * @dev Adds a token to the tokenmanager
     * @param _name Name of the token to be added
     * @param _iEToken Token to be added
     */
    function addToken(bytes32 _name, IEToken _iEToken)
        public
        onlyOwner
        tokenNotExists(_name)
        notNullToken(_iEToken)
    {
        tokens[_name] = TokenEntry({
            index: names.length,
            token: _iEToken,
            exists: true
        });
        names.push(_name);
        emit TokenAdded(_name, _iEToken);
    }

    /**
     * @dev Deletes a token.
     * @param _name Name of token to be deleted
     */
    function deleteToken(bytes32 _name)
        public
        onlyOwner
        tokenExists(_name)
    {
        IEToken prev = tokens[_name].token;
        delete names[tokens[_name].index];
        delete tokens[_name].token;
        delete tokens[_name];
        emit TokenDeleted(_name, prev);
    }

    /**
     * @dev Upgrades a token
     * @param _name Name of token to be upgraded
     * @param _iEToken Upgraded version of token
     */
    function upgradeToken(bytes32 _name, IEToken _iEToken)
        public
        onlyOwner
        tokenExists(_name)
        notNullToken(_iEToken)
    {
        IEToken prev = tokens[_name].token;
        tokens[_name].token = _iEToken;
        emit TokenUpgraded(_name, prev, _iEToken);
    }

    /**
     * @dev Finds a token of the specified name
     * @param _name Name of the token to be returned
     * @return The token of the given name
     */
    function getToken (bytes32 _name)
        public
        tokenExists(_name)
        view
        returns (IEToken)
    {
        return tokens[_name].token;
    }

    /**
     * @dev Gets all token names
     * @return A list of names
     */
    function getTokens ()
        public
        view
        returns (bytes32[])
    {
        return names;
    }

    /**
     * @dev Checks whether a token of specified name exists exists
     * in list of tokens
     * @param _name Name of token
     * @return true if a token of the given name exists
     */
    function _tokenExists (bytes32 _name)
        private
        view
        returns (bool)
    {
        return tokens[_name].exists;
    }

}