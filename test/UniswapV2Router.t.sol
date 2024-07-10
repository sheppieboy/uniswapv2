// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Test, console} from "forge-std/Test.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {ERC20Mintable} from "./mocks/ERC20Mintable.sol";
import {UniswapV2Router} from "../src/UniswapV2Router.sol";
import {UniswapV2Pair} from "../src/UniswapV2Pair.sol";
import {UniswapV2Library} from "../src/UniswapV2Library.sol";

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

    function encodeError(string memory error) internal pure returns(bytes memory encoded){
        encoded = abi.encodeWithSignature(error);
    }

    function test_setUpIsCorrect() public view {
        assertEq(tokenA.balanceOf(address(this)), 20 ether);
        assertEq(tokenB.balanceOf(address(this)), 20 ether);
        assertEq(tokenA.name(), "Token A");
        assertEq(tokenB.name(), "Token B");
        assertEq(tokenA.symbol(), "A");
        assertEq(tokenB.symbol(), "B");
    }

    function test_AddLiquidity_CreatesPair() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        router.addLiquidity(address(tokenA), address(tokenB), 1 ether, 1 ether, 1 ether, 1 ether, address(this));

        address pairAddress = factory.pairs(address(tokenA), address(tokenB));

        assertEq(pairAddress, 0x01495e9E70884f8bBFb75344d15d91C6b69f2476);
    }


    function test_AddLiquidity_NoPair() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(address(tokenA), address(tokenB), 1 ether, 1 ether, 1 ether, 1 ether, address(this));

        assertEq(amountA, 1 ether);
        assertEq(amountB, 1 ether);
        assertEq(liquidity, 1 ether - 1000);

        address pairAddress = factory.pairs(address(tokenA), address(tokenB));

        assertEq(tokenA.balanceOf(pairAddress), 1 ether);
        assertEq(tokenB.balanceOf(pairAddress), 1 ether);


        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenB));
        assertEq(pair.token1(), address(tokenA));
        assertEq(pair.totalSupply(), 1 ether);
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);

        assertEq(tokenA.balanceOf(address(this)), 19 ether);
        assertEq(tokenB.balanceOf(address(this)), 19 ether);
    }

    function test_AddLiquidity_AmountBOptimalIsOk() public {
        address pairAddress = factory.createPair(address(tokenA), address(tokenB));

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenB));
        assertEq(pair.token1(), address(tokenA));

        // add initial liquidity to pair contract
        tokenA.transfer(pairAddress, 1 ether);
        tokenB.transfer(pairAddress, 2 ether);
        pair.mint(address(this));

        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 2 ether);


        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(address(tokenA), address(tokenB), 1 ether, 2 ether, 1 ether, 1.9 ether, address(this));

        assertEq(amountA, 1 ether);
        assertEq(amountB, 2 ether);

        assertEq(liquidity,  1414213562373095048);
    }

    function test_RevertsWhen_AddLiquidity_AmountBOptimalIsTooLow() public {
        address pairAddress = factory.createPair(address(tokenA), address(tokenB));

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenB));
        assertEq(pair.token1(), address(tokenA));

        // add initial liquidity to pair contract
        tokenA.transfer(pairAddress, 5 ether);
        tokenB.transfer(pairAddress, 10 ether);
        pair.mint(address(this));

        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 2 ether);

        vm.expectRevert(encodeError("InsufficientBAmount()"));
        router.addLiquidity(address(tokenA), address(tokenB), 1 ether, 2 ether, 1 ether, 2 ether, address(this));
    }

    function test_AddLiquidity_AmountBOptimalIsTooHighAmountATooLow() public {
        address pairAddress = factory.createPair(address(tokenA), address(tokenB));

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenB));
        assertEq(pair.token1(), address(tokenA));

        // add initial liquidity to pair contract
        tokenA.transfer(pairAddress, 10 ether);
        tokenB.transfer(pairAddress, 5 ether);
        pair.mint(address(this));

        tokenA.approve(address(router), 2 ether);
        tokenB.approve(address(router), 1 ether);
        
        vm.expectRevert(encodeError("InsufficientAAmount()"));
        router.addLiquidity(address(tokenA), address(tokenB), 2 ether, 0.9 ether, 1.8 ether, 1 ether, address(this));
        
    }

    function test_AddLiquidity_AmountBOptimalIsTooHighButAIsOk() public {
        address pairAddress = factory.createPair(address(tokenA), address(tokenB));

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenB));
        assertEq(pair.token1(), address(tokenA));

        // add initial liquidity to pair contract
        tokenA.transfer(pairAddress, 10 ether);
        tokenB.transfer(pairAddress, 5 ether);
        pair.mint(address(this));

        tokenA.approve(address(router), 2 ether);
        tokenB.approve(address(router), 1 ether);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(address(tokenA), address(tokenB), 2 ether, 0.9 ether, 1.7 ether, 1 ether, address(this));
        
        assertEq(amountA, 1.8 ether);
        assertEq(amountB, 0.9 ether);
        assertEq(liquidity, 1272792206135785543);

    }


    function test_RemoveLiquidity() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);
        router.addLiquidity(address(tokenA), address(tokenB), 1 ether, 1 ether, 1 ether, 1 ether, address(this));

        address pairAddress = factory.pairs(address(tokenA), address(tokenB));
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        uint256 liquidity = pair.balanceOf(address(this));

        pair.approve(address(router), liquidity);

        router.removeLiquidity(address(tokenA), address(tokenB), liquidity, 1 ether - 1000, 1 ether - 1000, address(this));

        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        assertEq(reserve0, 1000);
        assertEq(reserve1, 1000);
        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.totalSupply(), 1000);
        assertEq(tokenA.balanceOf(address(this)), 20 ether - 1000);
        assertEq(tokenB.balanceOf(address(this)), 20 ether - 1000);

    }

    function test_RemovePartialLiquidity() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);
        router.addLiquidity(address(tokenA), address(tokenB), 1 ether, 1 ether, 1 ether, 1 ether, address(this));
        address pairAddress = factory.pairs(address(tokenA), address(tokenB));
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        uint256 liquidity = pair.balanceOf(address(this));

        uint256 partialLiquidity = (liquidity * 3)/ 10; //i.e. 30% of liquidity is removed

        pair.approve(address(router), partialLiquidity);

        router.removeLiquidity(address(tokenA), address(tokenB), partialLiquidity, 0.3 ether - 300, 0.3 ether - 300, address(this));

        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        assertEq(reserve0, 0.7 ether + 300);
        assertEq(reserve1, 0.7 ether + 300);
        assertEq(pair.balanceOf(address(this)), 0.7 ether - 700);
        assertEq(pair.totalSupply(), 0.7 ether + 300);
        assertEq(tokenA.balanceOf(address(this)), 20 ether - 0.7 ether - 300);
        assertEq(tokenB.balanceOf(address(this)), 20 ether - 0.7 ether - 300);
    }

}