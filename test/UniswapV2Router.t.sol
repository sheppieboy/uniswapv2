// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Test, console} from "forge-std/Test.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {ERC20Mintable} from "./mocks/ERC20Mintable.sol";
import {UniswapV2Router} from "../src/UniswapV2Router.sol";
import {UniswapV2Pair} from "../src/UniswapV2Pair.sol";
import {UniswapV2Library} from "../src/libraries/UniswapV2Library.sol";

contract UniswapV2RouterTest is Test{
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

    function test_setUpIsCorrect() public view {
        assertEq(tokenA.balanceOf(address(this)), 20 ether);
        assertEq(tokenB.balanceOf(address(this)), 20 ether);
        assertEq(tokenA.name(), "Token A");
        assertEq(tokenB.name(), "Token B");
        assertEq(tokenA.symbol(), "A");
        assertEq(tokenB.symbol(), "B");
    }

    function test_AddLiquidityCreatesPair() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        router.addLiquidity(address(tokenA), address(tokenB), 1 ether, 1 ether, 1 ether, 1 ether, address(this));

        address pairAddress = factory.pairs(address(tokenA), address(tokenB));

        assertEq(pairAddress, 0x201Ee9eFA76c019ba536A9DFF26f273cA811b162);
    }



}