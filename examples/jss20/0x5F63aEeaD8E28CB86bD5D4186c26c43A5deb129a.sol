pragma solidity ^0.5.10;

library Util {
    struct User {
        bool isExist;
        uint256 id;
        uint256 origRefID;
        uint256 referrerID;
        address[] referral;
        uint256[] expiring;
    }

}