pragma solidity 0.6.1;
pragma experimental ABIEncoderV2;


interface IERC20 {
  function balanceOf(address) external view returns (uint256);
}


contract DepositChecker {
  IERC20 internal constant _SAI = IERC20(
    0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359 // mainnet
  );

  IERC20 internal constant _DAI = IERC20(
    0x6B175474E89094C44Da98b954EedeAC495271d0F // mainnet
  );

  IERC20 internal constant _USDC = IERC20(
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 // mainnet
  );
  
  IERC20 internal constant _CSAI = IERC20(
    0xF5DCe57282A584D2746FaF1593d3121Fcac444dC // mainnet
  );
  
  IERC20 internal constant _CDAI = IERC20(
    0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643 // mainnet
  );
  
  IERC20 internal constant _CUSDC = IERC20(
    0x39AA39c021dfbaE8faC545936693aC917d5E7563 // mainnet
  );
  
  struct BalanceByToken {
    uint256 saiBalance;
    uint256 daiBalance;
    uint256 usdcBalance;
    uint256 cSaiBalance;
    uint256 cDaiBalance;
    uint256 cUSDCBalance;
  }
  
  function balancesOf(
    address[] calldata accounts
  ) external view returns (
    BalanceByToken[] memory balances
  ) {
    balances = new BalanceByToken[](accounts.length);
    for (uint256 i = 0; i < accounts.length; i++) {
      address account = accounts[i];
      balances[i] = BalanceByToken({
        saiBalance: _SAI.balanceOf(account),
        daiBalance: _DAI.balanceOf(account),
        usdcBalance: _USDC.balanceOf(account),
        cSaiBalance: _CSAI.balanceOf(account),
        cDaiBalance: _CDAI.balanceOf(account),
        cUSDCBalance: _CUSDC.balanceOf(account)
      });
    }
  }
}