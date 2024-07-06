// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mintable} from "./mocks/ERC20Mintable.sol";
import {UniswapV2Pair} from "../src/UniswapV2Pair.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";

contract UniswapV2PairTest is Test{
    ERC20Mintable token0;
    ERC20Mintable token1;

    UniswapV2Pair pair;

    function setUp() public {
        token0 = new ERC20Mintable("Token A", "A");
        token1 = new ERC20Mintable("Token B", "B");
        pair = new UniswapV2Pair(address(token0), address(token1));

        // token0.mint(10 ether);
        // token1.mint(10 ether);
    }
}

contract TestContractiveContract{

    function addLiquidity(address _pairAddress, address _token0, address _token1, uint256 amount0, uint256 amount1) public {
        ERC20(_token0).transfer(_pairAddress, amount0);
        ERC20(_token1).transfer(_pairAddress, amount1);

        UniswapV2Pair(_pairAddress).mint();
    }

    function removeLiquidity(address _pairAddress) public {
        UniswapV2Pair(_pairAddress).burn();
    }
}