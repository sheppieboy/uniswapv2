// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Test, console} from "forge-std/Test.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {ERC20Mintable} from "./mocks/ERC20Mintable.sol";
import {UniswapV2Pair} from "../src/UniswapV2Pair.sol";


contract UniswapV2FactoryTest is Test {
    UniswapV2Factory factory;

    ERC20Mintable token0;
    ERC20Mintable token1;
    ERC20Mintable token2;
    ERC20Mintable token3;

    function setUp() public {
        factory = new UniswapV2Factory();

        token0 = new ERC20Mintable("TokenA", "A");
        token1 = new ERC20Mintable("TokenB", "B");
        token2 = new ERC20Mintable("TokenC", "C");
        token3 = new ERC20Mintable("Tokend", "D");
    }

    function encodeError(string memory error) internal pure returns (bytes memory encoded){
        encoded = abi.encodeWithSignature(error);
    }

    function test_CreatePair() public {
        address pairAddress = factory.createPair(address(token1), address(token0));

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(token0));
        assertEq(pair.token1(), address(token1));
    }

    function test_RevertWhen_CreatePairWithZeroAddress() public {
        vm.expectRevert(encodeError("ZeroAddress()"));
         factory.createPair(address(0), address(token0));

        vm.expectRevert(encodeError("ZeroAddress()"));
        factory.createPair(address(token1), address(0));
    }

    function test_RevertWhen_CreatePairExists() public {
        factory.createPair(address(token1), address(token0));

        vm.expectRevert(encodeError("PairExists()"));
        factory.createPair(address(token1), address(token0));
    }

    function test_RevertWhen_CreatePairWithIdenticalTokens() public {
        vm.expectRevert(encodeError("IdenticalAddresses()"));
        factory.createPair(address(token1), address(token1));

        vm.expectRevert(encodeError("IdenticalAddresses()"));
        factory.createPair(address(token0), address(token0));
    }
}