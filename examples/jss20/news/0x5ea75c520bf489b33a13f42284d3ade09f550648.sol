pragma solidity ^0.5.12;

contract tokenInterface {
	function balanceOf(address _owner) public view returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool);
}

contract Timelock_Swap_Trustless {
	tokenInterface public tcj;
	tokenInterface public xra;
	uint256 public tcj_required;
	uint256 public xra_required;
	uint256 public dataUnlock;
	address public addrCoinshare;
	address public addrXriba;

	constructor(address _tcj, address _xra, uint256 _dataUnlock, address _addrCoinshare, address _addrXriba, uint256 _tcj_required, uint256 _xra_required) public {
		tcj = tokenInterface(_tcj);
		xra = tokenInterface(_xra);	
		tcj_required = _tcj_required;
		xra_required = _xra_required;
		dataUnlock = _dataUnlock;
		addrCoinshare = _addrCoinshare;
		addrXriba = _addrXriba;
	}
	
	bool withdrawn;
	function enabled() public view returns(bool) {
	    bool coinshare_paid = tcj.balanceOf(address(this)) >= tcj_required;
	    bool xriba_paid = xra.balanceOf(address(this)) >= xra_required;
	    
	    if(coinshare_paid && xriba_paid) {
	        return true;
	    } else if (withdrawn) {
	        return true;
	    } else {
	        return false;
	    }
	}
	
	function () external {
	    uint256 tcj_amount = tcj.balanceOf(address(this));
	    uint256 xra_amount = xra.balanceOf(address(this));
	    
	    if(enabled()) {
	        require(now>dataUnlock,"now>dataUnlock");
	        if(msg.sender == addrCoinshare) {
	            require(xra_amount > 0, "xra_amount > 0");
	            withdrawn = true;
	            xra.transfer(addrCoinshare, xra_amount);
	        } else if ( msg.sender == addrXriba ) {
	            require(tcj_amount > 0, "tcj_amount > 0");
	            withdrawn = true;
	            tcj.transfer(addrXriba, tcj_amount);
	        } else {
	            revert("No auth.");
	        }
	    } else {
	        if(msg.sender == addrCoinshare) {
	            require(tcj_amount > 0, "tcj_amount > 0");
	            tcj.transfer(addrCoinshare, tcj_amount);
	        } else if ( msg.sender == addrXriba ) {
	            require(xra_amount > 0, "xra_amount > 0");
	            xra.transfer(addrXriba, xra_amount);
	        } else {
	            revert("No auth.");
	        }
	    }
	}
}

contract XRA_TCJ_SWAP_TIMELOCK is Timelock_Swap_Trustless {
	constructor() public Timelock_Swap_Trustless(
	    0x44744e3e608D1243F55008b328fE1b09bd42E4Cc, 
	    0x7025baB2EC90410de37F488d1298204cd4D6b29d, 
	    1598911200, 
	    0xC9d32Ab70a7781a128692e9B4FecEBcA6C1Bcce4, 
	    0x98719cFC0AeE5De1fF30bB5f22Ae3c2Ce45e43F7, 
	    8333333000000000000000000,
	    3333333000000000000000000) {
	}
}