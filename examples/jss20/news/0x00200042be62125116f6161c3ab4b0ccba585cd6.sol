pragma solidity 0.5.17;

contract IDpost {
    string public ID;
    
    event Post(string indexed ID);
    
    function post(string calldata _ID) external {
        ID = _ID;
        emit Post(ID);
    }
}