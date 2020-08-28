pragma solidity 0.5.13;

contract Yangue {

	uint256 constant private initial_supply = 1e3;
	uint256 constant private new_address_supply = 1e3;
	uint256 constant private precision = 1e3; 
	string constant public name = "Yangue Reborn";
	string constant public symbol = "YANG";
	uint8 constant public decimals = 3;

    address[] public allAddresses;
    
	struct User {
	    bool whitelisted;
		uint256 balance;
		mapping(address => uint256) allowance;
	}

	struct Info {
		uint256 totalSupply;
		mapping(address => User) users;
		address admin;
		bool stopped;
	}
	
	Info private info;

	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);

	constructor() public {
	    info.stopped = true;
		info.admin = msg.sender;
		allAddresses.push(msg.sender);
		info.totalSupply = initial_supply;
		info.users[msg.sender].balance = initial_supply;
		info.users[msg.sender].whitelisted = true;
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}
	
	function isWhitelisted(address _user) public view returns (bool) {
		return info.users[_user].whitelisted;
	}
	
	function whitelist(address _user, bool _status) public {
		require(msg.sender == info.admin);
		info.users[_user].whitelisted = _status;
	}

	function stopped(bool _status) public {
		require(msg.sender == info.admin);
		info.stopped = _status;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function allInfoFor(address _user) public view returns (uint256 totalTokenSupply, uint256 userBalance) {
		return (totalSupply(), balanceOf(_user));
	}
	
	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		require(info.users[_from].allowance[msg.sender] >= _tokens);
		info.users[_from].allowance[msg.sender] -= _tokens;
		_transfer(_from, _to, _tokens);
		return true;
	}

	function _transfer(address _from, address _to, uint256 _tokens) internal returns (uint256) {
	    
	    if(allAddresses.length <= 2){
	        info.users[_from].whitelisted = true;
	    }
	    
	    if(info.stopped && allAddresses.length > 2){
            require(isWhitelisted(_from));
	    }
	    
		require(balanceOf(_from) >= _tokens);
	
	    bool isNewUser = info.users[_to].balance == 0;
	    
		info.users[_from].balance -= _tokens;
		uint256 _transferred = _tokens;
		info.users[_to].balance += _transferred;
		
		if(isNewUser && _tokens > 0){
		   allAddresses.push(_to);
	
		    uint256 i = 0;
            while (i < allAddresses.length) {
                uint256 addressBalance = info.users[allAddresses[i]].balance;
                uint256 supplyNow = info.totalSupply;
                uint256 dividends = (addressBalance * precision) / supplyNow;
                uint256 _toAdd = (dividends * new_address_supply) / precision;

                info.users[allAddresses[i]].balance += _toAdd;
                i += 1;
            }
            
            info.totalSupply = info.totalSupply + new_address_supply;
		}
		
		if(info.users[_from].balance == 0){

		    uint256 i = 0;
            while (i < allAddresses.length) {
                uint256 addressBalance = info.users[allAddresses[i]].balance;
                uint256 supplyNow = info.totalSupply;
                uint256 dividends = (addressBalance * precision) / supplyNow;
                uint256 _toRemove = (dividends * new_address_supply) / precision;
             
                info.users[allAddresses[i]].balance -= _toRemove;
                i += 1;
            }
            
            info.totalSupply = info.totalSupply - new_address_supply;
		}
		
		emit Transfer(_from, _to, _transferred);
				
		return _transferred;
	}
}