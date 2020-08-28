pragma solidity ^0.5.15;

// https://github.com/makerdao/dss/blob/master/src/jug.sol
contract JugAbstract {
    function drip(bytes32) external returns (uint256);
}

// https://github.com/makerdao/dss/blob/master/src/pot.sol
contract PotAbstract {
    function drip() external returns (uint256);
    function dsr() public view returns (uint256);
    function chi() public view returns (uint256);
    function rho() public view returns (uint256);
}

// https://github.com/makerdao/dss/blob/master/src/vat.sol
contract VatAbstract {
    function dai(address) public view returns (uint256);
    function sin(address) public view returns (uint256);
}

// https://github.com/makerdao/dss/blob/master/src/vow.sol
contract VowAbstract {
    function sin(uint256) public view returns (uint256);
    function Sin() public view returns (uint256);
    function Ash() public view returns (uint256);
    function bump() public view returns (uint256);
    function hump() public view returns (uint256);
    function flap() external returns (uint256);
    function heal(uint256) external;
}

// https://github.com/makerdao/sai/blob/master/src/pit.sol
contract GemPitAbstract {
    function burn(address) public;
}

// https://github.com/dapphub/ds-token/blob/master/src/token.sol
contract DSTokenAbstract {
    function balanceOf(address) external view returns (uint256);
}

// https://github.com/makerdao/dss/blob/master/src/pot.sol
contract PotHelper {

    PotAbstract pa;

    constructor(address pot) public {
        pa = PotAbstract(pot);
    }

    // https://github.com/makerdao/dss/blob/master/src/pot.sol#L79
    uint256 constant ONE = 10 ** 27;

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, y) / ONE;
    }

    function rpow(uint x, uint n, uint base) internal pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }

    // View function for calculating value of chi iff drip() is called in the same block.
    function drop() external view returns (uint256) {
        if (now == pa.rho()) return pa.chi();
        return rmul(rpow(pa.dsr(), now - pa.rho(), ONE), pa.chi());
    }

    // Pass the Pot Abstract for additional operations
    function pot() external view returns (PotAbstract) {
        return pa;
    }
}

// ༼つಠ益ಠ༽つ ─=≡Σ◈)) HADAIKEN
//
// Optimized contract for performing some or all of the functions that
//   keep Multi-Collateral Dai running.
contract Hadaiken {

    address constant internal PIT = address(0x69076e44a9C70a67D5b79d95795Aba299083c275);
    address constant internal MKR = address(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    address constant internal JUG = address(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    address constant internal POT = address(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    address constant internal VAT = address(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    address constant internal VOW = address(0xA950524441892A31ebddF91d3cEEFa04Bf454466);

    GemPitAbstract  constant internal pit  = GemPitAbstract(PIT);
    DSTokenAbstract constant internal gem  = DSTokenAbstract(MKR);
    JugAbstract     constant internal jug  = JugAbstract(JUG);
    PotAbstract     constant internal pot  = PotAbstract(POT);
    VowAbstract     constant internal vow  = VowAbstract(VOW);
    VatAbstract     constant internal vat  = VatAbstract(VAT);
    PotHelper                internal poth;

    bytes32 constant internal ETH_A = bytes32("ETH-A");
    bytes32 constant internal BAT_A = bytes32("BAT-A");
    bytes32 constant internal USDC_A = bytes32("USDC-A");

    constructor() public {
        poth = new PotHelper(POT);
    }

    // Raw System Debt
    function _rawSysDebt() internal view returns (uint256) {
        return (vat.sin(VOW) - vow.Sin() - vow.Ash());
    }

    function rawSysDebt() external view returns (uint256) {
        return _rawSysDebt();
    }

    function _sysSurplusThreshold() internal view returns (uint256) {
        return (vat.sin(VOW) + vow.bump() + vow.hump());
    }

    function  sysSurplusThreshold() external view returns (uint256) {
        return _sysSurplusThreshold();
    }

    // Saves you money.
    function heal() external {
        _heal();
    }

    // Returns the amount of debt healed if you're curious about that sort of thing.
    function healStat() external returns (uint256 sd) {
        sd = _rawSysDebt();
        _heal();
    }

    // No return here. I want to save gas and who cares.
    function _heal() internal {
        vow.heal(_rawSysDebt());
    }

    // Return the new chi value after drip.
    function drip() external returns (uint256 chi) {
        chi = pot.drip();
        _dripIlks();
    }

    // Returns a simulated chi value
    function drop() external view returns (uint256) {
        return poth.drop();
    }

    function _dripPot() internal {
        pot.drip();
    }

    function dripIlks() external {
        _dripIlks();
    }

    function _dripIlks() internal {
        jug.drip(ETH_A);
        jug.drip(BAT_A);
        jug.drip(USDC_A);
    }

    function kickable() external view returns (bool) {
        return _kickable();
    }

    // Can we bump an auction?
    function _kickable() internal view returns (bool) {
        // Assume heal is called prior to kick.
        // require(vat.dai(address(this)) >= add(add(vat.sin(address(this)), bump), hump), "Vow/insufficient-surplus");
        // require(sub(sub(vat.sin(address(this)), Sin), Ash) == 0, "Vow/debt-not-zero");
        return (vat.dai(VOW) >= _sysSurplusThreshold());
    }

    // Burn all of the MKR in the Sai Pit
    function finishhim() external returns (uint256 burned) {
        burned = gem.balanceOf(PIT);
        _finishhim();
    }

    function _finishhim() internal {
        pit.burn(MKR);
    }

    // Kick off an auction and return the auction ID
    function ccccombobreaker() external returns (uint256) {
        _heal();  // Flap requires debt == 0
        return vow.flap();
    }

    // Kick off an auction and throw away id
    function _ccccombobreaker() internal {
        vow.flap();
    }

    // Kitchen sink. Call this early and often.
    function hadaiken() external {
        _dripPot();                               // Update the chi
        _dripIlks();                              // Updates the Ilk rates
        _heal();                                  // Cancel out system debt with system surplus
        if (_kickable()) { _ccccombobreaker(); }  // Start an auction
    }
}