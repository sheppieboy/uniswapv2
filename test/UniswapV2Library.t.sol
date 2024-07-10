// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Test, console} from "forge-std/Test.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {UniswapV2Pair} from "../src/UniswapV2Pair.sol";
import {ERC20Mintable} from "./mocks/ERC20Mintable.sol";
import {UniswapV2Library} from "../src/UniswapV2Library.sol";


contract UniswapV2LibraryTest is Test {
    UniswapV2Factory factory;

    ERC20Mintable tokenA;
    ERC20Mintable tokenB;
    ERC20Mintable tokenC;
    ERC20Mintable tokenD;

    UniswapV2Pair pair;
    UniswapV2Pair pair2;
    UniswapV2Pair pair3;

    function setUp() public {
        factory = new UniswapV2Factory();

        tokenA = new ERC20Mintable("TokenA", "A");
        tokenB = new ERC20Mintable("TokenB", "B");
        tokenC = new ERC20Mintable("TokenC", "C");
        tokenD = new ERC20Mintable("TokenD", "D");

        tokenA.mint(10 ether, address(this));
        tokenB.mint(10 ether, address(this));
        tokenC.mint(10 ether, address(this));
        tokenD.mint(10 ether, address(this));

        address pairAddress = factory.createPair(address(tokenA), address(tokenB));

        pair = UniswapV2Pair(pairAddress);

        pairAddress = factory.createPair(address(tokenB), address(tokenC));
        
        pair2 = UniswapV2Pair(pairAddress);

        pairAddress = factory.createPair(address(tokenC), address(tokenD));

        pair3 = UniswapV2Pair(pairAddress);
    }

    function encodeError(string memory error) internal pure returns (bytes memory encoded){
        encoded = abi.encodeWithSignature(error);
    }

    function test_GetRerserves() public {
        tokenA.transfer(address(pair), 1.1 ether);
        tokenB.transfer(address(pair), 0.8 ether);

        UniswapV2Pair(address(pair)).mint(address(this));

        (uint256 reserve0, uint256 reserve1) = UniswapV2Library.getReserves(address(factory), address(tokenA), address(tokenB));

        assertEq(reserve0, 1.1 ether);
        assertEq(reserve1, 0.8 ether);
    }

    function test_PairFor() public view {
        address pairAddress = UniswapV2Library.pairFor(address(factory), address(tokenA), address(tokenB));
        assertEq(pairAddress, factory.pairs(address(tokenA), address(tokenB)));
    }

    function test_PairForTokensSorting() public view {
        address pairAddress = UniswapV2Library.pairFor(address(factory), address(tokenB), address(tokenA));
        assertEq(pairAddress, factory.pairs(address(tokenA), address(tokenB)));
        assertEq(pairAddress, address(pair));
    }

    function test_PairForNonExistentFactory() public view {
        address pairAddress = UniswapV2Library.pairFor(address(0xaabbcc), address(tokenB), address(tokenA));

        assertNotEq(pairAddress, factory.pairs(address(tokenA), address(tokenB)));
    }

    function test_PairForWrongTokenAddress() public view {
        address pairAddress = UniswapV2Library.pairFor(address(factory), address(0xdeadbeef), address(tokenA));
        assertNotEq(pairAddress, address(pair));

        pairAddress = UniswapV2Library.pairFor(address(factory), address(0xdeadbeef), address(tokenB));
        assertNotEq(pairAddress, address(pair));
    }

    function test_Quote() public pure {
        uint256 amountOut = UniswapV2Library.quote(1 ether, 1 ether, 1 ether);
        assertEq(amountOut, 1 ether);

        amountOut = UniswapV2Library.quote(1 ether, 2 ether, 1 ether);
        assertEq(amountOut, 0.5 ether);

        amountOut = UniswapV2Library.quote(1 ether, 1 ether, 2 ether);
        assertEq(amountOut, 2 ether);
    }

    function test_RevertWhen_QuoteAmountInZero() public {
        vm.expectRevert(encodeError("InsufficientAmount()"));
        UniswapV2Library.quote(0, 1 ether, 1 ether);
    }

    function test_RevertWhen_QuoteRerserveInIsZero() public {
        vm.expectRevert(encodeError("InsufficientLiquidity()"));
        UniswapV2Library.quote(1 ether, 0 ether, 1 ether);
    }

    function test_RevertWhen_QuoteRerserveOutIsZero() public {
        vm.expectRevert(encodeError("InsufficientLiquidity()"));
        UniswapV2Library.quote(1 ether, 1 ether, 0 ether);
    }

    function test_GetAmountOut() public pure {
        uint256 amountOut = UniswapV2Library.getAmountOut(1000, 1 ether, 1.5 ether);
        assertEq(amountOut, 1495);
    }

    function test_RevertWhen_GetOutAmountWithZeroInput() public {
        vm.expectRevert(encodeError("InsufficientAmount()"));
        UniswapV2Library.getAmountOut(0, 1.5 ether, 1.5 ether);
    }

    function test_RevertWhen_GetOutAmountWithZeroReserveIn() public {
        vm.expectRevert(encodeError("InsufficientLiquidity()"));
        UniswapV2Library.getAmountOut(1000, 0 ether, 1.5 ether);
    }

    function test_RevertWhen_GetOutAmountWithZeroReserveOut() public {
        vm.expectRevert(encodeError("InsufficientLiquidity()"));
        UniswapV2Library.getAmountOut(1000, 1.5 ether, 0 ether);
    }

    function test_GetAmountsOut() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 2 ether);
        pair.mint(address(this));


        tokenB.transfer(address(pair2), 1 ether);
        tokenC.transfer(address(pair2), 0.5 ether);
        pair2.mint(address(this));

        tokenC.transfer(address(pair3), 1 ether);
        tokenD.transfer(address(pair3), 2 ether);
        pair3.mint(address(this));

        address[] memory path = new address[](4);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);
        path[3] = address(tokenD);

        uint256[] memory amounts = UniswapV2Library.getAmountsOut(address(factory), 0.1 ether, path);

        assertEq(amounts.length, 4);
        assertEq(amounts[0], 0.1 ether);
        assertEq(amounts[1], 0.181322178776029826 ether);
        assertEq(amounts[2], 0.076550452221167502 ether);
        assertEq(amounts[3], 0.141817942760565270 ether);
    }

    function test_RevertWhen_GetAmountsOutInvalidPath() public {
        address[] memory path = new address[](1);
        path[0] = address(tokenA);

        vm.expectRevert(encodeError("InvalidPath()"));
        UniswapV2Library.getAmountsOut(address(factory), 0.1 ether, path);
    }

    function test_GetAmountIn() public pure {
        uint256 amountIn = UniswapV2Library.getAmountIn(1495, 1 ether, 1.5 ether);
        assertEq(amountIn, 1000);
    }

    function test_RevertWhen_GetAmountInWithZeroInput() public {
        vm.expectRevert(encodeError("InsufficientAmount()"));
        UniswapV2Library.getAmountIn(0, 1.5 ether, 1.5 ether);
    }

    function test_RevertWhen_GetAmountInWithZeroReserveIn() public {
        vm.expectRevert(encodeError("InsufficientLiquidity()"));
        UniswapV2Library.getAmountIn(1000, 0 ether, 1.5 ether);
    }

    function test_RevertWhen_GetAmountIntWithZeroReserveOut() public {
        vm.expectRevert(encodeError("InsufficientLiquidity()"));
        UniswapV2Library.getAmountIn(1000, 1.5 ether, 0 ether);
    }

    function test_GetAmountsIn() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 2 ether);
        pair.mint(address(this));


        tokenB.transfer(address(pair2), 1 ether);
        tokenC.transfer(address(pair2), 0.5 ether);
        pair2.mint(address(this));

        tokenC.transfer(address(pair3), 1 ether);
        tokenD.transfer(address(pair3), 2 ether);
        pair3.mint(address(this));

        address[] memory path = new address[](4);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);
        path[3] = address(tokenD);

        uint256[] memory amounts = UniswapV2Library.getAmountsIn(address(factory), 0.1 ether, path);
        
        assertEq(amounts.length, 4);
        assertEq(amounts[0], 0.063113405152841847 ether);
        assertEq(amounts[1], 0.118398043685444580 ether);
        assertEq(amounts[2], 0.052789948793749671 ether);
        assertEq(amounts[3], 0.100000000000000000 ether);
    }

    function test_RevertWhen_GetAmountsInWithInvalidPath() public {
        address[] memory path = new address[](1);
        path[0] = address(tokenA);

        vm.expectRevert(encodeError("InvalidPath()"));
        UniswapV2Library.getAmountsIn(address(factory), 0.1 ether, path);
    }


}