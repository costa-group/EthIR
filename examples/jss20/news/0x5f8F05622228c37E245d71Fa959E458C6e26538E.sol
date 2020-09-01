{{
  "language": "Solidity",
  "sources": {
    "solidity/contracts/system/TBTCConstants.sol": {
      "content": "/*\n Authored by Satoshi Nakamoto 🤪\n*/\n\npragma solidity 0.5.17;\n\nlibrary TBTCConstants {\n    // This is intended to make it easy to update system params\n    // During testing swap this out with another constats contract\n\n    // System Parameters\n    uint256 public constant BENEFICIARY_FEE_DIVISOR = 1000;  // 1/1000 = 10 bps = 0.1% = 0.001\n    uint256 public constant SATOSHI_MULTIPLIER = 10 ** 10; // multiplier to convert satoshi to TBTC token units\n    uint256 public constant DEPOSIT_TERM_LENGTH = 180 * 24 * 60 * 60; // 180 days in seconds\n    uint256 public constant TX_PROOF_DIFFICULTY_FACTOR = 6; // confirmations on the Bitcoin chain\n\n    // Redemption Flow\n    uint256 public constant REDEMPTION_SIGNATURE_TIMEOUT = 2 * 60 * 60;  // seconds\n    uint256 public constant INCREASE_FEE_TIMER = 4 * 60 * 60;  // seconds\n    uint256 public constant REDEMPTION_PROOF_TIMEOUT = 6 * 60 * 60;  // seconds\n    uint256 public constant MINIMUM_REDEMPTION_FEE = 2000; // satoshi\n\n    // Funding Flow\n    uint256 public constant FUNDING_PROOF_TIMEOUT = 3 * 60 * 60; // seconds\n    uint256 public constant FORMATION_TIMEOUT = 3 * 60 * 60; // seconds\n\n    // Liquidation Flow\n    uint256 public constant COURTESY_CALL_DURATION = 6 * 60 * 60; // seconds\n    uint256 public constant AUCTION_DURATION = 24 * 60 * 60; // seconds\n    uint256 public constant PERMITTED_FEE_BUMPS = 5; // number of times the fee can be increased\n\n    // Getters for easy access\n    function getBeneficiaryRewardDivisor() public pure returns (uint256) { return BENEFICIARY_FEE_DIVISOR; }\n    function getSatoshiMultiplier() public pure returns (uint256) { return SATOSHI_MULTIPLIER; }\n    function getDepositTerm() public pure returns (uint256) { return DEPOSIT_TERM_LENGTH; }\n    function getTxProofDifficultyFactor() public pure returns (uint256) { return TX_PROOF_DIFFICULTY_FACTOR; }\n\n    function getSignatureTimeout() public pure returns (uint256) { return REDEMPTION_SIGNATURE_TIMEOUT; }\n    function getIncreaseFeeTimer() public pure returns (uint256) { return INCREASE_FEE_TIMER; }\n    function getRedemptionProofTimeout() public pure returns (uint256) { return REDEMPTION_PROOF_TIMEOUT; }\n    function getMinimumRedemptionFee() public pure returns (uint256) { return MINIMUM_REDEMPTION_FEE; }\n\n    function getFundingTimeout() public pure returns (uint256) { return FUNDING_PROOF_TIMEOUT; }\n    function getSigningGroupFormationTimeout() public pure returns (uint256) { return FORMATION_TIMEOUT; }\n\n    function getCourtesyCallTimeout() public pure returns (uint256) { return COURTESY_CALL_DURATION; }\n    function getAuctionDuration() public pure returns (uint256) { return AUCTION_DURATION; }\n    function getPermittedFeeBumps() public pure returns (uint256) {return PERMITTED_FEE_BUMPS; }\n}\n"
    }
  },
  "settings": {
    "metadata": {
      "useLiteralContent": true
    },
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    }
  }
}}