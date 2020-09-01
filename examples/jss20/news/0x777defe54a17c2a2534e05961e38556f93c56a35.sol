pragma solidity 0.5.16;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @dev banq audit is a decentralized audit platform for opensource (smart contract) audit projects
 *      anyone can submit audit request and anyone can submit a audit report. A successful agree results in
 *      increased loyalty points. A disagree results in loss of loyalty points.
 */
contract BanqAudit {
    using SafeMath for uint256;
    
    //audit data
    struct Audit {
        address owner;
        string link;
        uint256 balance;
        uint256[4] rewards;
        uint256 reportIndex;
        uint256[] reports;
        address[] validated;
        bool closed;
    }
    
    //audit report data
    struct Report {
        address owner;
        bytes32 auditid;
        bytes32 reportid;
        string link;
        uint256 totalrisk;
        uint256[10] bugs;
        uint256[10] bugrisk;
        uint256[10] bugreview;
        bool[10] bugclosed;
        //reportstatus 1 = opened, 2 = responded auditee & 3 = closed auditor
        uint256 reportstatus;           
        uint256 payout;
    }
    
    //Total variables
    uint256 public totalRewardAvailable;
    uint256 public totalPendingPayout;

    //reliability points auditor and auditee
    uint256 public totalReliability_auditee;
    uint256 public totalReliability_auditor;
    mapping (address => uint256) public reliability_auditee; 
    mapping (address => uint256) public reliability_auditor; 
    
    //audit requests index and mapping of audits
    uint256 public indexTotal;
    uint256 public indexPending;
    mapping (bytes32 => Audit) public audits;
    mapping (uint256 => bytes32) public index_audit;
    mapping (bytes32 => uint256) public audit_index;
    mapping (uint256 => uint256) public total_pending;
    mapping (uint256 => uint256) public pending_total;
    
    //audit report index and mapping of audits
    uint256 public indexReports;
    mapping (uint256 => Report) public reports;
    
    //address developer used for fee payment
    address payable public dev;

    //Events to submit during stages of audit
    event AuditRequest(bytes32 _contracthash, uint256 _rewardtotal, address owner);
    event ReportSubmit(bytes32 _contracthash, bytes32 _reporthash, uint256 _reportid, uint256 _risktotal, address owner);
    event VerifiedReport(bytes32 _contracthash, uint256 _reportid, uint256 _amountreview, uint256 _points, bool received);
    event ClosedReport(bytes32 _contracthash, uint256 _reportid, uint256 _payout);
    event ClosedAudit(bytes32 _contracthash, uint256 _amountleft);

    constructor() public {
        dev = msg.sender;
    }

    /**
     * @dev fallback function. Makes the contract payable.
     */
    function() external payable {}

    /**
     * @dev function for the developer to change the address. 
     */
    function changeDev(address payable _dev) external returns (bool) {
        require(msg.sender == dev, "change developer: not the current developer");
        dev = _dev;
    }

    /**
     * @dev functions to get the arrays of the audit and report structs.
     */
     function getAuditData(bytes32 _contracthash) public view returns (uint256[4] memory) {
            return audits[_contracthash].rewards;
     }
     function getAuditReports(bytes32 _contracthash) public view returns (uint256[] memory) {
            return audits[_contracthash].reports;
     }
     function getAuditValidators(bytes32 _contracthash) public view returns (address[] memory) {
            return audits[_contracthash].validated;
     }
     function getReportData(uint256 _indexReports, uint256 id) public view returns (uint256[10] memory) {
            if (id == 0) {
                return reports[_indexReports].bugs;
            }
            if (id == 1) {
                return reports[_indexReports].bugrisk;
            }
            if (id == 2) {
                return reports[_indexReports].bugreview;
            }
     } 
     
    /**
     * @dev auditee can request an audit using this function and sets reward per bug and bug risk.
     *      contract needs a deposit of multiples of the total reward.
     * 
     */
    function RequestAudit(bytes32 _contracthash, string memory _link, uint256[4] memory _rewards) public payable returns (bool success) {
            uint256[] memory emptyarray;
            address[] memory emptyaddress;
            uint256 totalRewards = _rewards[0].add(_rewards[1]).add(_rewards[2]).add(_rewards[3]);
            //calculate fee 0.3% and deduct form deposit
            uint256 deposit_multiplier = msg.value.div(totalRewards);
            uint256 total = totalRewards.mul(deposit_multiplier);
            uint256 fee = total.div(1000).mul(3);
            uint256 amount = msg.value.sub(fee);
            //Check if rewards are multiple of each other and msg.value
            require(audits[_contracthash].owner == address(0), "request audit: audit is non empty");
            require(msg.value != 0, "request audit: no reward added");
            require(amount.mod(totalRewards) == 0, "request audit: msg.value not equal to rewards");
            require(_rewards[0].mod(_rewards[1]) == 0, "request audit: critical reward is not multiple of high reward");
            require(_rewards[1].mod(_rewards[2]) == 0, "request audit: high reward is not multiple of medium reward");
            require(_rewards[2].mod(_rewards[3]) == 0, "request audit: critical medium is not multiple of low reward");
            totalRewardAvailable = totalRewardAvailable.add(amount);
            audits[_contracthash] = Audit({owner: msg.sender,
                                            link: _link,
                                            balance: amount,
                                            rewards: _rewards,
                                            reportIndex: 0,
                                            reports: emptyarray,
                                            validated: emptyaddress,
                                            closed: false
                                    });
            index_audit[indexTotal] = _contracthash;
            audit_index[_contracthash] = indexTotal;
            //Set audit as pending
            total_pending[indexTotal] = indexPending;
            pending_total[indexPending] = indexTotal;
            indexTotal = indexTotal.add(1);
            indexPending = indexPending.add(1);
            dev.transfer(fee);
            emit AuditRequest(_contracthash, totalRewards, msg.sender);
            return true;
    }
    
    /**
     * @dev auditee can deposit additional funds to a pending audit.
     */
    function depositAudit(bytes32 _contracthash) public payable returns (bool success) {
            uint256 minimum = audits[_contracthash].rewards[3];
            //calculate fee 0.3% and deduct form deposit
            uint256 deposit_multiplier = msg.value.div(minimum);
            uint256 total = minimum.mul(deposit_multiplier);
            uint256 fee = total.div(1000).mul(3);
            uint256 amount = msg.value.sub(fee);
            require(!audits[_contracthash].closed, "deposit audit: audit is closed");
            require(msg.value != 0, "request audit: no reward added");
            require(amount.mod(minimum) == 0, "deposit audit: msg.value not multiple of minimum reward");
            totalRewardAvailable = totalRewardAvailable.add(amount);
            audits[_contracthash].balance = audits[_contracthash].balance.add(amount);
            dev.transfer(fee);
            return true;
    }
    
    /**
     * @dev auditor can submit a report (bug) for a pending audit.
     */
    function SubmitReport(bytes32 _contracthash, bytes32 _reporthash, string memory _link, uint256[10] memory _bugID, uint256[10] memory _bugClaim) public returns (bool success) {
            require(!audits[_contracthash].closed, "submit report: audit is closed");
            require(audits[_contracthash].owner != msg.sender, "submit report: auditor and auditee are the same");
            uint256[10] memory emptyarray; 
            bool[10] memory emptyarray1; 
            uint256 totalrisk;
            for (uint256 i = 0; i < 10; i++) {
                require(_bugClaim[i] < 5);
                totalrisk = totalrisk.add(_bugClaim[i]);
            }
            audits[_contracthash].reportIndex = audits[_contracthash].reportIndex.add(1);
            reports[indexReports] = Report({owner: msg.sender,
                                            link: _link,
                                            auditid: _contracthash,
                                            reportid: _reporthash,
                                            totalrisk: totalrisk,
                                            bugs: _bugID,
                                            bugrisk: _bugClaim,
                                            bugreview: emptyarray,
                                            bugclosed: emptyarray1,
                                            reportstatus: 1,
                                            payout: 0
                                    });
            audits[_contracthash].reports.push(indexReports);
            indexReports = indexReports.add(1);
            emit ReportSubmit(_contracthash, _reporthash, indexReports, totalrisk, msg.sender);
            return true;
    }
    
    /**
     * @dev Auditee can check an audit report and agree/adjust the bug risk in the report 
     *      or claim that the report is not received. If not receiven it will deduct 
     *      reliability points of the auditor.
     */
    function VerifyReport(uint256 _reportID, uint256[10] memory _bugClaim, uint256 addition, bool received) public returns (bool success) {
            address auditor = reports[_reportID].owner;
            bytes32 _contracthash = reports[_reportID].auditid;
            require(audits[_contracthash].owner == msg.sender, "verify report: not the owner of the audit");
            require(reports[_reportID].reportstatus == 1, "verify report: report is not status 1");
            reports[_reportID].bugreview = _bugClaim;
            //for loop to calculate amount 
            uint256 amountAudit;
            uint256 amountReport;
            for (uint256 i = 0; i < 10; i++) {
                require(_bugClaim[i] < 5);
                if (reports[_reportID].bugrisk[i] != 0 && reports[_reportID].bugclosed[i] != true) {
                        reports[_reportID].bugclosed[i] == true;
                        if (reports[_reportID].bugreview[i] != 0) {
                            uint256 riskReview = reports[_reportID].bugreview[i].sub(1);
                            amountAudit = amountAudit.add(audits[_contracthash].rewards[riskReview]);
                        }
                        uint256 riskReport = reports[_reportID].bugrisk[i].sub(1);
                        amountReport = amountReport.add(audits[_contracthash].rewards[riskReport]);
                } 
            }
            if (addition > 0) {
                    require(addition < 5);
                    uint256 index = addition.sub(1);
                    amountAudit = amountAudit.add(audits[_contracthash].rewards[index]);
            }
            uint256 points;
            if (received == false) {
                reports[_reportID].reportstatus = 3;
                points = amountReport.div(10**16);
                if (reliability_auditor[reports[_reportID].owner] > points) {
                    totalReliability_auditor = totalReliability_auditor.sub(points);
                    reliability_auditor[reports[_reportID].owner] = reliability_auditor[reports[_reportID].owner].sub(points);
                } else {
                    totalReliability_auditor = totalReliability_auditor.sub(reliability_auditor[reports[_reportID].owner]);
                    reliability_auditor[reports[_reportID].owner] = 0;
                }
            } else {
                points = amountAudit.div(10**16);
                reports[_reportID].reportstatus = 2;
                totalReliability_auditor = totalReliability_auditor.add(points);
                reliability_auditor[auditor] = reliability_auditor[auditor].add(points);
                totalReliability_auditee = totalReliability_auditee.add(points);
                reliability_auditee[msg.sender] = reliability_auditee[msg.sender].add(points);
                totalRewardAvailable = totalRewardAvailable.sub(amountAudit);
                totalPendingPayout = totalPendingPayout.add(amountAudit);
                audits[_contracthash].balance = audits[_contracthash].balance.sub(amountAudit);
                reports[_reportID].payout = reports[_reportID].payout.add(amountAudit);
            }
            emit VerifiedReport(_contracthash, _reportID, amountAudit, points, received);
            return true;
    }
    
    /**
     * @dev Auditor can check response from aditee and agree with changes to receive rewards
     *      or disagree. Disagree will deduct reliability point from the auditee.
     */
    function ClaimResponse(uint256 _reportID, bool agreed) public returns (bool success) {
            bytes32 _contracthash = reports[_reportID].auditid;
            require(reports[_reportID].reportstatus == 2, "claim report: report is not status 2");
            require(reports[_reportID].owner == msg.sender, "claim report: msg.sender is not owner of report");
            reports[_reportID].reportstatus = 3;
            audits[_contracthash].validated.push(msg.sender);
            uint256 amount_nofee = reports[_reportID].payout;
            //calculate fee and deduct
            uint256 fee = amount_nofee.div(1000).mul(3);
            uint256 amount = amount_nofee.sub(fee);
            if (agreed == true) {
                totalPendingPayout = totalPendingPayout.sub(amount_nofee);
                dev.transfer(fee);
                msg.sender.transfer(amount); 
            } else {
                uint256 amountAudit;
                for (uint256 i = 0; i < 10; i++) {
                    if (reports[_reportID].bugreview[i] != 0) {
                        uint256 riskReview = reports[_reportID].bugreview[i].sub(1);
                        amountAudit = amountAudit.add(audits[_contracthash].rewards[riskReview]);
                    } 
                }
                uint256 points = amountAudit.div(10**16);
                if (reliability_auditee[audits[_contracthash].owner] > points) {
                    totalReliability_auditee = totalReliability_auditee.sub(points);
                    reliability_auditee[audits[_contracthash].owner] = reliability_auditee[audits[_contracthash].owner].sub(points);
                } else {
                    totalReliability_auditee = totalReliability_auditee.sub(reliability_auditee[audits[_contracthash].owner]);
                    reliability_auditee[audits[_contracthash].owner] = 0;
                }
                totalPendingPayout = totalPendingPayout.sub(amount_nofee);
                dev.transfer(fee);
                msg.sender.transfer(amount); 
            }
            emit ClosedReport(_contracthash, _reportID, amount);
            return true;
    }
    
    /**
     * @dev Close open audit requests
     */
    function CloseAuditRequest(bytes32 _contracthash) public returns (bool success) {
            require(audits[_contracthash].owner == msg.sender, "close audit: msg.sender is not owner of audit");
            require(audits[_contracthash].closed == false, "close audit: audit is closed");
            //Check pending reports
            uint256 pending;
            for (uint256 i = 0; i < audits[_contracthash].reportIndex; i++) {
                uint256 reportID = audits[_contracthash].reports[i];
                uint256 reportstatus = reports[reportID].reportstatus;
                if (reportstatus == 1) {
                    pending = pending.add(1);
                }
            }
            require(pending == 0, "close audit: there is an open report");
            uint256 amount = audits[_contracthash].balance;
            uint256 index_total = audit_index[_contracthash];
            uint256 pendingIndex = total_pending[index_total];
            uint256 replace = pending_total[indexPending.sub(1)];
            audits[_contracthash].closed = true;
            totalRewardAvailable = totalRewardAvailable.sub(audits[_contracthash].balance);
            audits[_contracthash].balance = 0;
            //Replace with the last and remove last
            pending_total[pendingIndex] = replace;
            total_pending[replace] = pendingIndex;
            pending_total[indexPending.sub(1)] = 0;
            total_pending[index_total] = 0;
            indexPending = indexPending.sub(1);
            //Transfer remaining balance to owner
            msg.sender.transfer(amount);
            emit ClosedAudit(_contracthash, amount);
            return true;
    }
    
    /**
     * @dev Auditor can close a report before reaction of the auditor.
     *      
     */
    function CloseReport(uint256 _reportID) public returns (bool success) {
            require(reports[_reportID].reportstatus == 1, "close report: report is closed");
            require(reports[_reportID].owner == msg.sender, "close report: not the owner");
            reports[_reportID].reportstatus = 3;
            emit ClosedReport(reports[_reportID].auditid, _reportID, 0);
            return true;
    }
}