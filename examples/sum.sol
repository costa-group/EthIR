
pragma solidity ^0.4.11;

contract Sum {

function suma (uint[] nums) returns (uint sol) {
   sol = 0;
   for(uint i = 0; i < 5; i++)
           sol = sol+nums[i];
 }

}
