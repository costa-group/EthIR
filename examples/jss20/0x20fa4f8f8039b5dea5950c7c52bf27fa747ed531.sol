pragma solidity 0.6.2;


interface SmartWalletInterface {
  function migrateSaiToDai() external;
  function migrateCSaiToDDai() external;
  function migrateCDaiToDDai() external;
  function migrateCUSDCToDUSDC() external;
}


contract DTokenMigrator {
  function batchMigrateSaiToDai(SmartWalletInterface[] calldata wallets) external {
    for (uint256 i = 0; i < wallets.length; i++) {
      if (gasleft() < 400000) {
        break;
      }
      try wallets[i].migrateSaiToDai() {} catch {}
    }
  }

  function batchMigrateCSaiToDDai(SmartWalletInterface[] calldata wallets) external {
    for (uint256 i = 0; i < wallets.length; i++) {
      if (gasleft() < 600000) {
        break;
      }
      try wallets[i].migrateCSaiToDDai() {} catch {}
    }
  }

  function batchMigrateCDaiToDDai(SmartWalletInterface[] calldata wallets) external {
    for (uint256 i = 0; i < wallets.length; i++) {
      if (gasleft() < 200000) {
        break;
      }
      try wallets[i].migrateCDaiToDDai() {} catch {}
    }
  }

  function batchMigrateCUSDCToDUSDC(SmartWalletInterface[] calldata wallets) external {
    for (uint256 i = 0; i < wallets.length; i++) {
      if (gasleft() < 200000) {
        break;
      }
      try wallets[i].migrateCUSDCToDUSDC() {} catch {}
    }
  }
}