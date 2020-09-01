pragma solidity ^0.5.1;

library SafeMath {
  
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    
    address public owner = address(0);
    bool public stoped  = false;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Stoped(address setter ,bool newValue);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier whenNotStoped() {
        require(!stoped);
        _;
    }

    function setStoped(bool _needStoped) public onlyOwner {
        require(stoped != _needStoped);
        stoped = _needStoped;
        emit Stoped(msg.sender,_needStoped);
    }


    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Cmoable is Ownable {
    address public cmo = address(0);

    event CmoshipTransferred(address indexed previousCmo, address indexed newCmo);

    modifier onlyCmo() {
        require(msg.sender == cmo);
        _;
    }

    function renounceCmoship() public onlyOwner {
        emit CmoshipTransferred(cmo, address(0));
        owner = address(0);
    }

    function transferCmoship(address newCmo) public onlyOwner {
        _transferCmoship(newCmo);
    }

    function _transferCmoship(address newCmo) internal {
        require(newCmo != address(0));
        emit CmoshipTransferred(cmo, newCmo);
        cmo = newCmo;
    }
}


contract BaseToken is Ownable, Cmoable {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8  public decimals;
    uint256 public totalSupply;
    uint256 public initedSupply = 0;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwnerOrCmo() {
        require(msg.sender == cmo || msg.sender == owner);
        _;
    }

    function _transfer(address _from, address _to, uint256 _value) internal whenNotStoped {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        emit Transfer(_from, _to, _value);
    }
    
    function _approve(address _spender, uint256 _value) internal whenNotStoped returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        return _approve(_spender, _value);
    }
}








contract Proxyable is BaseToken{

    mapping (address => bool) public disabledProxyList;

    function enableProxy() public whenNotStoped {

        disabledProxyList[msg.sender] = false;
    }

    function disableProxy() public whenNotStoped{
        disabledProxyList[msg.sender] = true;
    }


    function proxyTransferFrom(address _from, address _to, uint256 _value) public onlyOwnerOrCmo returns (bool success) {
        
        require(!disabledProxyList[_from]);
        super._transfer(_from, _to, _value);
        return true;
    }

  
}

 

contract CustomToken is BaseToken,Proxyable {

    constructor() public {
        
  
        totalSupply  = 80000000000000000000000000;
        initedSupply = 80000000000000000000000000;
        name = 'Medical data link';
        symbol = 'MENT';
        decimals = 18;
        balanceOf[0xF741C9357F1b514bbB61E9B8fECc9c050DAE364b] = 80000000000000000000000000;
        emit Transfer(address(0), 0xF741C9357F1b514bbB61E9B8fECc9c050DAE364b, 80000000000000000000000000);

        // 管理者
        owner = 0xbC8e1AcA830A37646cEDEb14c7158F3F1529C909;
        cmo   = 0xA3A2B7d2Cb75D53FfAF710824a51a4B3cF30e9D1;
        




    }

}