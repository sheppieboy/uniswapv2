// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";

contract UniswapV2Router {
    IUniswapV2Factory factory;

    constructor(address factoryAddress) {
        factory = IUniswapV2Factory(factoryAddress);
    }


    function addLiquidity(
        address tokenA, 
        address tokenB,
        //amounts we want to deposit into the pair, its an upper bound
        uint256 amountADesired, 
        uint256 amountBDesired,
        //min amounts we want to deposit, Pair contract always issues smaller amounts of LP tokens when we deposit unbalance liquidity
        // so min params all us to control how much liquidity we're ready to lose
        uint256 amountAMin,
        uint256 amountBMin,
        //address to is the address that recieves the LP tokens
        address to) 
        public returns (uint256 amountA, uint256 amountB, uint256 liquidity){
            
            if (factory.pairs(tokenA, tokenB) == address(0)) {
                factory.createPair(tokenA, tokenB);
            }

            (amountA, amountB) = _calculateLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);

            address pairAddress = UniswapV2Library.pairFor(address(factory), tokenA, tokenB);

            _safeTransferFrom(tokenA, msg.sender, pairAddress, amountA);
            _safeTransferFrom(tokenB, msg.sender, pairAddress, amountB);
            liquidity = IUniswapV2Pair(pairAddress).mint(to);
        }
}