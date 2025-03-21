/*

AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO
                                                                                  
                                                                                  
               AAA               IIIIIIIIIIRRRRRRRRRRRRRRRRR        OOOOOOOOO     
              A:::A              I::::::::IR::::::::::::::::R     OO:::::::::OO   
             A:::::A             I::::::::IR::::::RRRRRR:::::R  OO:::::::::::::OO 
            A:::::::A            II::::::IIRR:::::R     R:::::RO:::::::OOO:::::::O
           A:::::::::A             I::::I    R::::R     R:::::RO::::::O   O::::::O
          A:::::A:::::A            I::::I    R::::R     R:::::RO:::::O     O:::::O
         A:::::A A:::::A           I::::I    R::::RRRRRR:::::R O:::::O     O:::::O
        A:::::A   A:::::A          I::::I    R:::::::::::::RR  O:::::O     O:::::O
       A:::::A     A:::::A         I::::I    R::::RRRRRR:::::R O:::::O     O:::::O
      A:::::AAAAAAAAA:::::A        I::::I    R::::R     R:::::RO:::::O     O:::::O
     A:::::::::::::::::::::A       I::::I    R::::R     R:::::RO:::::O     O:::::O
    A:::::AAAAAAAAAAAAA:::::A      I::::I    R::::R     R:::::RO::::::O   O::::::O
   A:::::A             A:::::A   II::::::IIRR:::::R     R:::::RO:::::::OOO:::::::O
  A:::::A               A:::::A  I::::::::IR::::::R     R:::::R OO:::::::::::::OO 
 A:::::A                 A:::::A I::::::::IR::::::R     R:::::R   OO:::::::::OO   
AAAAAAA                   AAAAAAAIIIIIIIIIIRRRRRRRR     RRRRRRR     OOOOOOOOO     


AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO  AIRO     

            ______
            _\ _~-\___
    =  = ==(____AA____D
                \_____\___________________,-~~~~~~~`-.._
                /     o O o o o o O O o o o o o o O o  |\_
                `~-.__        ___..----..                  )
                      `---~~\___________/------------`````
                      =  ===(_________D
                                                                            

(AIRO) 

Where Crypto Takes Flight


Website:   https://airocoin.tech

Telegram:  https://t.me/airocointech

Twitter:   https://twitter.com/CoinAiro

Discord:   https://discord.gg/BMGa6yg


AIRO token sale begins August 13, 2020

AIRO Uniswap Listing August 16, 2020

AIRO token sale price is 0.0001 ETH
(50% discount from upcoming Uniswap listing)




*/
pragma solidity ^0.5.16;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function addBalance(address account, uint amount) internal {
        require(account != address(0), "ERC20: add to the zero address");

        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), account, amount);
    }



    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract AIRO is ERC20, ERC20Detailed {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint;
  uint256 public tokenSalePrice = 0.0001 ether;
  uint public saleTokens = 3000000e18;  //change to 3000000e18
  bool public _tokenSaleMode = true;
  uint256 public unlockTime;
  address public admin;
  uint256 public liquidityTokens = 0;
  bool public teamUnlocked = false;
  bool public liquidityTokensAdded = false;
  
 
  constructor () public ERC20Detailed("AIROCoin.tech", "AIRO", 18) {
      admin = msg.sender;
      unlockTime = now + 180*86400; //lock team tokens for 6 months
  }

   function burn(uint256 amount) public {
      _burn(msg.sender, amount);
  }
  
  function buyToken() public payable {
      require(_tokenSaleMode, "token sale is over");
      require(msg.value >= 0.25 ether, "minimum purchase 0.25 ETH");
      uint256 newTokens = SafeMath.mul(SafeMath.div(msg.value, tokenSalePrice),1e18);
      addBalance(msg.sender, newTokens);
      saleTokens = saleTokens.sub(newTokens);
      liquidityTokens = liquidityTokens.add(newTokens);
  }

   function unlockTeamTokens() public payable {    // team tokens are locked for 6 months
      require(msg.sender == admin, "!not allowed");
      require(now > unlockTime, "!too early");   
      require(!teamUnlocked, "!already unlocked");  
      teamUnlocked = true;
      uint256 newTokens = 500000e18;  // 500,000 team tokens
      addBalance(msg.sender, newTokens);
      
  }

  function() external payable {
      buyToken();
  }

  function getLiquidityTokens() public {
      require(msg.sender == admin, "!not allowed");
      require(!liquidityTokensAdded, "!already added");
      liquidityTokensAdded = true;
      addBalance(msg.sender, liquidityTokens);
  } 


  function endTokenSale() public {
      require(msg.sender == admin, "!not allowed");
      _tokenSaleMode = false;
  }

   function withdraw() external {
      require(msg.sender == admin, "!not allowed");
      msg.sender.transfer(address(this).balance);
  }

}