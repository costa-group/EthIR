// Copyright (C) 2019 lucasvo



// This program is free software: you can redistribute it and/or modify

// it under the terms of the GNU Affero General Public License as published by

// the Free Software Foundation, either version 3 of the License, or

// (at your option) any later version.

//

// This program is distributed in the hope that it will be useful,

// but WITHOUT ANY WARRANTY; without even the implied warranty of

// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the

// GNU Affero General Public License for more details.

//

// You should have received a copy of the GNU Affero General Public License

// along with this program.  If not, see <https://www.gnu.org/licenses/>.



pragma solidity ^0.5.12;


contract MintLike {

    uint public totalSupply;

    function mint(address,uint) public;

}



contract Budget {

    // --- Auth ---

    mapping (address => uint) public wards;

    function rely(address usr) public auth { wards[usr] = 1; }

    function deny(address usr) public auth { wards[usr] = 0; }

    modifier auth { require(wards[msg.sender] == 1); _; }



    // --- Data ---

    MintLike                  public roof;



    mapping (address => uint) public budgets;



    event BudgetSet(address indexed sender, address indexed usr, uint wad);



    constructor(address roof_) public {

        wards[msg.sender] = 1;

        roof = MintLike(roof_);

    }



    // --- Budget ---

    function mint(address usr, uint wad) public {

        roof.mint(usr, wad);

        require(budgets[msg.sender] >= wad);

        budgets[msg.sender] -= wad;

    }



    function budget(address usr, uint wad) public auth {

        budgets[usr] = wad;

        emit BudgetSet(msg.sender, usr, wad);

    }

}