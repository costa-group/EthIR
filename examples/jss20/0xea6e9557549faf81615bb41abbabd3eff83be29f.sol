pragma solidity 0.5.11;


interface CTokenInterface {
  function balanceOf(address) external view returns (uint256);
  function approve(address, uint256) external returns (bool);
  function transfer(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function exchangeRateStored() external view returns (uint256);
}


interface DTokenInterface {
  function mintViaCToken(uint256 cTokensToSupply) external returns (uint256 dTokensMinted);
  function redeemToCToken(uint256 dTokensToBurn) external returns (uint256 cTokensReceived);
  function balanceOf(address) external view returns (uint256);
  function approve(address, uint256) external returns (bool);
  function transfer(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
}


interface CurveInterface {
  function exchange(int128, int128, uint256, uint256, uint256) external;
  function get_dy(int128, int128, uint256) external view returns (uint256);
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "SafeMath: subtraction overflow");
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) return 0;
        c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "SafeMath: division by zero");
        c = a / b;
    }
}


contract CurveTradeHelperV0 {
  using SafeMath for uint256;

  CTokenInterface internal constant _CDAI = CTokenInterface(
    0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643
  );
  
  CTokenInterface internal constant _CUSDC = CTokenInterface(
    0x39AA39c021dfbaE8faC545936693aC917d5E7563
  );
 
  DTokenInterface internal constant _DDAI = DTokenInterface(
    0x00000000001876eB1444c986fD502e618c587430
  );
  
  DTokenInterface internal constant _DUSDC = DTokenInterface(
    0x00000000008943c65cAf789FFFCF953bE156f6f8
  );
  
  CurveInterface internal constant _CURVE = CurveInterface(
    0x2e60CF74d81ac34eB21eEff58Db4D385920ef419
  );
  
  uint256 internal constant _SCALING_FACTOR = 1e18;
  
  constructor() public {
    require(_CUSDC.approve(address(_CURVE), uint256(-1)));
  }
  
  function tradeCUSDCForCDai(uint256 quotedExchangeRate) external {
    // Get the total cUSDC balance of the caller.
    uint256 cUSDCBalance = _CUSDC.balanceOf(msg.sender);
    
    // Use that balance and quoted exchange rate to derive required cDai.
    uint256 minimumCDai = _getMinimumCDai(cUSDCBalance, quotedExchangeRate);
    
    // Transfer all cUSDC from the caller to this contract (requires approval).
    require(_CUSDC.transferFrom(msg.sender, address(this), cUSDCBalance));
    
    // Exchange cUSDC for cDai using Curve.
    _CURVE.exchange(1, 0, cUSDCBalance, minimumCDai, now + 1);
    
    // Get the received cDai and ensure it meets the requirement.
    uint256 cDaiBalance = _CDAI.balanceOf(address(this));
    require(
      cDaiBalance >= minimumCDai,
      "Realized exchange rate differs from quoted rate by over 1%."
    );
    
    // Transfer the cDai to the caller.
    require(_CDAI.transfer(msg.sender, cDaiBalance));
  }

  function tradeCUSDCForCDaiAtAnyRate() external {
    // Get the total cUSDC balance of the caller.
    uint256 cUSDCBalance = _CUSDC.balanceOf(msg.sender);
    
    // Transfer all cUSDC from the caller to this contract (requires approval).
    require(_CUSDC.transferFrom(msg.sender, address(this), cUSDCBalance));
    
    // Exchange cUSDC for any amount of cDai using Curve.
    _CURVE.exchange(1, 0, cUSDCBalance, 0, now + 1);
    
    // Get the received cDai and transfer it to the caller.
    require(_CDAI.transfer(msg.sender, _CDAI.balanceOf(address(this))));
  }
  
  function tradeDUSDCForDDai(uint256 quotedExchangeRate) external {
    // Get the total dUSDC balance of the caller.
    uint256 dUSDCBalance = _DUSDC.balanceOf(msg.sender);
    
    // Transfer all dUSDC from the caller to this contract (requires approval).
    require(_DUSDC.transferFrom(msg.sender, address(this), dUSDCBalance));

    // Redeem dUSDC for cUSDC.
    uint256 cUSDCBalance = _DUSDC.redeemToCToken(dUSDCBalance);
    
    // Use cUSDC balance and quoted exchange rate to derive required cDai.
    uint256 minimumCDai = _getMinimumCDai(cUSDCBalance, quotedExchangeRate);
    
    // Exchange cUSDC for cDai using Curve.
    _CURVE.exchange(1, 0, cUSDCBalance, minimumCDai, now + 1);
    
    // Get the received cDai and ensure it meets the requirement.
    uint256 cDaiBalance = _CDAI.balanceOf(address(this));
    require(
      cDaiBalance >= minimumCDai,
      "Realized exchange rate differs from quoted rate by over 1%."
    );
    
    // Mint dDai using the received cDai.
    uint256 dDaiBalance = _DUSDC.mintViaCToken(_CDAI.balanceOf(address(this)));
    
    // Transfer the received dDai to the caller.
    require(_DDAI.transfer(msg.sender, dDaiBalance));
  }

  function tradeDUSDCForDDaiAtAnyRate() external {
    // Get the total dUSDC balance of the caller.
    uint256 dUSDCBalance = _DUSDC.balanceOf(msg.sender);
    
    // Transfer all dUSDC from the caller to this contract (requires approval).
    require(_DUSDC.transferFrom(msg.sender, address(this), dUSDCBalance));
    
    // Redeem dUSDC for cUSDC.
    uint256 cUSDCBalance = _DUSDC.redeemToCToken(dUSDCBalance);
    
    // Exchange cUSDC for any amount of cDai using Curve.
    _CURVE.exchange(1, 0, cUSDCBalance, 0, now + 1);
    
    // Mint dDai using the received cDai.
    uint256 dDaiBalance = _DUSDC.mintViaCToken(_CDAI.balanceOf(address(this)));
    
    // Transfer the received dDai to the caller.
    require(_DDAI.transfer(msg.sender, dDaiBalance));
  }

  function getExchangeRateAndExpectedDai(uint256 usdc) internal view returns (
    uint256 exchangeRate,
    uint256 dai
  ) {
    uint256 cUSDCEquivalent = (
      usdc.mul(_SCALING_FACTOR)
    ).div(_CUSDC.exchangeRateStored());
    
    uint256 cDaiEquivalent;
    (exchangeRate, cDaiEquivalent) = _getExchangeRateAndExpectedCDai(
      cUSDCEquivalent
    );
    
    dai = (
      cDaiEquivalent.mul(_CDAI.exchangeRateStored())
    ).div(_SCALING_FACTOR);
  }

  function _getExchangeRateAndExpectedCDai(uint256 cUSDC) internal view returns (
    uint256 exchangeRate,
    uint256 cDai
) {
    cDai = _CURVE.get_dy(1, 0, cUSDC);
    exchangeRate = (cUSDC.mul(_SCALING_FACTOR)).div(cDai);
  }

  function _getMinimumCDai(uint256 cUSDC, uint256 quotedExchangeRate) internal pure returns (
    uint256 minimumCDai
) {
    uint256 quotedCDai = (cUSDC.mul(quotedExchangeRate)).div(_SCALING_FACTOR);
    minimumCDai = (quotedCDai.mul(99)).div(100);
  }
}