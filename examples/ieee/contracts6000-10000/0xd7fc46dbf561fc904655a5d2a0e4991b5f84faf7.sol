// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
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

interface Controller {
    function vaults(address) external view returns (address);
}

/*

 A strategy must implement the following calls;
 
 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()
 
 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller
 
*/

interface Yfii {
    function withdraw(uint) external;
    function getReward() external;
    function stake(uint) external;
    function balanceOf(address) external view returns (uint);
    function exit() external;
}

contract Balancer {
    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;
    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountOut, uint spotPriceAfter);
    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountIn, uint spotPriceAfter);
    function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut) external returns (uint poolAmountOut);
    function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut) external returns (uint tokenAmountOut);
}

interface yERC20 {
  function deposit(uint256 _amount) external;
  function withdraw(uint256 _amount) external;
}

interface ICurveFi {

  function get_virtual_price() external view returns (uint);
  function add_liquidity(
    uint256[4] calldata amounts,
    uint256 min_mint_amount
  ) external;
  function remove_liquidity_imbalance(
    uint256[4] calldata amounts,
    uint256 max_burn_amount
  ) external;
  function remove_liquidity(
    uint256 _amount,
    uint256[4] calldata amounts
  ) external;
  function exchange(
    int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
  ) external;
}

contract StrategyCurveYfii {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    address constant public want = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address constant public yusdc = address(0xd6aD7a6750A7593E092a9B218d66C0A814a3436e);
    address constant public ycrv = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
    address constant public pool = address(0xb81D3cB2708530ea990a287142b82D058725C092);
    address constant public yfii = address(0xa1d0E215a23d7030842FC67cE582a6aFa3CCaB83);
    address constant public balancer = address(0x16cAC1403377978644e78769Daa49d8f6B6CF565);
    address constant public curve = address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    
    address constant public dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address constant public ydai = address(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01);

    address constant public usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address constant public yusdt = address(0x83f798e925BcD4017Eb265844FDDAbb448f1707D);

    address constant public tusd = address(0x0000000000085d4780B73119b644AE5ecd22b376);
    address constant public ytusd = address(0x73a052500105205d34Daf004eAb301916DA8190f);

    address public governance;
    address public controller;
    
    constructor(address _controller) public {
        governance = msg.sender;
        controller = _controller;
    }
    
    function deposit() external {
        IERC20(want).safeApprove(yusdc, 0);
        IERC20(want).safeApprove(yusdc, IERC20(want).balanceOf(address(this)));
        yERC20(yusdc).deposit(IERC20(want).balanceOf(address(this)));
        IERC20(yusdc).safeApprove(curve, 0);
        IERC20(yusdc).safeApprove(curve, IERC20(yusdc).balanceOf(address(this)));
        ICurveFi(curve).add_liquidity([0,IERC20(yusdc).balanceOf(address(this)),0,0],0);
        IERC20(ycrv).safeApprove(pool, 0);
        IERC20(ycrv).safeApprove(pool, IERC20(ycrv).balanceOf(address(this)));
        Yfii(pool).stake(IERC20(ycrv).balanceOf(address(this)));
    }
    
    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }
    
    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint _amount) external {
        require(msg.sender == controller, "!controller");
        uint _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        /*
        address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, _amount);
        */
        IERC20(want).safeTransfer(controller, _amount);
    }
    
    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();
        balance = IERC20(want).balanceOf(address(this));
        /*
        address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, balance);
        */
        IERC20(want).safeTransfer(controller, balance);
    }
    
    function _withdrawAll() internal {
        harvest();
        Yfii(pool).exit();
        withdrawUSDC(IERC20(ycrv).balanceOf(address(this)));
    }
    
    function harvest() public {
        Yfii(pool).getReward();
        IERC20(yfii).safeApprove(balancer, 0);
        IERC20(yfii).safeApprove(balancer, IERC20(yfii).balanceOf(address(this)));
        Balancer(balancer).swapExactAmountIn(yfii, IERC20(yfii).balanceOf(address(this)), dai, 0, uint(-1));
        IERC20(dai).safeApprove(ydai, 0);
        IERC20(dai).safeApprove(ydai, IERC20(dai).balanceOf(address(this)));
        yERC20(ydai).deposit(IERC20(dai).balanceOf(address(this)));
        IERC20(ydai).safeApprove(curve, 0);
        IERC20(ydai).safeApprove(curve, IERC20(ydai).balanceOf(address(this)));
        ICurveFi(curve).add_liquidity([IERC20(ydai).balanceOf(address(this)),0,0,0],0);
        IERC20(ycrv).safeApprove(pool, 0);
        IERC20(ycrv).safeApprove(pool, IERC20(ycrv).balanceOf(address(this)));
        Yfii(pool).stake(IERC20(ycrv).balanceOf(address(this)));
    }
    
    function withdrawUSDC(uint _amount) internal returns (uint) {
        IERC20(ycrv).safeApprove(curve, 0);
        IERC20(ycrv).safeApprove(curve, _amount);
        ICurveFi(curve).remove_liquidity(_amount, [uint256(0),0,0,0]);
        
        uint256 _ydai = IERC20(ydai).balanceOf(address(this));
        uint256 _yusdt = IERC20(yusdt).balanceOf(address(this));
        uint256 _ytusd = IERC20(ytusd).balanceOf(address(this));
        
        if (_ydai > 0) {
            IERC20(ydai).safeApprove(curve, 0);
            IERC20(ydai).safeApprove(curve, _ydai);
            ICurveFi(curve).exchange(0, 1, _ydai, 0);
        }
        if (_yusdt > 0) {
            IERC20(yusdt).safeApprove(curve, 0);
            IERC20(yusdt).safeApprove(curve, _yusdt);
            ICurveFi(curve).exchange(2, 1, _yusdt, 0);
        }
        if (_ytusd > 0) {
            IERC20(ytusd).safeApprove(curve, 0);
            IERC20(ytusd).safeApprove(curve, _ytusd);
            ICurveFi(curve).exchange(3, 1, _ytusd, 0);
        }
        uint _before = IERC20(want).balanceOf(address(this));
        yERC20(yusdc).withdraw(IERC20(yusdc).balanceOf(address(this)));
        uint _after = IERC20(want).balanceOf(address(this));
        return _after.sub(_before);
    }
    
    function normalize(uint _amount, address _from) public view returns (uint) {
        return _amount.mul(10**IERC20(want).decimals()).div(10**IERC20(_from).decimals());
    }
    
    function _withdrawSome(uint256 _amount) internal returns (uint) {
        uint _ycrv = _amount.mul(1e12).mul(1e18).div(ICurveFi(curve).get_virtual_price());
        Yfii(pool).withdraw(_ycrv);
        uint _withdraw = withdrawUSDC(_ycrv);
        if (_withdraw > _amount) {
            _withdraw = _amount;
        }
        return _withdraw;
    }
    
    function balanceOfCurve() public view returns (uint) {
        return normalize(IERC20(ycrv).balanceOf(address(this)).mul(ICurveFi(curve).get_virtual_price()).div(1e18), ycrv);
    }
    
    function balanceOfYfii() public view returns (uint) {
        return normalize(Yfii(pool).balanceOf(address(this)).mul(ICurveFi(curve).get_virtual_price()).div(1e18), ycrv);
    }
    
    function balanceOf() public view returns (uint) {
        return IERC20(want).balanceOf(address(this))
                .add(balanceOfCurve())
                .add(balanceOfYfii());
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }
}