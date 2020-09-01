pragma solidity ^0.4.25;
 
/*
* An ERC 20 Utility Token with an Inbuilt Exchange within the Smart Contract
* Ace Tokens (ACE) by AceWins.io                                                                                                                    
* 1% Affiliate Commission
* Website: https://www.acetokens.io
* Casino Website: https://www.acewins.io
*/


contract Ownable {
    
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}


contract AceTokens is Ownable{
    using SafeMath for uint256;
    
     modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }
            
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy,
        uint timestamp,
        uint256 price
);

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned,
        uint timestamp,
        uint256 price
);
    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
);

    string public name = "Ace Tokens";
    string public symbol = "ACE";
    uint8 constant public decimals = 18;
    uint8 constant internal refferalFee_ = 1;
    uint8 constant internal AdmCh_ = 7; //It is actually 0.7%. This value will be divided by 10 and used. Since we cannot use a decimal here, a round number is used.
    uint256 constant internal tokenPriceInitial_ = 0.00000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.000000001 ether;
    uint256 public stakingRequirement = 10e18;
    uint256 public launchtime = 1582205400;
  
    
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_;
    address adm = 0xA4d05a1c22C8Abe6CCB2333C092EC80bd0955031;
    

        function buy(address _referredBy) public payable returns (uint256) {
        require(now >= launchtime);
        uint256 AdmFee = msg.value.div(100).mul(AdmCh_);
        uint256 ExFee = SafeMath.div(AdmFee, 10);  
        adm.transfer(ExFee);
        purchaseTokens(msg.value, _referredBy);
    }
    
        function() payable public {
        require(now >= launchtime);
        uint256 AdmFee = msg.value.div(100).mul(AdmCh_);
        uint256 ExFee = SafeMath.div(AdmFee, 10); 
        adm.transfer(ExFee);
        purchaseTokens(msg.value, 0x0);
    }
    
 function sell(uint256 _amountOfTokens) onlyBagholders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 AdmFee = SafeMath.div(SafeMath.mul(_ethereum, AdmCh_), 100);
        uint256 _admout = SafeMath.div(AdmFee, 10);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _admout);
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        _customerAddress.transfer(_taxedEthereum);
        adm.transfer(_admout); 
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum, now, buyPrice());
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders public returns (bool) {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        return true;
    }


    function totalEthereumBalance() public view returns (uint256) {
        return this.balance;
    }

    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }


    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }



    function sellPrice() public view returns (uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 AdmFee = SafeMath.div(SafeMath.mul(_ethereum, AdmCh_), 100);
            uint256 _admout = SafeMath.div(AdmFee, 10); 
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _admout);
            return _taxedEthereum;
        }
    }

    function buyPrice() public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 AdmFee = SafeMath.div(SafeMath.mul(_ethereum, AdmCh_), 100);
            uint256 _admout = SafeMath.div(AdmFee, 10); 
            uint256 _referralBonus = SafeMath.div(SafeMath.mul(_ethereum, refferalFee_), 100);
            uint256 _totalfees = SafeMath.add(_referralBonus, _admout);
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _totalfees);
            return _taxedEthereum;
        }
    }

    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256) {
        uint256 AdmFee = SafeMath.div(SafeMath.mul(_ethereumToSpend, AdmCh_), 100);
        uint256 _admfees = SafeMath.div(AdmFee, 10); 
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_ethereumToSpend, refferalFee_), 100);
        uint256 _totalfees = SafeMath.add(_referralBonus, _admfees);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _totalfees);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }

    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 AdmFee = SafeMath.div(SafeMath.mul(_ethereum, AdmCh_), 100);
        uint256 _admout = SafeMath.div(AdmFee, 10); 
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _admout);
        return _taxedEthereum;
    }

  function purchaseTokens(uint256 _incomingEthereum, address _referredBy) internal returns (uint256) {
        address _customerAddress = msg.sender;
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_incomingEthereum, refferalFee_), 100);
        uint256 AdmFee = SafeMath.div(SafeMath.mul(_incomingEthereum, AdmCh_), 100);
        uint256 _admfees = SafeMath.div(AdmFee, 10); 
        uint256 _totalfees = SafeMath.add(_referralBonus, _admfees);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _totalfees);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
       

        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

        if (
            _referredBy != 0x0000000000000000000000000000000000000000 &&
            _referredBy != _customerAddress &&
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {  
        
           _referredBy.transfer(_referralBonus);
           
        } else {
        
        adm.transfer(_referralBonus);
        
        }

        if (tokenSupply_ > 0) {
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            
        } else {
            tokenSupply_ = _amountOfTokens;
        }

        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy, now, buyPrice());

        return _amountOfTokens;
    }


    function ethereumToTokens_(uint256 _ethereum) internal view returns (uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
            (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                (_tokenPriceInitial ** 2)
                                +
                                (2 * (tokenPriceIncremental_ * 1e18) * (_ethereum * 1e18))
                                +
                                ((tokenPriceIncremental_ ** 2) * (tokenSupply_ ** 2))
                                +
                                (2 * tokenPriceIncremental_ * _tokenPriceInitial*tokenSupply_)
                            )
                        ), _tokenPriceInitial
                    )
                ) / (tokenPriceIncremental_)
            ) - (tokenSupply_);

        return _tokensReceived;
    }

    function tokensToEthereum_(uint256 _tokens) internal view returns (uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
            (
                SafeMath.sub(
                    (
                        (
                            (
                                tokenPriceInitial_ + (tokenPriceIncremental_ * (_tokenSupply / 1e18))
                            ) - tokenPriceIncremental_
                        ) * (tokens_ - 1e18)
                    ), (tokenPriceIncremental_ * ((tokens_ ** 2 - tokens_) / 1e18)) / 2
                )
                / 1e18);

        return _etherReceived;
    }

 
   function setLaunchTime(uint256 _LaunchTime) public {
      require(msg.sender==owner);
      launchtime = _LaunchTime;
    }

    function updateAdm(address _address)  {
       require(msg.sender==owner);
       adm = _address;
    }
    

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }


}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}