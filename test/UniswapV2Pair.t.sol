// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mintable} from "./mocks/ERC20Mintable.sol";
import {UniswapV2Pair} from "../src/UniswapV2Pair.sol";

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