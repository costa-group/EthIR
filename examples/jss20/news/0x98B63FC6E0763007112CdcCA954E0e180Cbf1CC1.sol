pragma solidity ^0.4.26;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context, Ownable {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()) || isOwner(), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

contract TTBTC is WhitelistAdminRole {

    using SafeMath for *;

    string constant private name = "TTBTC Game Official";

    uint startTime = 9;
    uint endTime = 12;

    uint investMin = 10 ** 17 wei;
    uint investMax = 10 ether;
    uint winnerProfitMax = 25 ether;

    address  private devAddr = address(0xEBd465Cd6B0d415887B6B035ADfF0237EFb413b9);

    uint devBalance = 0;
    uint userBalance = 0;

    struct UserGlobal {
        uint id;
        address userAddress;
        string referrer;
        string inviteCode;
        uint level;
        uint lv2Friends;
        uint lv3Friends;
    }

    struct User {
        uint id;
        address userAddress;
        uint level;
        string referrer;
        string inviteCode;
        uint balance;
        uint allInvestMoney;
        uint allInvestCount;
        uint allGuessBonus;
        uint allInviteBonus;
    }

    struct Invest {
        address userAddress;
        uint investAmount;
        uint intent;
        uint investTime;
    }

    struct InvestPool {
        uint investCount;
        mapping(uint => Invest) invests;
        mapping(address => Invest[]) userInvests;
        uint riseInvests;
        uint fallInvests;
        uint beginBtcPrice;
        uint endBtcPrice;
        bool isRise;
    }

    mapping(uint => InvestPool) rInvests;

    uint rid = 0;

    uint investCount = 0;

    uint investMoney = 0;

    uint uid = 0;

    mapping(uint => address) public indexMapping;
    mapping(string => UserGlobal) inviteCodeMapping;
    mapping(address => User) addressMapping;

    modifier isHuman() {
        address addr = msg.sender;
        uint codeLength;

        assembly {codeLength := extcodesize(addr)}
        require(codeLength == 0, "sorry humans only");
        require(tx.origin == msg.sender, "sorry, human only");
        _;
    }

    event LogInvestIn(uint indexed r, address indexed who, uint amount, uint time, uint intent);
    event LogWinnerProfit(uint indexed r, address indexed who, uint amount, uint intent, uint time);
    event LogInviteProfit(uint indexed r, address indexed from, uint fromLv, address indexed who, uint profit, uint time);
    event LogWithdrawProfit(address indexed who, uint amount, uint time);
    event LogRoundEnd(uint r, uint time);
    event LogSystemParamChange(uint paramType, uint time);

    constructor () public {
    }

    function() external payable {
    }

    function investIn(string memory inviteCode, string memory referrer, uint intent) public isHuman() payable {
        require(validInvestTime(), "invest is not allowd now");
        require(validInvestAmount(msg.value), "invalid invest value");
        require(intent == 0 || intent == 1, "invalid intent");

        User storage user = addressMapping[msg.sender];
        if (user.id == 0) {
            require(!compareStr(inviteCode, ""), "empty invite code");
            require(!isUsed(inviteCode), "invite code is used");
            uint userLevel = 1;
            UserGlobal storage parent = inviteCodeMapping[referrer];
            if (parent.id != 0) {
                if (parent.level == 1) {
                    userLevel = 2;
                    parent.lv2Friends++;
                } else if (parent.level == 2) {
                    userLevel = 3;
                    parent.lv3Friends++;
                    UserGlobal storage topParent = inviteCodeMapping[parent.referrer];
                    topParent.lv3Friends++;
                }
            } else {
                referrer = "";
            }
            registerUser(msg.sender, inviteCode, referrer, userLevel);
            user = addressMapping[msg.sender];
        }

        user.allInvestCount++;
        user.allInvestMoney += msg.value;

        Invest memory invest = Invest(msg.sender, msg.value, intent, now);
        InvestPool storage investPool = rInvests[rid];
        investPool.investCount++;
        investPool.invests[investPool.investCount] = invest;
        if (intent == 1) {
            investPool.riseInvests += msg.value;
        } else {
            investPool.fallInvests += msg.value;
        }
        Invest[] storage investList = investPool.userInvests[msg.sender];
        investList.push(invest);

        investCount++;
        investMoney += msg.value;
        emit LogInvestIn(rid, msg.sender, msg.value, invest.investTime, intent);
    }

    function reInvestIn(uint amount, uint intent) public isHuman() payable {
        require(amount > 0, "invalid invest value");
        require(validInvestTime(), "invest is not allowd now");
        require(intent == 0 || intent == 1, "invalid intent");

        User storage user = addressMapping[msg.sender];
        require(user.balance >= amount, "balance insufficient");
        uint allInvest = amount + msg.value;
        require(validInvestAmount(allInvest), "invalid invest value");

        user.balance -= amount;
        user.allInvestCount++;
        user.allInvestMoney += allInvest;

        Invest memory invest = Invest(msg.sender, allInvest, intent, now);
        InvestPool storage investPool = rInvests[rid];
        investPool.investCount++;
        investPool.invests[investPool.investCount] = invest;
        if (intent == 1) {
            investPool.riseInvests += allInvest;
        } else {
            investPool.fallInvests += allInvest;
        }
        Invest[] storage investList = investPool.userInvests[msg.sender];
        investList.push(invest);

        investCount++;
        investMoney += allInvest;
        userBalance -= amount;
        emit LogInvestIn(rid, msg.sender, allInvest, invest.investTime, intent);

    }

    function roundEnd(uint closePrice, uint openPrice, uint currentDate) external onlyWhitelistAdmin {
        InvestPool storage investPool = rInvests[rid];
        investPool.endBtcPrice = closePrice;
        investPool.isRise = investPool.endBtcPrice >= investPool.beginBtcPrice;
        if (investPool.investCount > 0) {
            uint winnerInvest = investPool.isRise ? investPool.riseInvests : investPool.fallInvests;
            uint allProfit = investPool.isRise ? investPool.fallInvests : investPool.riseInvests;
            uint userAllProfit = allProfit.div(10).mul(9);
            uint devProfit = allProfit.sub(userAllProfit);
            uint divided = 0;

            for (uint i = 1; i <= investPool.investCount; i++) {
                Invest storage invest = investPool.invests[i];
                uint userProfit = 0;
                if (investPool.isRise && invest.intent == 1 || !investPool.isRise && invest.intent == 0) {
                    uint profitSc = invest.investAmount.mul(1000000).div(winnerInvest);
                    userProfit = profitSc.mul(userAllProfit).div(1000000);
                    userProfit > winnerProfitMax ? winnerProfitMax : userProfit;
                }

                if (userProfit > 0) {
                    divided += userProfit;
                    uint divideProfit = divideProfitInternal(invest.userAddress, invest.investAmount, userProfit, invest.intent, invest.investTime);
                    devProfit -= divideProfit;
                }
            }
            devBalance = devBalance.add(devProfit).add(userAllProfit.sub(divided));
        }

        emit LogRoundEnd(rid, now);

        rid = currentDate;
        InvestPool storage ip = rInvests[rid];
        ip.beginBtcPrice = openPrice;
    }

    function divideProfitInternal(address userAddress, uint investAmount, uint userProfit, uint intent, uint investTime) internal returns (uint) {
        User storage userInfo = addressMapping[userAddress];
        userInfo.allGuessBonus += userProfit;
        userInfo.balance = userInfo.balance.add(investAmount).add(userProfit);
        userBalance = userBalance.add(investAmount).add(userProfit);
        emit LogWinnerProfit(rid, userInfo.userAddress, userProfit, intent, investTime);

        uint divideProfit = parentProfit(userInfo, userProfit);
        return divideProfit;
    }

    function parentProfit(User memory userInfo, uint userProfit) internal returns (uint) {
        uint divideProfit = 0;
        if (userInfo.level == 3) {
            User storage lv2User = addressMapping[inviteCodeMapping[userInfo.referrer].userAddress];
            if (lv2User.id != 0) {
                uint lv2Profit = userProfit.mul(10).div(9).mul(2).div(100);
                lv2User.allInviteBonus = lv2User.allInviteBonus.add(lv2Profit);
                lv2User.balance = lv2User.balance.add(lv2Profit);
                divideProfit += lv2Profit;
                userBalance += lv2Profit;
                emit LogInviteProfit(rid, userInfo.userAddress, userInfo.level, lv2User.userAddress, lv2Profit, now);
                User storage lv1User = addressMapping[inviteCodeMapping[lv2User.referrer].userAddress];
                if (lv1User.id != 0) {
                    uint lv1Profit = userProfit.mul(10).div(9).mul(1).div(100);
                    lv1User.allInviteBonus = lv1User.allInviteBonus.add(lv1Profit);
                    lv1User.balance = lv1User.balance.add(lv1Profit);
                    divideProfit += lv1Profit;
                    userBalance += lv1Profit;
                    emit LogInviteProfit(rid, userInfo.userAddress, userInfo.level, lv1User.userAddress, lv1Profit, now);
                }
            }
        } else if (userInfo.level == 2) {
            lv1User = addressMapping[inviteCodeMapping[userInfo.referrer].userAddress];
            if (lv1User.id != 0) {
                lv1Profit = userProfit.mul(10).div(9).mul(3).div(100);
                lv1User.allInviteBonus = lv1User.allInviteBonus.add(lv1Profit);
                lv1User.balance = lv1User.balance.add(lv1Profit);
                divideProfit += lv1Profit;
                userBalance += lv1Profit;
                emit LogInviteProfit(rid, userInfo.userAddress, userInfo.level, lv1User.userAddress, lv1Profit, now);
            }
        }
        return divideProfit;
    }

    function withdraw(uint amount)
    public
    isHuman() {
        User storage user = addressMapping[msg.sender];
        require(amount > 0 && user.balance >= amount, "withdraw amount error");
        sendMoneyToUser(msg.sender, amount);
        user.balance -= amount;
        userBalance -= amount;
        emit LogWithdrawProfit(msg.sender, amount, now);
    }

    function devWithdraw(uint amount) external onlyWhitelistAdmin {
        require(devBalance >= amount, "invalid withdraw amount");
        sendMoneyToUser(devAddr, amount);
        devBalance -= amount;
        emit LogWithdrawProfit(devAddr, amount, now);
    }

    function sendMoneyToUser(address userAddress, uint money) private {
        userAddress.transfer(money);
    }

    function registerUserInfo(address user, string inviteCode, string referrer) external onlyOwner {
        registerUser(user, inviteCode, referrer, 1);
    }

    function isUsed(string memory code) public view returns (bool) {
        UserGlobal storage user = inviteCodeMapping[code];
        return user.id != 0;
    }

    function getGameInfo() public isHuman() view returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        InvestPool storage investPool = rInvests[rid];
        return (
        rid,
        investPool.investCount,
        investPool.riseInvests,
        investPool.fallInvests,
        investPool.beginBtcPrice,
        userBalance,
        devBalance,
        address(this).balance,
        startTime,
        endTime,
        investMin,
        investMax
        );
    }

    function getGameInfoByRid(uint r) public isHuman() view returns (uint, uint, uint, uint, uint, uint, bool) {
        InvestPool storage investPool = rInvests[r];
        return (
        rid,
        investPool.investCount,
        investPool.riseInvests,
        investPool.fallInvests,
        investPool.beginBtcPrice,
        investPool.endBtcPrice,
        investPool.isRise
        );
    }

    function getUserInfo(address userAddr) public isHuman() view returns (uint [8] memory ct, string memory inviteCode, string memory referrer) {
        User memory userInfo = addressMapping[userAddr];
        UserGlobal memory userGlobal = inviteCodeMapping[userInfo.inviteCode];
        ct[0] = userGlobal.level;
        ct[1] = userGlobal.lv2Friends;
        ct[2] = userGlobal.lv3Friends;
        ct[3] = 0;
        ct[4] = 0;
        ct[5] = userInfo.balance;
        ct[6] = userInfo.allGuessBonus;
        ct[7] = userInfo.allInviteBonus;

        InvestPool storage ip = rInvests[rid];
        Invest[] storage invests = ip.userInvests[userInfo.userAddress];
        for (uint i = 0; i < invests.length; i++) {
            Invest storage invest = invests[i];
            if (invest.intent == 1) {
                ct[3] += invest.investAmount;
            } else {
                ct[4] += invest.investAmount;
            }
        }
        inviteCode = userInfo.inviteCode;
        referrer = userInfo.referrer;
        return (
        ct,
        inviteCode,
        referrer
        );
    }

    function registerUser(address user, string memory inviteCode, string memory referrer, uint userLevel) private {
        UserGlobal storage userGlobal = inviteCodeMapping[inviteCode];
        uid++;
        userGlobal.id = uid;
        userGlobal.userAddress = user;
        userGlobal.inviteCode = inviteCode;
        userGlobal.referrer = referrer;
        userGlobal.level = userLevel;

        indexMapping[uid] = user;
        User storage userInfo = addressMapping[user];
        userInfo.id = uid;
        userInfo.userAddress = user;
        userInfo.inviteCode = inviteCode;
        userInfo.referrer = referrer;
        userInfo.level = userLevel;
    }

    function setInvestMin(uint m) external onlyWhitelistAdmin {
        require(m > 0, "param error");
        investMin = m;
        emit LogSystemParamChange(3, now);
    }

    function setInvestMax(uint m) external onlyWhitelistAdmin {
        require(m > 0, "param error");
        investMax = m;
        emit LogSystemParamChange(4, now);
    }

    function getHour() internal view returns (uint) {
        return now % 86400 / 3600 + 8;
    }

    function getSecond() internal view returns (uint) {
        return now % 3600 / 60;
    }

    function validInvestTime() internal view returns (bool) {
        uint hour = getHour();
        if (hour >= startTime && hour < endTime) {
            return true;
        }
        return false;
    }

    function validInvestAmount(uint amount) internal view returns (bool) {
        return amount >= investMin && amount <= investMax;
    }

    function compareStr(string memory _str, string memory str) public pure returns (bool) {
        if (keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str))) {
            return true;
        }
        return false;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "mul overflow");

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div zero");
        // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "lower sub bigger");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "overflow");
        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "mod zero");
        return a % b;
    }
}