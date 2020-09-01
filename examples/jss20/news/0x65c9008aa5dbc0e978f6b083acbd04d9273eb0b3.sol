pragma solidity ^0.5.15;

contract VatLike {
    function dai (address) external view returns (uint);
    function sin (address) external view returns (uint);
}

contract VowLike {
    function vat() external returns (VatLike);
    function Sin() external returns (uint256);
    function Ash() external returns (uint256);
    function heal(uint256) external;
    function flop() external;
}

contract FlopStarter {

    VowLike public constant vow = VowLike(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    VatLike public vat;

    constructor () public {
        vat = vow.vat();
    }

    function flop() external {
        uint256 Sin = vow.Sin();
        uint256 sin = vat.sin(address(vow));
        uint256 Ash = vow.Ash();
        uint256 rad = sin - Sin - Ash;
        vow.heal(rad);
        vow.flop();
    }
}