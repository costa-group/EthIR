pragma solidity ^0.4.24;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract Token {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals = 6;
    uint256 public totalSupply;
    address public owner;

    address[] public ownerContracts;
    address public userPool;
    address public platformPool;
    address public smPool;

    //  burnPoolAddresses
    mapping(string => address) burnPoolAddresses;

    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event TransferETH(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);

    //990000000,"Alchemy Coin","ALC"
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) payable public  {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        owner = msg.sender;
    }

    // onlyOwner
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function setOwnerContracts(address _adr) public onlyOwner {
        if(_adr != 0x0){
            ownerContracts.push(_adr);
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(userPool != 0x0);
        require(platformPool != 0x0);
        require(smPool != 0x0);
        // check zero address
        require(_to != 0x0);
        // check zero address
        require(_value > 0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        uint256 burnTotal = 0;
        uint256 platformTotal = 0;
        // burn
        if (this == _to) {
            burnTotal = _value*3;
            platformTotal = _value.mul(15).div(100);
            require(balanceOf[owner] >= (burnTotal + platformTotal));
            balanceOf[userPool] = balanceOf[userPool].add(burnTotal);
            balanceOf[platformPool] = balanceOf[platformPool].add(platformTotal);
            balanceOf[owner] -= (burnTotal + platformTotal);
            emit Transfer(_from, _to, _value);
            emit Transfer(owner, userPool, burnTotal);
            emit Transfer(owner, platformPool, platformTotal);
            emit Burn(_from, _value);
        } else if (smPool == _from) {
            address smBurnAddress = burnPoolAddresses["smBurn"];
            require(smBurnAddress != 0x0);
            burnTotal = _value*3;
            platformTotal = _value.mul(15).div(100);
            require(balanceOf[owner] >= (burnTotal + platformTotal));
            balanceOf[userPool] = balanceOf[userPool].add(burnTotal);
            balanceOf[platformPool] = balanceOf[platformPool].add(platformTotal);
            balanceOf[owner] -= (burnTotal + platformTotal);
            emit Transfer(_from, _to, _value);
            emit Transfer(_to, smBurnAddress, _value);
            emit Transfer(owner, userPool, burnTotal);
            emit Transfer(owner, platformPool, platformTotal);
            emit Burn(_to, _value);
        } else {
            address appBurnAddress = burnPoolAddresses["appBurn"];
            address webBurnAddress = burnPoolAddresses["webBurn"];
            address normalBurnAddress = burnPoolAddresses["normalBurn"];
            if (_to == appBurnAddress || _to == webBurnAddress || _to == normalBurnAddress) {
                burnTotal = _value*3;
                platformTotal = _value.mul(15).div(100);
                require(balanceOf[owner] >= (burnTotal + platformTotal));
                balanceOf[userPool] = balanceOf[userPool].add(burnTotal);
                balanceOf[platformPool] = balanceOf[platformPool].add(platformTotal);
                balanceOf[owner] -= (burnTotal + platformTotal);
                emit Transfer(_from, _to, _value);
                emit Transfer(owner, userPool, burnTotal);
                emit Transfer(owner, platformPool, platformTotal);
                emit Burn(_from, _value);
            } else {
                balanceOf[_to] = balanceOf[_to].add(_value);
                emit Transfer(_from, _to, _value);
                assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
            }

        }
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferTo(address _to, uint256 _value) public {
        require(_contains());
        _transfer(tx.origin, _to, _value);
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * batch
     */
    function transferArray(address[] _to, uint256[] _value) public {
        require(_to.length == _value.length);
        uint256 sum = 0;
        for(uint256 i = 0; i< _value.length; i++) {
            sum += _value[i];
        }
        require(balanceOf[msg.sender] >= sum);
        for(uint256 k = 0; k < _to.length; k++){
            _transfer(msg.sender, _to[k], _value[k]);
        }
    }

    function setUserPoolAddress(address _userPoolAddress, address _platformPoolAddress, address _smPoolAddress) public onlyOwner {
        require(_userPoolAddress != 0x0);
        require(_platformPoolAddress != 0x0);
        require(_smPoolAddress != 0x0);
        userPool = _userPoolAddress;
        platformPool = _platformPoolAddress;
        smPool = _smPoolAddress;
    }

    function setBurnPoolAddress(string key, address _burnPoolAddress) public onlyOwner {
        if (_burnPoolAddress != 0x0)
        burnPoolAddresses[key] = _burnPoolAddress;
    }

    function  getBurnPoolAddress(string key) public view returns (address) {
        return burnPoolAddresses[key];
    }

    function smTransfer(address _to, uint256 _value) public returns (bool)  {
        require(smPool == msg.sender);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function burnTransfer(address _from, uint256 _value, string key) public returns (bool)  {
        require(burnPoolAddresses[key] != 0x0);
        _transfer(_from, burnPoolAddresses[key], _value);
        return true;
    }

    function () payable public {
    }

    function getETHBalance() view public returns(uint){
        return address(this).balance;
    }

    function transferETH(address[] _tos) public onlyOwner returns (bool) {
        require(_tos.length > 0);
        require(address(this).balance > 0);
        for(uint32 i=0;i<_tos.length;i++){
            _tos[i].transfer(address(this).balance/_tos.length);
            emit TransferETH(owner, _tos[i], address(this).balance/_tos.length);
        }
        return true;
    }

    function transferETH(address _to, uint256 _value) payable public onlyOwner returns (bool){
        require(_value > 0);
        require(address(this).balance >= _value);
        require(_to != address(0));
        _to.transfer(_value);
        emit TransferETH(owner, _to, _value);
        return true;
    }

    function transferETH(address _to) payable public onlyOwner returns (bool){
        require(_to != address(0));
        require(address(this).balance > 0);
        _to.transfer(address(this).balance);
        emit TransferETH(owner, _to, address(this).balance);
        return true;
    }

    function transferETH() payable public onlyOwner returns (bool){
        require(address(this).balance > 0);
        owner.transfer(address(this).balance);
        emit TransferETH(owner, owner, address(this).balance);
        return true;
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * @dev Destoys `amount` tokens from the caller.
     *
     * See `ERC20._burn`.
     */
    function burn(uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function burnFrom(address _from, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

    // funding
    function funding() payable public returns (bool) {
        require(msg.value <= balanceOf[owner]);
        // SafeMath.sub will throw if there is not enough balance.
        balanceOf[owner] = balanceOf[owner].sub(msg.value);
        balanceOf[tx.origin] = balanceOf[tx.origin].add(msg.value);
        emit Transfer(owner, tx.origin, msg.value);
        return true;
    }

    function _contains() internal view returns (bool) {
        for(uint i = 0; i < ownerContracts.length; i++){
            if(ownerContracts[i] == msg.sender){
                return true;
            }
        }
        return false;
    }
}
