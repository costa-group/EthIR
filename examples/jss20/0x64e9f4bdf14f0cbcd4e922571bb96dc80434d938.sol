pragma solidity ^0.5.12;
/*
* This project is created to implement an election for 2019 Hong Kong local elections.
* Ofcause the Hong Kong government is not going to use it, but we have a chance to show that how an election can be done completely anonymously with blockchain
* Everyone can use this contract, but they must keep this statement here unchanged.
* Fight for freedom, Stand with Hong Kong
* Five Demands, Not One Less
* @secondphonejune2019 (You may find me via Telegram and Telegram only)
*/
/*
* This contract keeps the council list and candidate information. 
* A big problem here is how to include all candidate and council data into this contract effectively
*/
contract electionList{
	string public hashHead = "2019localelection";
	address payable public owner;
    //This one keeps the council list for easy checking by public
    //Information can be found in https://www.elections.gov.hk/dc2019/chi/intro_to_can/A.html
	string[] public councilList = ["中環","半山東","衛城","山頂","大學","觀龍","堅摩","西環",
	"寶翠","石塘咀","西營盤","上環","東華","正街","水街"
	];
	uint256 public councilNumber;
	//This one keeps the list of candidates grouped by council for easy checking
	mapping(string => string[]) public cadidateList;
	mapping(string => uint256) public candidateNumber;
	//address public dateTimeAddr = 0x1a6184CD4C5Bea62B0116de7962EE7315B7bcBce;
	//DateTime dateTime = DateTime(dateTimeAddr);
	//GMT+8, suppose it starts from 7th Nov 2019 9am in Hong Kong, it will be 7th Nov 2019 1am 
	//uint votingStartTime = dateTime.toTimestamp(2019,11,7,1); //7th Nov 2019 9am HKT
	//uint votingEndTime = dateTime.toTimestamp(2019,11,7,14); //7th Nov 2019 10pm HKT
	constructor() public{
	    owner = msg.sender;
	    councilNumber = councilList.length;
	    
	    cadidateList["中環"] = ["許智峯","黃鐘蔚"];
	    cadidateList["半山東"] = ["莫淦森","吳兆康"];
	    cadidateList["衛城"] = ["鄭麗琼","馮家亮"];
	    cadidateList["山頂"] = ["賣間囯信","楊哲安"];
	    cadidateList["大學"] = ["歐頌賢","任嘉兒"];
	    cadidateList["觀龍"] = ["楊開永","周世傑","梁晃維"];
	    cadidateList["堅摩"] = ["黃健菁","林雪迎","陳學鋒"];
	    cadidateList["西環"] = ["張國鈞","黃美𡖖","彭家浩"];
	    cadidateList["寶翠"] = ["楊浩然","馮敬彥","葉永成"];
	    cadidateList["石塘咀"] = ["陳財喜","葉錦龍"];
	    cadidateList["西營盤"] = ["黃永志","劉天正"];
	    cadidateList["上環"] = ["呂鴻賓","甘乃威"];
	    cadidateList["東華"] = ["張嘉恩","伍凱欣"];
	    cadidateList["正街"] = ["張啟昕","李志恒"];
	    cadidateList["水街"] = ["楊學明","何致宏"];
	    
	    for(uint i=0;i<councilNumber;i++){
	        candidateNumber[councilList[i]] = cadidateList[councilList[i]].length;
		}
	}
}