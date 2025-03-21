pragma solidity ^0.5.11;




interface DharmaSmartWalletImplementationV0Interface {

    enum ActionType {

        Cancel, SetUserSigningKey, Generic, GenericAtomicBatch, DAIWithdrawal,

        USDCWithdrawal, ETHWithdrawal, DAIBorrow, USDCBorrow

    }

    function getUserSigningKey() external view returns (address userSigningKey);

    function getNonce() external view returns (uint256 nonce);

    function getVersion() external pure returns (uint256 version);

}





interface DharmaKeyRegistryInterface {

    function getKeyForUser(address account) external view returns (address key);

}





contract SetUserSigningKeyActionIDHelper {

    function getSetUserSigningKeyActionID(

        DharmaSmartWalletImplementationV0Interface smartWallet,

        address userSigningKey,

        uint256 minimumActionGas

    ) external view returns (bytes32 actionID) {

        uint256 version = smartWallet.getVersion();

        DharmaKeyRegistryInterface keyRegistry;

        if (version == 2) {

            keyRegistry = DharmaKeyRegistryInterface(

                0x00000000006c7f32F0cD1eA4C1383558eb68802D

            );

        } else {

            keyRegistry = DharmaKeyRegistryInterface(

                0x00000000006c7f32F0cD1eA4C1383558eb68802D

            );

        }



        actionID = keccak256(

            abi.encodePacked(

                address(smartWallet),

                version,

                smartWallet.getUserSigningKey(),

                keyRegistry.getKeyForUser(address(smartWallet)),

                smartWallet.getNonce(),

                minimumActionGas,

                DharmaSmartWalletImplementationV0Interface.ActionType.SetUserSigningKey,

                abi.encode(userSigningKey)

            )

        );

    }

}