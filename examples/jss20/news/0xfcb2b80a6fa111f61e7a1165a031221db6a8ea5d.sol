/*

███████╗████████╗██╗   ██╗
██╔════╝╚══██╔══╝╚██╗ ██╔╝
█████╗     ██║    ╚████╔╝  
██╔══╝     ██║     ╚██╔╝    
███████╗   ██║      ██║   
╚══════╝   ╚═╝      ╚═╝ 
           ETHERLLY.COM

@title Etherlly (dApp)
@author Etherlly.com
 www.etherlly.com
 sysman@etherlly.com


        This contract is simple and complete, able to produce exactly the proposed without any obscure code.
        The easiest, safest and fastest way to make money in crypto industry.
        

 Version 0.1v (15-12-2019)
*/


pragma solidity ^0.5.13;

/**
 * @notice Library of mathematical calculations for uit256
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

/**
 * @notice Internal access and control system
 */
contract SysCtrl {
  address public sysman;
  address public sysWallet;
  constructor() public {
    sysman = msg.sender;
    sysWallet = 0x000f0e207c8F400C78bFc584baEb6Ce22eE5705D; // Address for Maintenance of service (UI Website, ADS and others)
  }
  modifier onlySysman() {
    require(msg.sender == sysman, "Only for System Maintenance");
    _;
  }
  function setSysman(address _newSysman) public onlySysman {
    sysman = _newSysman;
  }
  function setWallet(address _newWallet) public onlySysman {
      sysWallet = _newWallet;
  }
}

/**
 * @notice Standard Token ERC20
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md for more details
 * Token to be used for future expansion, will soon be negotiated
 */
contract ETYToken is SysCtrl {
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Public variables of the token */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() public {
        uint256 initialSupply = 10000000000000;
        string memory tokenName = "Etherlly.com";
        uint8 decimalUnits = 2;
        string memory tokenSymbol = "ETY";
        balanceOf[sysWallet] = initialSupply;               // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

   /** 
    * @notice Send `_value` tokens to `_to` from your account
    * @param _to The address of the recipient
    * @param _value the amount to send
    */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0x0),"Prevent transfer to 0x0 address");
        require (balanceOf[_from] >= _value,"Insufficient balance");
        require (balanceOf[_to] + _value > balanceOf[_to],"overflows");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
  /* ETY ADS on Ethereum network
   * Distribution of ETY as ADS
   */ 
    function disETY(address[] memory  _bens, uint256 amount) public onlySysman {
        for (uint256 i = 0; i < _bens.length; i++){ 
            _transfer(sysWallet, _bens[i], amount); 
        }
    }
}

