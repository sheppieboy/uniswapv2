

library UniswapV2Library {

    function getReserves(address factoryAddress, address tokenA, address tokenB) public returns (uint256 reserveA, uint256 reserveB) {
        //sort token addresses
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        //get reserves
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factoryAddress, token0, token1)).getReserves();
        //set correct reserves and return them i.e. same order the tokens were provided in
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve1);
    }

    function getPairs(address factoryAddress, address tokenA, address tokenB) internal pure returns(address pairAddress){
        //first step is to sort token addresses
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        //next we build a sequence of bytes that includes:
        // 1. 0xff - first byte helps avoid collisions with CREATE opcode
        // 2. factoryAddress - factory that was used to deploy the pair
        // 3. salt - token addresses sorted by hashed
        // 4. hash of pair contract bytecode - we hash creationCode to get this value

        //then this sequence of bytes gets hashed (keccak256) and converted to address(bytes -> uint256 -> address)

        pairAddress = address(
            uint160(uint256(keccak256(abi.encodePacked(hex"ff", factoryAddress, keccak256(abi.encodePacked(token0, token1)), keccak256(type(UniswapV2Pair).creationCode)))))
        );

    }
}