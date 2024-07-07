// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {UniswapV2Pair} from "./UniswapV2Pair.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";

error IdenticalAddresses();
error ZeroAddress();
error PairExists();

contract UniswapV2Factory {
    mapping(address => mapping(address => address)) public pairs;
    address[] public allPairs;

    event PairCreated(address indexed token0, address token1, address pair, uint256);

    function createPair(address tokenA, address tokenB) public returns (address pair){

        if (tokenA == tokenB) revert IdenticalAddresses();

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        if (token0 == address(0)) revert ZeroAddress();

        if (pairs[token0][token1] != address(0)) revert PairExists();

        //get creation bytecide of UniswapV2Pair, it includes:
        // constructor logic, responsible for smart contract initialization and deployment, NOT stored on the blockchain
        // runtime bytecode, which is actual business logic of contract, it's this bytecode thats store on the blockchain
        bytes memory bytecode = type(UniswapV2Pair).creationCode; 
        bytes32 salt = keccak256(abi.encodePacked(token0, token1)); //sequence of bytes thats used to generate new contract's address deterministically
        assembly {
            //create a new address deterministically using bytecode + salt
            //deploy a new UniswapV2Pair contract
            //get that pair's address
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IUniswapV2Pair(pair).initialize(token0, token1);

        pairs[token0][token1] = pair;
        pairs[token1][token0] = pair;

        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);

    }
}