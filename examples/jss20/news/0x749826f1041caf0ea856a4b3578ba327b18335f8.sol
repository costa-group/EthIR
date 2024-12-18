// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract Tigereum {

    // ERC20 Token, with the addition of symbol, name and decimals and a
    // fixed supply

    string public constant name = 'Tigereum';
    string public constant symbol = 'TIG';
    uint8 public constant decimals = 18;
    address public owner;
    string public webAddress;
    uint internal constant _totalSupply = 50000000 * 10**uint(decimals);

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        webAddress = "https://www.hellotig.com";
    }

    function totalSupply() public pure returns (uint) {
        return _totalSupply;
    }

    // Get the token balance for account { tokenOwner }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    // Transfer the balance from owner's account to another account
    function transfer(address to, uint tokens) public returns (bool success) {
        require( balances[msg.sender] >= tokens && tokens > 0 );
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // Send {tokens} amount of tokens from address {from} to address {to}
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require( allowed[from][msg.sender] >= tokens && balances[from] >= tokens && tokens > 0 );
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

    // Allow {spender} to withdraw from your account, multiple times, up to the {tokens} amount.
    function approve(address sender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][sender] = tokens;
        emit Approval(msg.sender, sender, tokens);
        return true;
    }

    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _to, uint256 _amount);
}