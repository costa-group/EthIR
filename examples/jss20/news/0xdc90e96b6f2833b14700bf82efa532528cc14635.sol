pragma solidity >=0.4.0;

contract PLACE {
    address payable fund = 0xA59B29d7dbC9794d1e7f45123C48b2b8d0a34636;
    mapping (address => uint) public block_number;
    bytes3[1048576] public pole;
    
    function doPaint(uint32 num, bytes3 color) public payable {
        require(
            num < 1048576 &&
            block.number > block_number[msg.sender] + 23 &&
            msg.value > 100000000000000 && msg.value < 1000000000000000000000000
        );
        block_number[msg.sender] = block.number;
        pole[num] = color;
        fund.transfer(msg.value);
    }
    
    function get_Pole_(uint32 cursor, uint32 howMany) public view returns ( bytes3[] memory _pole ) {
        uint32 length = howMany;
        if (length > 1048576 - cursor) length = 1048576 - cursor;
        _pole = new bytes3[](length);
        for (uint32 i = 0; i < length; i++) _pole[i] = pole[cursor + i];
        return (_pole);
    }
}