pragma solidity ^0.4.4;

contract Point {

    // 전체 포인트 금액 리턴
    function totalSupply() constant returns (uint256 supply) {}

    // _owner주소가 보유한 포인트 잔액 리턴
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     // _to수신 주소로 포인트 전달 결과 값 리턴(성공 또는 실패)
    function transfer(address _to, uint256 _value) returns (bool success) {}

    // 송신 주소에서 수신 주소로 포인트를 전송한 결과 리턴(성공 또는 실패)
    // approve()에서 사전 승인
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    // 발신 주소에서 포인트를 수신자(_spender)에게 인출할 수 있도록 권한 부여
    function approve(address _spender, uint256 _value) returns (bool success) {}

    // 포인트 소유자(_owner)가 포인트 수신자(_spender)에게 인출을 허락한 포인트 수 리턴
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    // 포인트 전송 이벤트 함수
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // 승인 이벤트 함수
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardPoint is Point {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract POPF20200201P1 is StandardPoint { // 수정 - 컨트랙트명 변경 (날짜 변경시 P앞자리 , 순번 변경시 P뒷자리)

    /* 변수 선언 */

    string public name;                        // 포인트명 변수   
    uint8 public decimals;                     // 포인트의 소숫점 이하 자릿수 변수, 표준을 준수하려면 18자리.
    string public symbol;                      // 포인트 Symbol 변수 
    string public version = 'P1.0';           // 버전 정보 변수
    uint256 public unitsOneEthCanBuy;     // 1 ETH로 구매 가능한 포인트 개수 정의 변수 
    uint256 public totalEthInWei;            // 총 발행 포인트 수(WEI 단위) , 0을 18개 제외하면 총 개수.
    address public fundsWallet;              // ETH를 받을 이더리움 주소  

    function POPF20200201P1() {          // 수정 -  위의 컨트랙트명과 일치해야 함.
        balances[msg.sender] = 10000000000000000000000000;           // 컨트랙트 Owner가 받을 전체 포인트 개수(WEI 단위) , 1천만개발행   
        totalSupply = 10000000000000000000000000;                       // 전체 공급 포인트 개수(WEI 단위) , 1천만개발행   
        name = "POPF20200201P1";                                        // 수정 - 표시용 포인트 이름  (컨트랙트명과 일치하거나 특허명칭으로 변경) 
        decimals = 18;                                                        // 포인트의 소숫점 이하 값 단위  
        symbol = "P";                                                         // 포인트 Symbol   
        unitsOneEthCanBuy = 100;                                         // 1 ETH로 구매 가능한 포인트 수(1 ETH = 100 P)   
        fundsWallet = msg.sender;                                        // ETH를 받을 이더리움 주소  
    }

    function() payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount); // 블록체인에 메세지 전송

        // ETH를 전송  
        fundsWallet.transfer(msg.value);                               
    }

    /* 계약 승인 요청 */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //여기에 계약을 포함 할 필요가 없다.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}