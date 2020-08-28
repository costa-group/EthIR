// hevm: flattened sources of src/2019-11-07_5.5_to_5_and_cap_120M.t.sol
pragma solidity >=0.5.10;

////// lib/ds-exec/src/exec.sol
// exec.sol - base contract used by anything that wants to do "untyped" calls

// Copyright (C) 2017  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity >=0.4.23; */

contract DSExec {
    function tryExec( address target, bytes memory data, uint value)
             internal
             returns (bool ok)
    {
        assembly {
            ok := call(gas, target, value, add(data, 0x20), mload(data), 0, 0)
        }
    }
    function exec( address target, bytes memory data, uint value)
             internal
    {
        if(!tryExec(target, data, value)) {
            revert("ds-exec-call-failed");
        }
    }

    // Convenience aliases
    function exec( address t, bytes memory c )
        internal
    {
        exec(t, c, 0);
    }
    function exec( address t, uint256 v )
        internal
    {
        bytes memory c; exec(t, c, v);
    }
    function tryExec( address t, bytes memory c )
        internal
        returns (bool)
    {
        return tryExec(t, c, 0);
    }
    function tryExec( address t, uint256 v )
        internal
        returns (bool)
    {
        bytes memory c; return tryExec(t, c, v);
    }
}

////// lib/ds-note/src/note.sol
/// note.sol -- the `note' modifier, for logging calls as events

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity >=0.4.23; */

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);

        _;
    }
}

////// src/2019-11-07_5.5_to_5_and_cap_120M.t.sol
// 2019-11-07_5.5_to_5_and_cap_120M.t.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity >=0.5.10; */

/* import "ds-test/test.sol"; */
/* import "ds-exec/exec.sol"; */
/* import "ds-note/note.sol"; */

interface SaiTub {
    function fee() external view returns (uint256);
    function cap() external view returns (uint256);
    function mat() external view returns (uint256);
    function drip() external;
}

interface ERC20 {
    function allowance(address,address) external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address,uint256) external returns (bool);
}

interface DSChief {
    function hat() external view returns (address);
    function GOV() external view returns (address);
    function IOU() external view returns (address);
    function approvals(address) external view returns (uint256);
    function lock(uint wad) external;
    function free(uint wad) external;
    function vote(address[] calldata yays) external returns (bytes32);
    function vote(bytes32 slate) external;
    function lift(address whom) external;
}

contract RaiseCeilingLowerSF is DSExec, DSNote {

    uint256 constant public CAP  = 120000000 * 10 ** 18; // 120,000,000 DAI
    uint256 constant public FEE  = 1000000001547125957863212448;
    address constant public MOM  = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C; // SaiMom

    bool public done;

    function cast() public note {
        require(!done);
        done = true;

        // increase cap to 120,000,000
        exec(MOM, abi.encodeWithSignature("setCap(uint256)", CAP), 0);

        // decrease fee to 5.0
        exec(MOM, abi.encodeWithSignature("setFee(uint256)", FEE), 0);

    }
}