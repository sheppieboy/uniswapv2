// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint256 amountOut, uint256 amount1Out, bytes calldata data) external;
}