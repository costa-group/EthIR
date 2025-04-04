pragma solidity 0.4.18;


contract KyberReserveIf {
    address public kyberNetwork;
}


interface KyberReserveInterface {

    function trade(address srcToken, uint srcAmount, address destToken, address destAddress, uint conversionRate,
        bool validate) public payable returns(bool);
    function getConversionRate(address src, address dest, uint srcQty, uint blockNumber) public view returns(uint);
}


contract KyberNetworkIf {
    KyberReserveInterface[] public reserves;
    function getNumReserves() public view returns(uint);
}


contract CheckReservePoint {

    KyberNetworkIf constant kyber = KyberNetworkIf(0x7C66550C9c730B6fdd4C03bc2e73c5462c5F7ACC);
    KyberNetworkIf constant oldKyber = KyberNetworkIf(0x65bF64Ff5f51272f729BDcD7AcFB00677ced86Cd);

    function checkPointing() public view returns(address[] goodPoint, address[] oldKybers, address[] badPoint, uint numReserves, uint oldIndex, uint goodIndex) {
        numReserves = oldKyber.getNumReserves();

        goodPoint = new address[](numReserves);
        oldKybers = new address[](numReserves);
        badPoint = new address[](10);

        uint badIndex;

        KyberReserveIf reserve;

        for (uint i = 0; i < numReserves; i ++) {
            reserve = KyberReserveIf(oldKyber.reserves(i));

            if (reserve.kyberNetwork() == address(oldKyber)) {
                oldKybers[oldIndex++] = address(reserve);
            } else if (reserve.kyberNetwork() == address(kyber)){
                goodPoint[goodIndex++] = address(reserve);
            } else {
                badPoint[badIndex++] = address(reserve);
            }
        }
    }
}