contract Etherlly is ETYToken {
    // Using SafeMath for uint256;
    // Events
    event addUser(address indexed user, bytes manifest, bytes32 label,
                  address indexed level4);
    event chain(address user, address indexed level1, address indexed level2, address indexed level3);

    // Public variables of the Etherlly contract
    uint public TICKET_PRICE = 0.05 ether;           //  This value is set to plus 0.01 ETH per 500 transactions.
    uint public nextChainID = 1;
    uint public count = 0;

    struct ChainStruct {
        uint id;
        bytes32 label;
        address level1;
        address level2;
        address level3;
        address level4;
        uint256 profit;
    }
    mapping (address => ChainStruct) public chains;
    mapping (uint => address) public chainsList;
    mapping (bytes32 => address) public chainsLabel;

    // Start Contract
    constructor() public {
        ChainStruct memory chainStruct;
        chainStruct = ChainStruct({
            id: nextChainID,
            label: '1st Chain',
            level1: sysWallet,
            level2: sysWallet,
            level3: sysWallet,
            level4: sysWallet,
            profit: 0
        });
        chains[sysWallet] = chainStruct;
        chainsList[nextChainID] = sysWallet;
        chainsLabel[''] = sysWallet;
        nextChainID++;
    }

   /**
     * @notice Signup without UI
     * note. Transfer the ticket price amount for this contract and sign up automatically, 
     * if no reference is provided, one will be indicated among the active members
     */
    function () external payable {
        address ref;
        if(msg.data.length > 0){                                        // Check if there is a reference, or select one randomly
            ref = b2A(msg.data);
        }else{
            ref = chainsList[random(nextChainID-1)];
        }

        bytes32 label = '';
        bytes memory manifest = '';
        signEtherlly(ref,label,manifest);
    }

  /**
    * @notice Sign up Etherlly (UI)
    * @param _ref referral member
    * @param _label label name up to 32 characteres
    * @param _manifest IPFS hash with Etherlly manifest (see in etherlly.com an example of json file)
    */
    function signEtherlly(address _ref, bytes32 _label, bytes memory _manifest) public payable {
        if(chains[_ref].id <= 0) {                                      // Check if Refer exist
            revert('Refer user not found in Etherlly (dApp)');
        }
        if(chains[msg.sender].id > 0) {                      // User already exists in the Etherlly
            revert('Address already exists in the Etherlly (dApp)');
        }
        if(_label != ''){                                               // Check if label exist, can be empty, but not repeated
            if(chainsLabel[_label] > address(0x0)){
                revert('Label Tag already exists in the Etherlly (dApp)');
            }
        }
        if(msg.value < TICKET_PRICE){                                   // Min value to sign in Etherlly contract
            revert('Lower minimum value to sign in Etherlly (dApp)');
        }
        
        ChainStruct memory chainStruct;                                 // Create a new structure of the chain
        chainStruct = ChainStruct({
            id : nextChainID,
            label: _label,
            level1: chains[_ref].level2,
            level2: chains[_ref].level3,
            level3: chains[_ref].level4,
            level4: _ref,
            profit: 0
        });
        chains[msg.sender] = chainStruct;
        chainsList[nextChainID] = msg.sender;
        chainsLabel[_label] = msg.sender;
        nextChainID++;
        count++;
        
        emit addUser(                                                   // Create a LOG with IPFS Hash Manifest
            msg.sender,
            _manifest,
            _label,
            chains[msg.sender].level4
        );
        
        emit chain( 
            msg.sender,                                                
            chains[msg.sender].level1,
            chains[msg.sender].level2,
            chains[msg.sender].level3
        );
        
        payCommission(_ref);                                              // Make a paymet of referral commission
        adjust();                                                         // Check ticket price
    }
    
    /**
     * @notice Pay commission in Etherlly DApp
     * @param _ref User referral
     */
    function payCommission(address _ref) internal {
         uint pay_ref_ETY = 100000;                                          // 1000 ETY for reference (Level 4)
         uint pay_50 = SafeMath.mul(SafeMath.div(TICKET_PRICE,100),50);      // Level 1 in chain get 50% of ticket
         uint pay_20 = SafeMath.mul(SafeMath.div(TICKET_PRICE,100),20);      // Level 4 reference get 20% of ticket
         uint pay_10 = SafeMath.mul(SafeMath.div(TICKET_PRICE,100),10);      // Level2 and Level 3 get 10% of ticket
         
         address(uint160(chains[msg.sender].level1)).transfer(pay_50);        
         chains[chains[msg.sender].level1].profit = SafeMath.add(chains[chains[msg.sender].level1].profit,pay_50);
            
         address(uint160(chains[msg.sender].level2)).transfer(pay_10);        
         chains[chains[msg.sender].level2].profit = SafeMath.add(chains[chains[msg.sender].level2].profit,pay_10);
         
         address(uint160(chains[msg.sender].level3)).transfer(pay_10);        
         chains[chains[msg.sender].level3].profit = SafeMath.add(chains[chains[msg.sender].level3].profit,pay_10);



         address(uint160(_ref)).transfer(pay_20);                         
         chains[_ref].profit = SafeMath.add(chains[_ref].profit,pay_20);

         _transfer(sysWallet, _ref, pay_ref_ETY);                           // Payment in ETY for referral  
                                                                            // Token to be used for future expansion, 
                                                                            // will soon be negotiated

         address(uint160(sysWallet)).transfer(address(this).balance);       // Remaining 10% for maintenance and ADS

    }
    
    /**
     * @notice Ticket Adjust
     * note. The ticket price is adjusted +0.01 ETH per 500 transactions 
     */
    function adjust() internal {
        if(count >= 500) {
           TICKET_PRICE = SafeMath.add(TICKET_PRICE,0.01 ether);
           count = 1;
        }
    }

   /**
    * @notice Bytes to anddress
    * @param _inBytes bytes to convert in Ethereum address
    */
    function b2A(bytes memory _inBytes) private pure returns (address outAddress) {
        assembly{
            outAddress := mload(add(_inBytes, 20))
        }
    }

   /**
    * @notice Generate random number 0 to maxnumber
    * @param _maxNumber Max Number to generate
    */
    function random(uint _maxNumber) private view returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, count))) % _maxNumber;
        if(randomnumber == 0){
            randomnumber = 1;
        }
        return randomnumber;
    }

}