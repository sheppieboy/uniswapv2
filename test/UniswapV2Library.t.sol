// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Test, console} from "forge-std/Test.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {UniswapV2Pair} from "../src/UniswapV2Pair.sol";
import {ERC20Mintable} from "./mocks/ERC20Mintable.sol";


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
}