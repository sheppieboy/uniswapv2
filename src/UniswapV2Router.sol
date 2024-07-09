// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {UniswapV2Library} from "./UniswapV2Library.sol";

error InsufficientBAmount();
error InsufficientAAmount();
error SafeTransferFailed();
error InsufficientOutputAmount();
error ExcessiveInputAmount();

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

        function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to) public returns (uint256 amountA, uint256 amountB){
            address pairAddress = UniswapV2Library.pairFor(address(factory), tokenA, tokenB);

            IUniswapV2Pair(pairAddress).transferFrom(msg.sender, pairAddress, liquidity);
            (amountA, amountB) = IUniswapV2Pair(pairAddress).burn(to);

            if (amountA < amountAMin) revert InsufficientAAmount();
            if (amountB < amountBMin) revert InsufficientBAmount();
        }

        //when we have an exact amount of tokens and want to get some, calculated, amount in exchange, it makes chained swaps along the specified path
        //which is a sequence of token addresses, the final amount is sent to address to

        //the path parameter might seem complex, but it's just an array of token addresses
        //If we want to swap Token A for Token B directly, the path will only contain Token A and Token B addresses
        //If we want to swap Token A for Token C via Token B, the path will contain: Token A address, Token B address, Token C address, the contract would swap Token A for Token B
        //and then Token B for Token C
        function swapExactTokensFor(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to) public returns (uint256[] memory amounts){
            //this function simply extracts pairs of tokens from the path (e.g. [[tokenA, tokenB], [tokenB, tokenC]]) and then iteratively calls getAmountOut for each of them to
            //to build an array of output amounts
            amounts = UniswapV2Library.getAmountsOut(address(factory), amountIn, path);

            //after obtaining output amounts, we can verify the final amount right away
            if(amounts[amounts.length - 1] < amountOutMin) revert InsufficientOutputAmount();

            //contract initializes a swap by sending input tokens to the first pair
            _safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(address(factory), path[0], path[1]), amounts[0]);

            //performns chained swaps
            _swap(amounts, path, to);
        }

        function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to) public returns (uint256[] memory amounts) {
            amounts = UniswapV2Library.getAmountsIn(address(factory), amountOut, path);
            if(amounts[amounts.length - 1] > amountInMax) revert ExcessiveInputAmount();

            _safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(address(factory), path[0], path[1]), amounts[0]);
            
            _swap(amounts, path, to);
        }

        //PRIVATE FUNCTIONS

        function _swap(uint256[] memory amounts, address[] memory path, address _to) private {
            for(uint256 i; i < path.length -1; i++){
                //sort addresses
                (address input, address output) = (path[i], path[i + 1]);
                (address token0, ) = UniswapV2Library.sortTokens(input, output);

                //sorting amounts
                uint256 amountOut = amounts[i + 1];
                (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));

                address to = i < path.length - 2 ? UniswapV2Library.pairFor(address(factory), output, path[i +2]) : _to;

                IUniswapV2Pair(UniswapV2Library.pairFor(address(factory), input, output)).swap(amount0Out, amount1Out, to, "");
            }
        }

        function _calculateLiquidity(
            address tokenA, 
            address tokenB, 
            uint256 amountADesired, 
            uint256 amountBDesired, 
            uint256 amountAMin, 
            uint256 amountBMin
            ) private returns(uint256 amountA, uint256 amountB){
                
                (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(address(factory), tokenA, tokenB);

                //if reserves are empty, this is a new pair, which means the liqudity will define the reserves ratio
                if (reserveA == 0 && reserveB == 0) {
                    (amountA, amountB) = (amountADesired, amountBDesired);
                } else{

                    uint256 amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);

                    if (amountBOptimal <= amountBDesired) {
                        if (amountBOptimal <= amountBMin) revert InsufficientBAmount();
                        (amountA, amountB) = (amountADesired, amountBOptimal);

                    }else {
                        uint256 amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);

                        assert(amountAOptimal <= amountADesired);

                        if(amountAOptimal <= amountAMin) revert InsufficientAAmount();
                        (amountA, amountB) = (amountAOptimal, amountBDesired);
                    }
                }
            }
    
    function _safeTransferFrom(address token, address from, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert SafeTransferFailed();
    }
}