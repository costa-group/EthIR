pragma solidity 0.5.11;


interface KeyRingFactoryV2 {
  function newKeyRing(address userSigningKey, address targetKeyRing) external returns (address keyRing);
}


interface SmartWallet {
  function executeAction(
    address to,
    bytes calldata data,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok, bytes memory returnData);
}


contract KeyRingGenericDeployerHelper {
  KeyRingFactoryV2 internal constant _FACTORY = KeyRingFactoryV2(
    0x2484000059004afB720000dc738434fA6200F49D
  );
    
  function newKeyRingAndGenericAction(
    address userSigningKey,
    address targetKeyRing,
    address smartWallet,
    address to,
    bytes calldata data,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (
    address keyRing, bool genericActionOK, bytes memory genericActionReturnData
  ) {
    keyRing = _FACTORY.newKeyRing(userSigningKey, targetKeyRing);
    (genericActionOK, genericActionReturnData) = SmartWallet(smartWallet).executeAction(
      to, data, minimumActionGas, userSignature, dharmaSignature
    );
  }
}