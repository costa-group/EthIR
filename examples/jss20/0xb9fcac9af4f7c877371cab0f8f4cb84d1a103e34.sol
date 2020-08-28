pragma solidity ^0.5.12;

contract tokenInterface {
	function balanceOf(address _owner) public view returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool);
}

contract Timelock_Swap_Trustless {
	
	tokenInterface public tcj;
	tokenInterface public xra;
	uint256 public dataUnlock;
	address public addrCoinshare;
	address public addrXriba;

	constructor(address _tcj, address _xra, uint256 _dataUnlock, address _addrCoinshare, address _addrXriba) public {
		tcj = tokenInterface(_tcj);
		xra = tokenInterface(_xra);
		
		dataUnlock = _dataUnlock;
		
		addrCoinshare = _addrCoinshare;
		addrXriba = _addrXriba;
	}
	
	bool withdrawn;
	
	function enabled() public view returns(bool) {
	    bool xriba_paid = xra.balanceOf(address(this)) > 3333333 * 1e18;
	    bool coinshare_paid = tcj.balanceOf(address(this)) >= 8333333 * 1e18;
	    
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