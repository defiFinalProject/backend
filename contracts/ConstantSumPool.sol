// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ConstantSumPool {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public balanceA;
    uint256 public balanceB;

    uint256 public feePercentage = 300;  // 0.3% 手续费（单位：万分比）
    mapping(address => uint256) public liquidityShares;

    event Swap(address indexed user, address indexed fromToken, address indexed toToken, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function getTokenBalance(address token) public view returns (uint256) {
        if (token == address(tokenA)) return balanceA;
        if (token == address(tokenB)) return balanceB;
        revert("Invalid token");
    }

    function getFee(uint256 amountOut) public view returns (uint256) {
        return (amountOut * feePercentage) / 10000;
    }

    function getAmountOut(uint256 amountIn, address fromToken, address toToken) public view returns (uint256) {
        require(fromToken != toToken, "Tokens must be different");

        uint256 toBalance = getTokenBalance(toToken);
        require(toBalance >= amountIn, "Insufficient liquidity");

        return amountIn; // 1:1 constant sum
    }

    function getActualAmountOut(uint256 amountOut) public view returns (uint256) {
        uint256 fee = getFee(amountOut);
        return amountOut - fee;
    }

    function swap(address fromToken, address toToken, uint256 amountIn) external {
        require(amountIn > 0, "Amount must be greater than 0");
        require(fromToken != toToken, "Tokens must be different");

        uint256 amountOut = getAmountOut(amountIn, fromToken, toToken);
        uint256 fee = getFee(amountOut);
        uint256 amountAfterFee = amountOut - fee;

        IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn);
        IERC20(toToken).transfer(msg.sender, amountAfterFee);

        // 更新池子余额
        if (fromToken == address(tokenA)) balanceA += amountIn;
        else if (fromToken == address(tokenB)) balanceB += amountIn;

        if (toToken == address(tokenA)) balanceA -= amountAfterFee;
        else if (toToken == address(tokenB)) balanceB -= amountAfterFee;

        emit Swap(msg.sender, fromToken, toToken, amountIn, amountOut);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        balanceA += amountA;
        balanceB += amountB;

        uint256 totalSupplied = amountA + amountB;
        uint256 totalBalance = balanceA + balanceB;

        liquidityShares[msg.sender] += (totalSupplied * 1e18) / totalBalance;
    }

    function removeLiquidity(uint256 shareAmount) external {
        require(liquidityShares[msg.sender] >= shareAmount, "Not enough shares");

        uint256 totalLiquidity = balanceA + balanceB;

        uint256 amountA = (balanceA * shareAmount) / totalLiquidity;
        uint256 amountB = (balanceB * shareAmount) / totalLiquidity;

        liquidityShares[msg.sender] -= shareAmount;
        balanceA -= amountA;
        balanceB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
    }
}