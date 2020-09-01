pragma solidity ^0.4.25;

contract Incrementer {
	uint256 private counter;

	event Incremented(uint256 newCounter);

	constructor() public {
		counter = 0;
	}

	function increment() public {
		counter = counter + 1;
		emit Incremented(counter);
	}
}