// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ConstantSumPool {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public balanceA;
    uint256 public balanceB;

    uint256 public feePercentage = 300; // 0.3% 手续费（单位：万分比）
    mapping(address => uint256) public liquidityShares;
    address[] public providers;

    event Swap(
        address indexed user,
        address indexed fromToken,
        address indexed toToken,
        uint256 amountIn,
        uint256 amountOut
    );

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

    function getAmountOut(
        uint256 amountIn,
        address fromToken,
        address toToken
    ) public view returns (uint256) {
        require(fromToken != toToken, "Tokens must be different");

        uint256 toBalance = getTokenBalance(toToken);
        require(toBalance >= amountIn, "Insufficient liquidity");

        return amountIn; // 1:1 constant sum
    }

    function getAddLiquidityOut(
        uint256 amountIn,
        address Token
    ) public view returns (uint256) {
        if (balanceA == 0 && balanceB == 0) {
            return amountIn;
        } else {
            if (Token == address(tokenA)) {
                return (amountIn * balanceB) / balanceA;
            } else {
                return (amountIn * balanceA) / balanceB;
            }
        }
    }

    function getActualAmountOut(
        uint256 amountOut
    ) public view returns (uint256) {
        uint256 fee = getFee(amountOut);
        return amountOut - fee;
    }

    function getRemoveLiquidityOut(
        uint256 amountIn,
        address Token
    ) public view returns (uint256) {
        uint256 curruntToken = getTokenBalance(Token);
        require(
            amountIn / curruntToken < liquidityShares[msg.sender],
            "you don't have much liquidity share"
        );
        uint256 anotherTokenBalance = getTokenBalance(
            Token == address(tokenA) ? address(tokenB) : address(tokenA)
        );
        return (amountIn * anotherTokenBalance) / curruntToken;
    }

    // function swap(
    //     address fromToken,
    //     address toToken,
    //     uint256 amountIn
    // ) external {
    //     require(amountIn > 0, "Amount must be greater than 0");
    //     require(fromToken != toToken, "Tokens must be different");

    //     uint256 amountOut = getAmountOut(amountIn, fromToken, toToken);
    //     uint256 fee = getFee(amountOut);
    //     // uint256 amountAfterFee = amountOut - fee;
    //     uint256 amountAfterFee = getActualAmountOut(amountOut);

    //     IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn);
    //     IERC20(toToken).transfer(msg.sender, amountAfterFee);

    //     uint256 totalShares = 0;
    //     for (uint i = 0; i < providers.length; i++) {
    //         totalShares += liquidityShares[providers[i]];
    //     }

    //     for (uint i = 0; i < providers.length; i++) {
    //         address provider = providers[i];
    //         uint256 share = liquidityShares[provider];
    //         uint256 providerFee = (fee * share) / totalShares;
    //         IERC20(toToken).transfer(provider, providerFee);
    //     }

    //     // 更新池子余额
    //     if (fromToken == address(tokenA)) balanceA += amountIn;
    //     else if (fromToken == address(tokenB)) balanceB += amountIn;

    //     if (toToken == address(tokenA)) balanceA -= amountOut;
    //     else if (toToken == address(tokenB)) balanceB -= amountOut;

    //     emit Swap(msg.sender, fromToken, toToken, amountIn, amountOut);
    // }
    function swap(
    address fromToken,
    address toToken,
    uint256 amountIn
) external {
    require(amountIn > 0, "Amount must be greater than 0");
    require(fromToken != toToken, "Tokens must be different");

    // 计算原始可获得数量（不扣手续费）
    uint256 amountOut = getAmountOut(amountIn, fromToken, toToken);

    // 计算手续费 & 扣除后的实际获得数量
    uint256 fee = getFee(amountOut);
    uint256 amountAfterFee = amountOut - fee;

    // ✅ Step 1: 用户转入 fromToken
    IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn);

    // ✅ Step 2: 合约给用户转出扣完 fee 的数量
    IERC20(toToken).transfer(msg.sender, amountAfterFee);

    // ✅ Step 3: 将 fee 按比例分发给流动性提供者
    uint256 totalShares = 0;
    for (uint i = 0; i < providers.length; i++) {
        totalShares += liquidityShares[providers[i]];
    }

    for (uint i = 0; i < providers.length; i++) {
        address provider = providers[i];
        uint256 share = liquidityShares[provider];
        uint256 providerFee = (fee * share) / totalShares;
        IERC20(toToken).transfer(provider, providerFee);
    }

    // ✅ Step 4: 更新池子余额（按照实际发出的总量更新）
    if (fromToken == address(tokenA)) balanceA += amountIn;
    else if (fromToken == address(tokenB)) balanceB += amountIn;

    if (toToken == address(tokenA)) balanceA -= (amountAfterFee + fee);
    else if (toToken == address(tokenB)) balanceB -= (amountAfterFee + fee);

    emit Swap(msg.sender, fromToken, toToken, amountIn, amountOut);
}


    function addLiquidity(uint256 amountA, uint256 amountB) external {
         require(amountA > 0 && amountB > 0, "Amounts must be > 0");

    if (liquidityShares[msg.sender] == 0) {
        providers.push(msg.sender);
    }

    tokenA.transferFrom(msg.sender, address(this), amountA);
    tokenB.transferFrom(msg.sender, address(this), amountB);

    uint256 totalSupplied = amountA + amountB;
    uint256 totalBalance = balanceA + balanceB;

    balanceA += amountA;
    balanceB += amountB;

    if (totalBalance == 0) {
        // 第一次添加流动性
        liquidityShares[msg.sender] = totalSupplied * 1e18;
    } else {
        // 后续添加流动性（按照总池比例分配）
        liquidityShares[msg.sender] = (totalSupplied * 1e18) / totalBalance;
    }

    }

    // function removeLiquidity(uint256 amountA, uint256 amountB) external {
    //     uint256 totalLiquidity = balanceA + balanceB;

    //     liquidityShares[msg.sender] = liquidityShares[msg.sender] * totalLiquidity -amountA-amountB/ (totalLiquidity-amountA-amountB);

    //     for (uint i = 0; i < providers.length; i++) {
    //         if (providers[i] != msg.sender) {
    //             address provider = providers[i];
    //             uint256 share = liquidityShares[provider];
    //             liquidityShares[provider] =
    //                 (share * (balanceA + balanceB)) /
    //                 (balanceA + balanceB - amountA - amountB);
    //         }
    //     }

    //     balanceA -= amountA;
    //     balanceB -= amountB;

    //     tokenA.transfer(msg.sender, amountA);
    //     tokenB.transfer(msg.sender, amountB);
    // }
    function removeLiquidity(uint256 amountIn, address tokenIn) external {
    require(amountIn > 0, "Amount must be greater than 0");

    // 确认是有效的 token
    require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid token");

    // 确认用户拥有足够的份额（或直接不校验）
    uint256 tokenOutAmount;

    if (tokenIn == address(tokenA)) {
        require(balanceA >= amountIn, "Insufficient tokenA in pool");
        tokenOutAmount = (amountIn * balanceB) / balanceA;
        require(balanceB >= tokenOutAmount, "Insufficient tokenB in pool");

        balanceA -= amountIn;
        balanceB -= tokenOutAmount;

        tokenA.transfer(msg.sender, amountIn);
        tokenB.transfer(msg.sender, tokenOutAmount);
    } else {
        require(balanceB >= amountIn, "Insufficient tokenB in pool");
        tokenOutAmount = (amountIn * balanceA) / balanceB;
        require(balanceA >= tokenOutAmount, "Insufficient tokenA in pool");

        balanceB -= amountIn;
        balanceA -= tokenOutAmount;

        tokenB.transfer(msg.sender, amountIn);
        tokenA.transfer(msg.sender, tokenOutAmount);
    }

    // 流动性份额缩减：用户的贡献在池子中减少
    uint256 totalLiquidity = balanceA + balanceB + amountIn + tokenOutAmount;
    uint256 removedLiquidity = amountIn + tokenOutAmount;
    liquidityShares[msg.sender] =
        (liquidityShares[msg.sender] * (totalLiquidity - removedLiquidity)) /
        totalLiquidity;
}

}