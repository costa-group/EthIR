pragma solidity ^0.5.16;


interface ICEther {

    function mint() external payable;

    function redeem(uint redeemTokens) external returns (uint);

    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function repayBorrow(uint repayAmount) external returns (uint);

    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

    function transfer(address dst, uint amount) external returns (bool);

    function transferFrom(address src, address dst, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function balanceOfUnderlying(address owner) external returns (uint);

    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

    function borrowRatePerBlock() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function totalBorrowsCurrent() external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);

    function borrowBalanceStored(address account) external view returns (uint);

    function exchangeRateCurrent() external returns (uint);

    function exchangeRateStored() external view returns (uint);

    function getCash() external view returns (uint);

    function accrueInterest() external returns (uint);

    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);



    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function admin() external view returns (address);

    function pendingAdmin() external view returns (address);

    function reserveFactorMantissa() external view returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function totalSupply() external view returns (uint256);

}



// File: localhost/contracts/handlers/HandlerBase.sol



pragma solidity ^0.5.0;



contract HandlerBase {

    address[] public tokens;



    function _updateToken(address token) internal {

        tokens.push(token);

    }

}



// File: localhost/contracts/handlers/compound/HCEther.sol



pragma solidity ^0.5.0;







contract HCEther is HandlerBase {

    function getCEther() public pure returns (address result) {

        return 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    }



    function mint(uint256 value) external payable {

        ICEther compound = ICEther(getCEther());

        compound.mint.value(value)();



        // Update involved token

        _updateToken(getCEther());

    }

}