// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {UniswapV2Library} from "./libraries/UniswapV2Library.sol";

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


        function _calculateLiquidity(
            address tokenA, 
            address tokenB, uint256 amountADesired, 
            uint256 amountBDesired, 
            uint256 amountAMin, 
            uint256 amountBMin
            ) internal pure returns(uint256 amountA, uint256 amountB){
                
                (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(address(factory), tokenA, tokenB);

                //if reserves are empty, this is a new pair, which means the liqudity will define the reserves ratio
                if (reserveA == 0 && reserveB == 0) {
                    (amountA, amountB) = (amountADesired, amountADesired);
                } 
                //not new pair
                else{

                    uint256 amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);

                    if (amountBOptimal <= amountBDesired) {
                        if (amountBOptimal <= amountBMin) revert InsufficientBAmount();
                        (amountA, amountB) = (amountADesired, amountBOptimal);

                    }else {
                        uint256 amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);

                        assert(amountAOptimal <= amountADesired);

                        if(amountAOptimal <= amountAMin) revert InsufficientAMount();
                        (amountA, amountB) = (amountAOptimal, amountBDesired);
                    }
                }
            }
    
    function _safeTransferFrom(address token, address from, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)"));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert SafeTransferFailed();
    }
}