pragma solidity ^0.5.0;


contract Gem {
    function dec() public returns (uint);
    function gem() public returns (Gem);
    function join(address, uint) public payable;
    function exit(address, uint) public;

    function approve(address, uint) public;
    function transfer(address, uint) public returns (bool);
    function transferFrom(address, address, uint) public returns (bool);
    function deposit() public payable;
    function withdraw(uint) public;
    function allowance(address, address) public returns (uint);
}

contract Join {
    bytes32 public ilk;

    function dec() public returns (uint);
    function gem() public returns (Gem);
    function join(address, uint) public payable;
    function exit(address, uint) public;
}

interface ERC20 {
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function decimals() external view returns (uint256 digits);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Vat {

    struct Urn {
        uint256 ink;   
        uint256 art;   
    }

    struct Ilk {
        uint256 Art;   
        uint256 rate;  
        uint256 spot;  
        uint256 line;  
        uint256 dust;  
    }

    mapping (bytes32 => mapping (address => Urn )) public urns;
    mapping (bytes32 => Ilk)                       public ilks;
    mapping (bytes32 => mapping (address => uint)) public gem;  

    function can(address, address) public view returns (uint);
    function dai(address) public view returns (uint);
    function frob(bytes32, address, address, address, int, int) public;
    function hope(address) public;
    function move(address, address, uint) public;
}

contract Flipper {

    function bids(uint _bidId) public returns (uint256, uint256, address, uint48, uint48, address, address, uint256);
    function tend(uint id, uint lot, uint bid) external;
    function dent(uint id, uint lot, uint bid) external;
    function deal(uint id) external;
}

contract BidProxy {

    address public constant ETH_FLIPPER = 0xd8a04F5412223F513DC55F839574430f5EC15531;
    address public constant BAT_FLIPPER = 0xaA745404d55f88C108A28c86abE7b5A1E7817c07;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public constant DAI_JOIN = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public constant ETH_JOIN = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    address public constant BAT_JOIN = 0x3D0B1912B66114d4096F48A8CEe3A56C231772cA;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    bytes32 public constant BAT_ILK = 0x4241542d41000000000000000000000000000000000000000000000000000000;
    bytes32 public constant ETH_ILK = 0x4554482d41000000000000000000000000000000000000000000000000000000;

    function daiBid(uint _bidId, bool _isEth, uint _amount) public {
        uint tendAmount = _amount * (10 ** 27);
        address flipper = _isEth ? ETH_FLIPPER : BAT_FLIPPER;

        joinDai(_amount);

        (, uint lot, , , , , , ) = Flipper(flipper).bids(_bidId);

        Vat(VAT_ADDRESS).hope(flipper);

        Flipper(flipper).tend(_bidId, lot, tendAmount);
    }

    function collateralBid(uint _bidId, bool _isEth, uint _amount) public {
        address flipper = _isEth ? ETH_FLIPPER : BAT_FLIPPER;

        uint bid;
        (bid, , , , , , , ) = Flipper(flipper).bids(_bidId);

        joinDai(bid / (10**27));

        Vat(VAT_ADDRESS).hope(flipper);

        Flipper(flipper).dent(_bidId, _amount, bid);
    }

    function closeBid(uint _bidId, bool _isEth) public {
        address flipper = _isEth ? ETH_FLIPPER : BAT_FLIPPER;
        address join = _isEth ? ETH_JOIN : BAT_JOIN;
        bytes32 ilk = _isEth ? ETH_ILK : BAT_ILK;

        Flipper(flipper).deal(_bidId);
        uint amount = Vat(VAT_ADDRESS).gem(ilk, address(this)) / (10**27);

        Vat(VAT_ADDRESS).hope(join);
        Gem(join).exit(msg.sender, amount);
    }

    function exitCollateral(bool _isEth) public {
        address join = _isEth ? ETH_JOIN : BAT_JOIN;
        bytes32 ilk = _isEth ? ETH_ILK : BAT_ILK;

        uint amount = Vat(VAT_ADDRESS).gem(ilk, address(this));

        Vat(VAT_ADDRESS).hope(join);
        Gem(join).exit(msg.sender, amount);
    }

    function exitDai() public {
        uint amount = Vat(VAT_ADDRESS).dai(address(this)) / (10**27);

        Vat(VAT_ADDRESS).hope(DAI_JOIN);
        Gem(DAI_JOIN).exit(msg.sender, amount);
    }

    function withdrawToken(address _token) public {
        uint balance = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(msg.sender, balance);
    }

    function withdrawEth() public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function joinDai(uint _amount) internal {
        uint amountInVat = Vat(VAT_ADDRESS).dai(address(this)) / (10**27);

        if (_amount > amountInVat) {
            uint amountDiff = (_amount - amountInVat) + 1;

            ERC20(DAI_ADDRESS).transferFrom(msg.sender, address(this), amountDiff);
            ERC20(DAI_ADDRESS).approve(DAI_JOIN, amountDiff);
            Join(DAI_JOIN).join(address(this), amountDiff);
        }
    }
}