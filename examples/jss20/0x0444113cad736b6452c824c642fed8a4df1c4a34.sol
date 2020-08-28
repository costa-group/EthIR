pragma solidity ^0.5.12;

// EtherBuy is a DApp to buy and sell anything on Ethereum.
contract EtherBuy {
	struct oneSale {
		address payable seller;
		string title;
		string content;
		uint price;
		uint locked; //money will be locked until the buyer sends feedback or the seller cancels sale
		bool available;
	}
	struct oneBuy {
		address payable buyer;
		string message;
		bool lockReleased;
		bool hasReceived;
		string commentByBuyer;
		string commentBySeller;
	}
	
	oneSale[] public sales;
	mapping(uint => oneBuy[]) public buys;

	event SellEvent();
	event BuyEvent(uint SaleID, string message);
	event CancelEvent(uint SaleID);
	event FeedbackEvent(uint SaleID, uint BuyID);

	function sell(string memory title, string memory content, uint price, uint locked) public {
		sales.push(oneSale(
			msg.sender,
			title,
			content,
			price,
			locked,
			true
		));		
		emit SellEvent();
	}

	function buy(uint SaleID, string memory message) public payable {
		require(sales[SaleID].available);
		require(msg.value==sales[SaleID].price+sales[SaleID].locked);

		buys[SaleID].push(oneBuy(
			msg.sender,
			message,
			false,
			false,
			"",
			""
		));

		sales[SaleID].seller.transfer(sales[SaleID].price);
		
		emit BuyEvent(SaleID, message);
	}

	function cancel(uint SaleID) public {
		require(msg.sender==sales[SaleID].seller);
		sales[SaleID].available = false;
		if(sales[SaleID].locked>0) {
			uint lockedValue = sales[SaleID].locked;
			for (uint BuyID=0; BuyID<buys[SaleID].length; BuyID++) {
				if(buys[SaleID][BuyID].lockReleased==false) {
					buys[SaleID][BuyID].lockReleased = true;
					buys[SaleID][BuyID].buyer.transfer(lockedValue);
				}
			}
		}
		emit CancelEvent(SaleID);
	}

	function buyerFeedback(uint SaleID, uint BuyID, bool hasReceived, string memory comment) public {
		require(msg.sender==buys[SaleID][BuyID].buyer);

		if(!buys[SaleID][BuyID].lockReleased && sales[SaleID].locked>0) {
			buys[SaleID][BuyID].lockReleased = true;
			msg.sender.transfer(sales[SaleID].locked);
		}

		buys[SaleID][BuyID].hasReceived = hasReceived;
		buys[SaleID][BuyID].commentByBuyer = comment;
		emit FeedbackEvent(SaleID, BuyID);
	}

	function sellerFeedback(uint SaleID, uint BuyID, string memory comment) public {
		require(msg.sender==sales[SaleID].seller);
		buys[SaleID][BuyID].commentBySeller = comment;
		emit FeedbackEvent(SaleID, BuyID);
	}

    function getCountOfSales() view public returns (uint) {
    	return sales.length;
    }
    
    function getCountOfBuys(uint SaleID) view public returns (uint) {
    	return buys[SaleID].length;
    }
}