// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract UniswapV2Router {
    IUniswapV2Factory factory;

    constructor(address factoryAddress) {
        factory = IUniswapV2Factory(factoryAddress);
    }
}