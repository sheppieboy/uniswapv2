

library UniswapV2Library {

    function getReserves(address factoryAddress, address tokenA, address tokenB) public returns (uint256 reserveA, uint256 reserveB) {
        //sort token addresses
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        //get reserves
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factoryAddress, token0, token1)).getReserves();
        //set correct reserves and return them
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve1);
    }
}