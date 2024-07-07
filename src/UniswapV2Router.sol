// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";

contract UniswapV2Router {
    IUniswapV2Factory factory;

    constructor(address factoryAddress) {
        factory = IUniswapV2Factory(factoryAddress);
    }
}