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
    TestInteractiveContract testInteractiveContract;

    function setUp() public {
        testInteractiveContract = new TestInteractiveContract();

        token0 = new ERC20Mintable("Token A", "A");
        token1 = new ERC20Mintable("Token B", "B");

        pair = new UniswapV2Pair(address(token0), address(token1));

        //mint tokens to this contract
        token0.mint(10 ether, address(this));
        token1.mint(10 ether, address(this));

        //mint to test interactive contract
        token0.mint(10 ether, address(testInteractiveContract));
        token1.mint(10 ether, address(testInteractiveContract));
    }

    function encodeError(string memory error) internal pure returns(bytes memory encoded){
        encoded = abi.encodeWithSignature(error);
    }

    function encodeError(string memory error, uint256 a) internal pure returns(bytes memory encoded){
         encoded = abi.encodeWithSignature(error, a);
    }

    function assertReserves(uint112 expectedReserve0, uint112 expectedReserve1) internal {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        assertEq(reserve0, expectedReserve0, "unexpected reserve0");
        assertEq(reserve1, expectedReserve1, "unexpected reserve1");
    }

    function assertCumulativePrices(uint256 expectedPrice0, uint256 expectedPrice1) internal {
        assertEq(pair.price0CumulativeLast(), expectedPrice0, "unexpected cumulative price 0");
        assertEq(pair.price1CumulativeLast(), expectedPrice1, "unexpected cumulative price 1");
    }

}

contract TestInteractiveContract{

    function addLiquidity(address _pairAddress, address _token0, address _token1, uint256 amount0, uint256 amount1) public {
        ERC20(_token0).transfer(_pairAddress, amount0);
        ERC20(_token1).transfer(_pairAddress, amount1);

        UniswapV2Pair(_pairAddress).mint(address(this));
    }

    function removeLiquidity(address _pairAddress) public {
        UniswapV2Pair(_pairAddress).burn();
    }
}