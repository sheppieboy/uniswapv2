// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {Math} from "./libraries/Math.sol";
import {UQ112x112} from "./libraries/UQ112x112.sol";

interface IERC20 {
    function balanceOf(address) external returns (uint256);
    function transfer(address to, uint256 amount) external;
}

error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error TransferFailed();
error InsufficientOutputAmount();
error InsufficientLiquidity();
error InvalidK();
error BalanceOverflow();

contract UniswapV2Pair is ERC20, Math{
    using UQ112x112 for uint224;

    uint256 constant MINIMUM_LIQUIDITY = 1000;

    address public token0;
    address public token1;

    uint32 private blockTimestampLast;
    uint112 private reserve0;
    uint112 private reserve1;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address to);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Sync(uint256 reserve0, uint256 reserve1);
    event Swap(address indexed from, uint256 amount0Out, uint256 amount1Out, address indexed to);

    constructor(address _token0, address _token1) ERC20("uniswapV2", "UNI", 18) {
        token0 = _token0;
        token1 = _token1;
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to) public {
        if (amount0Out == 0 && amount1Out == 0) revert InsufficientOutputAmount();

        (uint112 _reserve0, uint112 _reserve1,) = getReserves();

        if (amount0Out > _reserve0 || amount1Out > _reserve1) revert InsufficientLiquidity();

        uint256 balance0 = IERC20(token0).balanceOf(address(this)) - amount0Out;
        uint256 balance1 = IERC20(token1).balanceOf(address(this)) - amount1Out;

        if (balance0 * balance1 < uint256(_reserve0) * uint256(_reserve1)) revert InvalidK();

        _update(balance0, balance1, _reserve0, _reserve1);

        if(amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if(amount1Out > 0) _safeTransfer(token1, to, amount1Out);

        emit Swap(msg.sender, amount0Out, amount1Out, to);
    }

    function mint() public {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        uint256 liquidity;

        if (totalSupply == 0){
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        }else{
            liquidity = Math.min(
                (amount0 *totalSupply) / _reserve0,
                (amount1 * totalSupply) / _reserve1
            );
        }

        if (liquidity <= 0) revert InsufficientLiquidityMinted();

        _mint(msg.sender, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1);

        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to) public returns (uint256 amount0, uint256 amount1) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 liquidity = balanceOf[address(this)];

        amount0 = (liquidity * balance0)/totalSupply;
        amount1 = (liquidity * balance1)/totalSupply;

        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();

        _burn(address(this), liquidity);

        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);
        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));


        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();

        _update(balance0, balance1, _reserve0, _reserve1);

        emit Burn(msg.sender, amount0, amount1, to);
    }

    //public view functions
    function getReserves() public view returns (uint112, uint112, uint32){
        return (reserve0, reserve1, blockTimestampLast);
    }

    //private functions

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, value));

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }

    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {

        if(balance0 > type(uint112).max || balance1 > type(uint112).max) revert BalanceOverflow();

        unchecked {
            uint32 timeElapsed = uint32(block.timestamp) - blockTimestampLast;

            if (timeElapsed > 0 && _reserve0 > 0 && _reserve1 > 0){
                price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
                price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
            }
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);

        emit Sync(reserve0, reserve1);
    }
}