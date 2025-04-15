// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ConstantMeanPool {
    // 代币合约的引用
    IERC20 public tokenA;
    IERC20 public tokenB;
    IERC20 public tokenC;

    // 流动性池的余额
    uint256 public balanceA;
    uint256 public balanceB;
    uint256 public balanceC;

    // 权重设置（总和为100）
    uint256 public constant WEIGHT_A = 30; // 30%
    uint256 public constant WEIGHT_B = 30; // 30%
    uint256 public constant WEIGHT_C = 40; // 40%
    uint256 public constant TOTAL_WEIGHT = 100;

    // 手续费百分比（例如，0.3% = 300）
    uint256 public feePercentage = 300;  // 0.3%手续费
    mapping(address => uint256) public liquidityShares; // 用户地址 => 持有份额

    event Swap(address indexed user, address indexed fromToken, address indexed toToken, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB, address _tokenC) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        tokenC = IERC20(_tokenC);
    }

    // 计算恒定均值 k
    function calculateK() public view returns (uint256) {
        // 为了简化计算，我们使用: (balanceA^WEIGHT_A * balanceB^WEIGHT_B * balanceC^WEIGHT_C)
        // 由于Solidity不支持浮点数和指数运算，我们使用对数来简化计算
        uint256 weightedA = balanceA ** WEIGHT_A;
        uint256 weightedB = balanceB ** WEIGHT_B;
        uint256 weightedC = balanceC ** WEIGHT_C;
        
        return weightedA * weightedB * weightedC;
    }

    // 根据 Constant Mean 公式计算兑换的代币数量
    function getAmountOut(uint256 amountIn, address fromToken, address toToken) public view returns (uint256) {
        require(amountIn > 0, "Amount must be greater than 0");
        
        uint256 balanceIn = getTokenBalance(fromToken);
        uint256 balanceOut = getTokenBalance(toToken);
        //uint256 k = calculateK();
        
        // 假设交易只涉及两个代币，第三个代币余额保持不变
        uint256 newBalanceIn = balanceIn + amountIn;
        
        // 根据恒定均值公式求解新的balanceOut
        // (newBalanceIn^w1 * newBalanceOut^w2 * unchangedBalance^w3) = k
        
        uint256 weightIn;
        uint256 weightOut;
        
        if (fromToken == address(tokenA)) {
            weightIn = WEIGHT_A;
        } else if (fromToken == address(tokenB)) {
            weightIn = WEIGHT_B;
        } else {
            weightIn = WEIGHT_C;
        }
        
        if (toToken == address(tokenA)) {
            weightOut = WEIGHT_A;
        } else if (toToken == address(tokenB)) {
            weightOut = WEIGHT_B;
        } else {
            weightOut = WEIGHT_C;
        }

        // 根据权重比例计算输出量
        // newBalanceOut = balanceOut * (balanceIn/newBalanceIn)^(weightIn/weightOut)
        uint256 ratio = (balanceIn * 1e18) / newBalanceIn;
        uint256 weightRatio = (weightIn * 1e18) / weightOut;
        uint256 adjustedRatio = ratio ** weightRatio;
        uint256 newBalanceOut = (balanceOut * adjustedRatio) / 1e18;
        
        return balanceOut - newBalanceOut;
    }

    // 获取池子中某种代币的余额
    function getTokenBalance(address token) public view returns (uint256) {
        if (token == address(tokenA)) {
            return balanceA;
        } else if (token == address(tokenB)) {
            return balanceB;
        } else if (token == address(tokenC)) {
            return balanceC;
        } else {
            return 0;
        }
    }

    // 获取手续费
    function getFee(uint256 amountOut) public view returns (uint256) {
        return (amountOut * feePercentage) / 10000;  // 手续费 = 预计兑换数量 * 手续费百分比
    }

    // 获取实际兑换数量（扣除手续费后的数量）
    function getActualAmountOut(uint256 amountOut) public view returns (uint256) {
        uint256 fee = getFee(amountOut);
        return amountOut - fee;
    }

    // 交换代币，输入数量和手续费自动计算
    function swap(address fromToken, address toToken, uint256 amountIn) external {
        require(amountIn > 0, "Amount must be greater than 0");
        
        uint256 k_before = calculateK();
        uint256 amountOut = getAmountOut(amountIn, fromToken, toToken);
        uint256 fee = getFee(amountOut);
        uint256 amountAfterFee = amountOut - fee;

        // 更新余额
        if (fromToken == address(tokenA)) {
            balanceA += amountIn;
        } else if (fromToken == address(tokenB)) {
            balanceB += amountIn;
        } else {
            balanceC += amountIn;
        }

        if (toToken == address(tokenA)) {
            balanceA -= amountAfterFee;
        } else if (toToken == address(tokenB)) {
            balanceB -= amountAfterFee;
        } else {
            balanceC -= amountAfterFee;
        }

        // 验证k值是否保持不变（考虑误差）
        uint256 k_after = calculateK();
        require(k_after >= k_before * 999/1000, "Constant mean invariant violated");


        // 转移代币
        IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn);
        IERC20(toToken).transfer(msg.sender, amountAfterFee);

        emit Swap(msg.sender, fromToken, toToken, amountIn, amountOut);
    }

    // 添加流动性
    function addLiquidity(uint256 amountA, uint256 amountB, uint256 amountC) external {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        tokenC.transferFrom(msg.sender, address(this), amountC);

        balanceA += amountA;
        balanceB += amountB;
        balanceC += amountC;
        liquidityShares[msg.sender] += amountA+amountB+amountC/balanceA+balanceB+balanceC;
    }

    // 移除流动性
    function removeLiquidity(uint256 shareAmount) external {
        require(liquidityShares[msg.sender] >= shareAmount, "Not enough shares");

        // 计算每个币要返回多少
        uint256 amountA = (balanceA * shareAmount);
        uint256 amountB = (balanceB * shareAmount);
        uint256 amountC = (balanceC * shareAmount);

        // 更新用户和池子的余额
        liquidityShares[msg.sender] -= shareAmount;

        balanceA -= amountA;
        balanceB -= amountB;
        balanceC -= amountC;

        // 转给用户
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
        tokenC.transfer(msg.sender, amountC);
    }
}