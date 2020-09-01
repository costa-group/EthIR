pragma solidity 0.6.2;


interface SmartWallet {
    function migrateSaiToDai() external;
}


contract Sainnihilator {
    function migrateAll(SmartWallet[] calldata wallets) external {
        for (uint256 i = 0; i < wallets.length; i++) {
            if (gasleft() < 500000) break;
            try wallets[i].migrateSaiToDai() {} catch {}
        }
    }
}