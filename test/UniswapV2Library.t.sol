// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Test, console} from "forge-std/Test.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {UniswapV2Pair} from "../src/UniswapV2Pair.sol";
import {ERC20Mintable} from "./mocks/ERC20Mintable.sol";
import {UniswapV2Library} from "../src/libraries/UniswapV2Library.sol";


contract UniswapV2LibraryTest is Test {
    UniswapV2Factory factory;

    ERC20Mintable tokenA;
    ERC20Mintable tokenB;

    UniswapV2Pair pair;

    function setUp() public {
        factory = new UniswapV2Factory();

        tokenA = new ERC20Mintable("TokenA", "A");
        tokenB = new ERC20Mintable("TokenB", "B");

        tokenA.mint(10 ether, address(this));
        tokenB.mint(10 ether, address(this));

        address pairAddress = factory.createPair(address(tokenA), address(tokenB));

        pair = UniswapV2Pair(pairAddress);
    }

    function test_GetRerserves() public {
        tokenA.transfer(address(pair), 1.1 ether);
        tokenB.transfer(address(pair), 0.8 ether);

        UniswapV2Pair(address(pair)).mint(address(this));

        (uint256 reserve0, uint256 reserve1) = UniswapV2Library.getReserves(address(factory), address(tokenA), address(tokenB));

        assertEq(reserve0, 1.1 ether);
        assertEq(reserve1, 0.8 ether);
    }
}