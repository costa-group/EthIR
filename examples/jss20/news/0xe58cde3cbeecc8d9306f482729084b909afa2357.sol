pragma solidity ^0.5.16;

contract Underwriter {
    using SafeMath for *;
    
    /**
     * @dev calculates number of shares received given X eth
     * @param _curEth current amount of eth in contract
     * @param _newEth eth being spent
     * @return amount of share purchased
     */
    function mintShare(uint256 _curEth, uint256 _newEth)
        external
        pure
        returns (uint256)
    {
        return(shares((_curEth).add(_newEth)).sub(shares(_curEth)));
    }

    /**
     * @dev calculates amount of eth received if you sold X shares
     * @param _curShares current amount of shares that exist
     * @param _sellShares amount of shares you wish to sell
     * @return amount of eth received
     */
    function burnShare(uint256 _curShares, uint256 _sellShares)
        external
        pure
        returns (uint256)
    {
        return((eth(_curShares)).sub(eth(_curShares.sub(_sellShares))));
    }

    /**
     * @dev calculates how many shares would exist with given an amount of eth
     * @param _eth eth in contract
     * @return number of shares that would exist
     */
    function shares(uint256 _eth)
        public
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }

    /**
     * @dev calculates how much eth would be in contract given a number of shares
     * @param _shares number of shares minted
     * @return eth that would exists
     */
    function eth(uint256 _shares)
        public
        pure
        returns(uint256)
    {
        return ((78125000).mul(_shares.sq()).add(((149999843750000).mul(_shares.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}
library SafeMath {

    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        if (a == 0) return 0;
        c = a * b;
        require(c / a == b);
    }

    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        require(b <= a);
        c = a - b;
    }

    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        c = a + b;
        require(c >= a);
    }

    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y)
    {
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
    }

    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }

    function pwr(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = 1;
        while(y != 0){
            if(y % 2 == 1)
                z = mul(z,x);
            x = sq(x);
            y = y / 2;
        }
        return z;
    }

}