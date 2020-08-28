pragma solidity ^0.4.21;

contract BSX{

    uint256 totalSupply_; 
    string public constant name = "Bistox Exchange Token";
    string public constant symbol = "BSX";
    uint8 public constant decimals = 18;
    uint256 public constant initialSupply = 200000000 *(10**uint256(decimals));

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    mapping (address => uint256) balances; 
    mapping (address => mapping (address => uint256)) allowed;
    
    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256){
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool ) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value); 
        balances[msg.sender] = balances[msg.sender] - _value; 
        balances[_to] = balances[_to] + _value; 
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]); 
        balances[_from] = balances[_from] - _value; 
        balances[_to] = balances[_to] + _value; 
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value; 
        emit Transfer(_from, _to, _value); 
        return true; 
        } 

    function burn(uint256 _value) returns (bool success) {
        if (balances[msg.sender] < _value) throw;//проверка что на балансе есть нужное кол-во токенов
		if (_value <= 0) throw; 
        balances[msg.sender] = balances[msg.sender] - _value;// вычитание
        totalSupply_ = totalSupply_ - _value;// Новое значение totalSupply
        Burn(msg.sender, _value);// Запуск события Burn
        return true;
    }
    
     function increaseApproval(address _spender, uint _addedValue) public returns (bool) { 
     allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue; 
     emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]); 
     return true; 
     } 
 
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) { 
    uint oldValue = allowed[msg.sender][_spender]; 
    if (_subtractedValue > oldValue) {

        allowed[msg.sender][_spender] = 0;
    } 
        else {
        allowed[msg.sender][_spender] = oldValue - _subtractedValue;
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
    }

    function BSX(address owner) public {
        totalSupply_ = initialSupply;
        balances[address(owner)] = initialSupply;
        emit Transfer(0x0, address(owner), initialSupply);
    }
}