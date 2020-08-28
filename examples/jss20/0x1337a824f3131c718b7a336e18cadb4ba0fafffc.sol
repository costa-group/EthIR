pragma solidity >0.6.0;

interface GnosisSafeSetup {
     function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;
}

interface ProxyFactory {
     function createProxy(address masterCopy, bytes calldata data) external returns (address payable proxy);
}

contract Safe_1_1_1_Factory {
    ProxyFactory private constant PROXY_FACTORY = ProxyFactory(0x76E2cFc1F5Fa8F6a5b3fC4c8F4788F0116861F9B);
    address private constant MASTER_COPY = 0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F;
    
    fallback() payable external {
        address[] memory owners = new address[](1);
        owners[0] = msg.sender;
        bytes memory proxyInitData = abi.encodeWithSelector(
            GnosisSafeSetup.setup.selector,
            owners,
            1,
            address(0x0),
            new bytes(0),
            address(0x0),
            address(0x0),
            0,
            address(0x0)
        );
        address payable safe = PROXY_FACTORY.createProxy(MASTER_COPY, proxyInitData);
        require(safe != address(0x0), "Safe deployment failed");
        if (msg.value > 0) {
            safe.transfer(msg.value);
        }
    }
}