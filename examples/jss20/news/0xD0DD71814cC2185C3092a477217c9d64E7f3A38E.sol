// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.

//

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


// https://github.com/dapphub/ds-pause

contract DSPauseAbstract {

    function setOwner(address) public;

    function setAuthority(address) public;

    function setDelay(uint256) public;

    function plans(bytes32) public view returns (bool);

    function proxy() public view returns (address);

    function delay() public view returns (uint256);

    function plot(address, bytes32, bytes memory, uint256) public;

    function drop(address, bytes32, bytes memory, uint256) public;

    function exec(address, bytes32, bytes memory, uint256) public returns (bytes memory);

}



// https://github.com/makerdao/dss/blob/master/src/jug.sol

contract JugAbstract {

    function wards(address) public view returns (uint256);

    function rely(address) external;

    function deny(address) external;

    function ilks(bytes32) public view returns (uint256, uint256);

    function vat() public view returns (address);

    function vow() public view returns (address);

    function base() public view returns (address);

    function init(bytes32) external;

    function file(bytes32, bytes32, uint256) external;

    function file(bytes32, uint256) external;

    function file(bytes32, address) external;

    function drip(bytes32) external returns (uint256);

}



// https://github.com/makerdao/dss/blob/master/src/pot.sol

contract PotAbstract {

    function wards(address) public view returns (uint256);

    function rely(address) external;

    function deny(address) external;

    function pie(address) public view returns (uint256);

    function Pie() public view returns (uint256);

    function dsr() public view returns (uint256);

    function chi() public view returns (uint256);

    function vat() public view returns (address);

    function vow() public view returns (address);

    function rho() public view returns (uint256);

    function live() public view returns (uint256);

    function file(bytes32, uint256) external;

    function file(bytes32, address) external;

    function cage() external;

    function drip() external returns (uint256);

    function join(uint256) external;

    function exit(uint256) external;

}



contract SpellAction {

    // Provides a descriptive tag for bot consumption

    // This should be modified weekly to provide a summary of the actions

    string constant public description = "2020-05-08 MakerDAO Executive Spell";



    // The contracts in this list should correspond to MCD core contracts, verify

    //  against the current release list at:

    //     https://changelog.makerdao.com/releases/mainnet/1.0.6/contracts.json

    //

    // Contract addresses pertaining to the SCD ecosystem can be found at:

    //     https://github.com/makerdao/sai#dai-v1-current-deployments

    address constant public MCD_JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;

    address constant public MCD_POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;



    uint256 constant public THOUSAND = 10**3;

    uint256 constant public MILLION = 10**6;

    uint256 constant public WAD = 10**18;

    uint256 constant public RAY = 10**27;

    uint256 constant public RAD = 10**45;



    // Many of the settings that change weekly rely on the rate accumulator

    // described at https://docs.makerdao.com/smart-contract-modules/rates-module

    // To check this yourself, use the following rate calculation (example 8%):

    //

    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'

    //

    uint256 constant public ONE_PCT_RATE = 1000000000315522921573372069;



    function execute() external {

        // perform drips

        PotAbstract(MCD_POT).drip();

        JugAbstract(MCD_JUG).drip("ETH-A");

        JugAbstract(MCD_JUG).drip("BAT-A");

        JugAbstract(MCD_JUG).drip("USDC-A");

        JugAbstract(MCD_JUG).drip("WBTC-A");



        // MCD Risk Parameter Modifications



        // Set the USDC-A stability fee to 1%

        // https://vote.makerdao.com/polling-proposal/qmfhclbxzjypk4aatyvwqthtuqr5842xnrytj8q89ajb6z

        // Existing Rate: 0%

        // New Rate: 1%

        uint256 USDC_FEE = ONE_PCT_RATE;

        JugAbstract(MCD_JUG).file("USDC-A", "duty", USDC_FEE);

    }

}



contract DssSpell {



    DSPauseAbstract  public pause =

        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);

    address          public action;

    bytes32          public tag;

    uint256          public eta;

    bytes            public sig;

    uint256          public expiration;

    bool             public done;



    constructor() public {

        sig = abi.encodeWithSignature("execute()");

        action = address(new SpellAction());

        bytes32 _tag;

        address _action = action;

        assembly { _tag := extcodehash(_action) }

        tag = _tag;

        expiration = now + 30 days;

    }



    function description() public view returns (string memory) {

        return SpellAction(action).description();

    }



    function schedule() public {

        require(now <= expiration, "This contract has expired");

        require(eta == 0, "This spell has already been scheduled");

        eta = now + DSPauseAbstract(pause).delay();

        pause.plot(action, tag, sig, eta);

    }



    function cast() public {

        require(!done, "spell-already-cast");

        done = true;

        pause.exec(action, tag, sig, eta);

    }

}