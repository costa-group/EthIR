ETHIR
=====


A framework for high-level Analysis of Ethereum Bytecode.

The tool extends [OYENTE framework](https://github.com/melonproject/oyente) to build the CFG of EVM programs analyzed and builds a Rule-based representation. This high-level representation can be injected in other resource static analayzers. 

## Installation
1. Install Solidity compiler (last version tested 0.4.19)
```
 sudo add-apt-repository ppa:ethereum/ethereum
 sudo apt-get update
 sudo apt-get install solc
```

2. Install Ethereum (last version tested 1.7.3)
```
 sudo apt-get install software-properties-common
 sudo add-apt-repository -y ppa:ethereum/ethereum
 sudo apt-get update
 sudo apt-get install ethereum
```

3. Install [Z3](https://github.com/Z3Prover/z3/releases) (last version tested 4.5.0)

   Download the [source code folder](https://github.com/Z3Prover/z3/releases/tag/z3-4.5.0).

   Decompress the folder and install it.
```
 cd z3-z3-4.5.0
 python scripts/mk_make.py --python
 cd build
 make
 sudo make install
```
## Run ETHIR
To run our framework go inside XXX folder and execute the command:
```
.\oyente-ethir -s file_name 
```

## Examples
The folder "Exampes" contains some running examples to test the tool.
Some of the solidity files such as bloccking, advertisement, validToken or cryptoPhoenix are real-world scripts and smallExample, sum or voting are ad-hoc examples where is easier to undestand the decompilation.

