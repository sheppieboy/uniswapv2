// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Test, console} from "forge-std/Test.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {ERC20Mintable} from "./mocks/ERC20Mintable.sol";
import {UniswapV2Router} from "../src/UniswapV2Router.sol";

contract UniswapV2RouterTest {
    UniswapV2Factory factory;

    UniswapV2Router router;

    ERC20Mintable tokenA;
    ERC20Mintable tokenB;

    function setUp() public {
        factory = new UniswapV2Factory();
        router = new UniswapV2Router(address(factory));

        tokenA = new ERC20Mintable("Token A", "A");
        tokenB = new ERC20Mintable("Token B", "B");

        tokenA.mint(20 ether, address(this));
        tokenB.mint(20 ether, address(this));
    }
}