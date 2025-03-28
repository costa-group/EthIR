/**

 *Submitted for verification at Etherscan.io on 2019-11-11

*/



pragma solidity ^0.5.12;
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {

        uint256 result = a * b;

        assert(a == 0 || result / a == b);

        return result;

    }



    function div(uint256 a, uint256 b) internal pure returns(uint256) {

        uint256 result = a / b;

        return result;

    }



    function sub(uint256 a, uint256 b) internal pure returns(uint256) {

        assert(b <= a);

        return a - b;

    }



    function add(uint256 a, uint256 b) internal pure returns(uint256) {

        uint256 result = a + b;

        assert(result >= a);

        return result;

    }

}



contract ERC20Basic {

    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function balanceOf(address who) public view returns(uint256);

    function transfer(address to, uint256 value) public returns(bool);

}



contract ERC20 is ERC20Basic {

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function allowance(address owner, address spender) public view returns(uint256);

    function approve(address spender, uint256 value) public returns(bool);

    function transferFrom(address from, address to, uint256 value) public returns(bool);

}



contract BasicToken is ERC20Basic {

    using SafeMath for uint256;



    struct WalletData {

        uint256 tokensAmount; //Tokens amount on wallet

        uint256 freezedAmount; //Freezed tokens amount on wallet.

        bool canFreezeTokens; //Is wallet can freeze tokens or not.

        uint unfreezeDate; // Date when we can unfreeze tokens on wallet.

    }



    mapping(address => WalletData) wallets;



    function transfer(address _to, uint256 _value) public notSender(_to) returns(bool) {

        require(_to != address(0) && _value > 0 &&

            wallets[msg.sender].tokensAmount >= _value &&

            checkIfCanUseTokens(msg.sender, _value));



        uint256 amount = wallets[msg.sender].tokensAmount.sub(_value);

        wallets[msg.sender].tokensAmount = amount;

        wallets[_to].tokensAmount = wallets[_to].tokensAmount.add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;

    }



    function balanceOf(address _owner) public view returns(uint256 balance) {

        return wallets[_owner].tokensAmount;

    }

    // Check wallet on unfreeze tokens amount

    function checkIfCanUseTokens(address _owner, uint256 _amount) internal view returns(bool) {

        uint256 unfreezedAmount = wallets[_owner].tokensAmount.sub(wallets[_owner].freezedAmount);

        return _amount <= unfreezedAmount;

    }



    // Prevents user to send transaction on his own address

    modifier notSender(address _owner) {

        require(msg.sender != _owner);

        _;

    }

}



contract StandartToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) allowed;



    function approve(address _spender, uint256 _value) public returns(bool) {

        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        if (allowed[msg.sender][_spender] == 0) {

            require(_value > 0);

            allowed[msg.sender][_spender] = _value;

            emit Approval(msg.sender, _spender, _value);

            return true;

        } else {

            allowed[msg.sender][_spender] = _value;

            emit Approval(msg.sender, _spender, _value);

            return true;

        }

    }



    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {

        return allowed[_owner][_spender];

    }



    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {

        require(_to != address(0) && _value > 0 &&

            checkIfCanUseTokens(_from, _value) &&

            _value <= wallets[_from].tokensAmount &&

            _value <= allowed[_from][msg.sender]);

        wallets[_from].tokensAmount = wallets[_from].tokensAmount.sub(_value);

        wallets[_to].tokensAmount = wallets[_to].tokensAmount.add(_value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;

    }

}



contract Ownable {

    constructor() public {

        owner = msg.sender;

    }

    event TransferOwnership(address indexed _previousOwner, address indexed _newOwner);

    address public owner;

    function transferOwnership(address _newOwner) public returns(bool);

    modifier onlyOwner() {

        require(msg.sender == owner);

        _;

    }

}



contract FreezableToken is StandartToken, Ownable {

    event ChangeFreezePermission(address indexed _owner, bool _permission);

    event FreezeTokens(address indexed _owner, uint256 _freezeAmount);

    event UnfreezeTokens(address indexed _owner, uint256 _unfreezeAmount);



    // Give\deprive permission to a wallet for freeze tokens.

    function giveFreezePermission(address[] memory _owners, bool _permission) public onlyOwner returns(bool) {

        for (uint i = 0; i < _owners.length; i++) {

            wallets[_owners[i]].canFreezeTokens = _permission;

            emit ChangeFreezePermission(_owners[i], _permission);

        }

        return true;

    }



    function freezeAllowance(address _owner) public view returns(bool) {

        return wallets[_owner].canFreezeTokens;

    }

    // Freeze tokens on sender wallet if have permission.

    function freezeTokens(uint256 _amount, uint _unfreezeDate) public isFreezeAllowed returns(bool) {

        //We can freeze tokens only if there are no frozen tokens on the wallet.

        require(wallets[msg.sender].freezedAmount == 0 &&

            wallets[msg.sender].tokensAmount >= _amount && _amount > 0);

        wallets[msg.sender].freezedAmount = _amount;

        wallets[msg.sender].unfreezeDate = _unfreezeDate;

        emit FreezeTokens(msg.sender, _amount);

        return true;

    }



    function showFreezedTokensAmount(address _owner) public view returns(uint256) {

        return wallets[_owner].freezedAmount;

    }



    function unfreezeTokens() public returns(bool) {

        require(wallets[msg.sender].freezedAmount > 0 &&

            now >= wallets[msg.sender].unfreezeDate);

        emit UnfreezeTokens(msg.sender, wallets[msg.sender].freezedAmount);

        wallets[msg.sender].freezedAmount = 0; // Unfreeze all tokens.

        wallets[msg.sender].unfreezeDate = 0;

        return true;

    }

    //Show date in UNIX time format.

    function showTokensUnfreezeDate(address _owner) public view returns(uint) {

        //If wallet don't have freezed tokens - function will return 0.

        return wallets[_owner].unfreezeDate;

    }



    function getUnfreezedTokens(address _owner) internal view returns(uint256) {

        return wallets[_owner].tokensAmount.sub(wallets[_owner].freezedAmount);

    }



    modifier isFreezeAllowed() {

        require(freezeAllowance(msg.sender));

        _;

    }

}





contract FlamengoDigitalCryptoCurrency is FreezableToken {

   

    event Burn(address indexed _from, uint256 _value);

    string constant public name = "(FDCC) Flamengo Digital Crypto Currency";

    string constant public symbol = "(FDCC)";

    uint constant public decimals = 18;

    uint256 constant public START_TOKENS = 70000000000 * 10 ** decimals; //65Mi start



    constructor() public {

        wallets[owner].tokensAmount = START_TOKENS;

        wallets[owner].canFreezeTokens = true;

        totalSupply = START_TOKENS;

    }



    function burn(uint256 value) public onlyOwner returns(bool) {

        require(checkIfCanUseTokens(owner, value) &&

            wallets[owner].tokensAmount >= value);

        wallets[owner].tokensAmount = wallets[owner].

        tokensAmount.sub(value);

        totalSupply = totalSupply.sub(value);

        emit Burn(owner, value);

        return true;

    }



    function transferOwnership(address _newOwner) public notSender(_newOwner) onlyOwner returns(bool) {

        require(_newOwner != address(0));

        emit TransferOwnership(owner, _newOwner);

        owner = _newOwner;

        return true;

    }



    function() payable external {

        revert();

    }





}