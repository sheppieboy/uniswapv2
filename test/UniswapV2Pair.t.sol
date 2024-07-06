// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mintable} from "./mocks/ERC20Mintable.sol";
import {UniswapV2Pair} from "../src/UniswapV2Pair.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {UQ112x112} from "../src/libraries/UQ112x112.sol";

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

    function assertReserves(uint112 expectedReserve0, uint112 expectedReserve1) internal view {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        assertEq(reserve0, expectedReserve0, "unexpected reserve0");
        assertEq(reserve1, expectedReserve1, "unexpected reserve1");
    }

    function assertCumulativePrices(uint256 expectedPrice0, uint256 expectedPrice1) internal view{
        assertEq(pair.price0CumulativeLast(), expectedPrice0, "unexpected cumulative price 0");
        assertEq(pair.price1CumulativeLast(), expectedPrice1, "unexpected cumulative price 1");
    }

    function assertBlockTimestampLast(uint32 expected) internal view {
        (,, uint32 blockTimestampLast) = pair.getReserves();
        assertEq(blockTimestampLast, expected, "unexpected blockTimestampLast");
    }

    function calculativeCurrentPrice() internal view returns(uint256 price0, uint256 price1){
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        price0 = reserve0 > 0 ? (reserve1 * uint256(UQ112x112.Q112))/reserve0 : 0;
        price1 = reserve1 > 0 ? (reserve0 * uint256(UQ112x112.Q112))/reserve1 : 0;
    }

    function test_MintNoLiquidityAddedYet() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint(address(this));

        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);
        assertEq(pair.totalSupply(), 1 ether);
    }

    function test_RevertWhen_MintLiquidityUnderflow() public {
        vm.expectRevert(encodeError("Panic(uint256)", 0x11));
        pair.mint(address(this));
    }

    function test_RevertWhen_MintZeroLiquidity() public {
        token0.transfer(address(pair), 1000); //this is min liq amount
        token1.transfer(address(pair), 1000);

        vm.expectRevert(encodeError("InsufficientLiquidityMinted()"));
        pair.mint(address(this));
    }

    function test_MintWhenLiquidityAlreadyAdded() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this)); //LP + 1;

        vm.warp(37);

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 2 ether);

        pair.mint(address(this)); // LP + 2

        assertEq(pair.balanceOf(address(this)), 3 ether - 1000);
        assertEq(pair.totalSupply(), 3 ether);
        assertReserves(3 ether, 3 ether);
    }

    function test_MintDifferingDepositAmounts() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP
        assertEq(pair.balanceOf(address(this)), 2 ether - 1000);
        assertReserves(3 ether, 2 ether);
    }


    function test_SwapBasicScenario() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);
        pair.swap(0, 0.18 ether, address(this));

        assertEq(token0.balanceOf(address(this)), 10 ether - 1 ether - 0.1 ether, "unexpected token0 balance");

        assertEq(token1.balanceOf(address(this)), 10 ether - 2 ether + 0.18 ether);

        assertReserves(1 ether + 0.1 ether, 2 ether - 0.18 ether);
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