# SwapBased V2 Core 面试准备（分主题问答）

## 与《学习指南》的关系

- **[LEARNING_GUIDE.md](LEARNING_GUIDE.md)** 提供 **§0 文档说明与章节索引**、分篇导航与流程图；本文件提供 **考点问答** 与 **面试前速查**。
- **使用顺序建议**：先掌握学习指南 **§0.2 章节总览**（知道每章对应下面哪一块），再按 **A→G** 自测；卡壳时回到表中「学习指南」列跳转精读。

### 主题块 ↔ 学习指南章节

| 本文件 | 主题 | 学习指南（精读） | 源码锚点 |
|--------|------|------------------|----------|
| **A** | Uniswap V2 / AMM | **§5** | `UniswapV2Pair`、`UniswapV2Router02` |
| **B** | StakingRewards 积分模型 | **§9**、**§3.2** | `masterchefv2/StakingRewards.sol` |
| **C** | MasterChef / 治理 / 投票 | **§9**、**§3.3～3.4** | `MasterchefV2.sol`、`MasterChefCoin.sol` |
| **D** | Vaults（xBASE / oCOIN） | **§6（速览）**、**§12（详解）** | `vaultsv2/xBASE.sol`、`oCOIN.sol` |
| **E** | 安全与工程 | **§16**、**§14** | 全仓特权面、测试脚手架 |
| **F** | 综合与对比 | **§2～§4**、**§12** | 跨模块 |
| **G** | 面试前 5 分钟速查 | **§0.3**、**§15** | — |

---

## A. Uniswap V2 与 AMM

**对应学习指南**：[LEARNING_GUIDE.md](LEARNING_GUIDE.md) **§5**（Uniswap V2 核心）

### A1. 恒定乘积做市商（CPAMM）核心公式是什么？和「价格」有什么关系？

**考点**：x \cdot y = k 的直觉、储备与价格。

**参考答案要点**：

- 池内两种代币储备量 R_0,R_1 在无手续费理想情况下满足 R_0 \cdot R_1 = k；单笔交易后在新储备下仍满足池子规则（V2 实际还扣手续费，且用恒定乘积公式算输出）。
- 边际价格可近似为 \Delta y / \Delta x 的极限，与储备比有关；大额交易会**滑点**明显。

### A2. `UniswapV2Pair` 里 `lock` 修饰器的作用是什么？

**考点**：重入、swap 流程中回调。

**参考答案要点**：

- `unlocked` 标志在 `swap` / `mint` / `burn` 等路径防止**重入**（例如 `swap` 中若向合约转账触发对侧回调，再次进入会失败）。
- 与 `StakingRewards` 里 `ReentrancyGuard` 目的一致，实现细节不同。

### A3. 闪电贷在 V2 Pair 里如何体现？`IUniswapV2Callee` 做什么？

**考点**：`swap` 的 `data` 与回调。

**参考答案要点**：

- 用户可先被转出代币，再在回调中归还并付手续费；若未满足余额约束则整笔回滚。
- `IUniswapV2Callee.uniswapV2Call` 在 `swap` 流程末尾由 Pair 调用，用于套利或还款逻辑（见接口 `[interfaces/IUniswapV2Callee.sol](interfaces/IUniswapV2Callee.sol)` 与 Pair 实现）。

### A4. `price0CumulativeLast` 有什么用？

**考点**：TWAP、预言机。

**参考答案要点**：

- 利用 `UQ112x112` 与时间差累计价格，供外部做**时间加权平均价格**，比单点现货更难被短期操纵（仍需足够流动性与时间窗口）。

### A5. Router 与 Pair 的分工？

**考点**：用户为何多数时候调 Router。

**参考答案要点**：

- Pair 管核心资产与公式；Router 封装**多跳路径、安全转账、deadline、最小输出**等，降低用户出错成本（见 `[UniswapV2Router02.sol](UniswapV2Router02.sol)`）。

---

## B. StakingRewards（Synthetix 模型）

**对应学习指南**：[LEARNING_GUIDE.md](LEARNING_GUIDE.md) **§9**（Chef + Farm）、**§3.2**（奖励模型直觉）

### B1. `rewardPerToken()` 的数学含义？

**考点**：每秒奖励按总质押量分摊。

**参考答案要点**：

- `rewardRate` 为每秒向整个池子发放的「奖励代币数量」；总质押为 `_totalSupply` 时，**每单位质押代币每秒**摊到 `rewardRate / _totalSupply`，积分进 `rewardPerTokenStored`，并带 `1e18` 精度避免小数截断（见 `[masterchefv2/StakingRewards.sol](masterchefv2/StakingRewards.sol)`）。

### B2. `earned(account)` 为什么需要 `userRewardPerTokenPaid`？

**考点**：债务/积分制，避免每次遍历全用户。

**参考答案要点**：

- 全局只维护 `rewardPerTokenStored`；用户侧记录「上次结算时」的全局值 `userRewardPerTokenPaid`，差额乘以余额即**新增应得**，再加上已缓存的 `rewards[account]`。

### B3. `updateReward` 修饰器做了哪些事？

**考点**：先更新全局再更新用户。

**参考答案要点**：

- 把 `rewardPerTokenStored` 更新到当前时间对应的值，刷新 `lastUpdateTime`，并对 `account` 重算 `rewards` 与 `userRewardPerTokenPaid`。

### B4. 本仓库中 Farm 的「奖励代币」存在哪里？

**考点**：与经典 StakingRewards 的区别。

**参考答案要点**：

- 合约里 `rewardsToken` 类型存在，但**实际发放**在 `getReward` 中通过 `IMasterChef(masterChef).mintRewards` 完成；奖励资产由 MasterChef 配置的多个 `IBaseToken` 铸造，而非单一预充值 ERC20 余额（需结合 `[StakingRewards.sol](masterchefv2/StakingRewards.sol)` 与 `[MasterchefV2.sol](masterchefv2/MasterchefV2.sol)` 理解）。

### B5. `depositFee` 与 `ownerFee` 各是多少？去向？

**考点**：万分比、资金流向。

**参考答案要点**：

- `depositFee = 100` → **1%** 质押量进 `taxWallet`；`ownerFee = 200` → **2%** 的**已计算奖励**在 `getReward` 时额外铸给 `taxWallet`（与 `mintRewards` 调用次数相关，见 `StakingRewards`）。

---

## C. MasterChef 与治理

**对应学习指南**：[LEARNING_GUIDE.md](LEARNING_GUIDE.md) **§9**、**§3.3～3.4**（池子控制与投票）

### C1. 谁可以调用 `mintRewards`？`msg.sender` 为什么是 Farm？

**考点**：防伪造、白名单。

**参考答案要点**：

- `require(isFarm[msg.sender])`，只有注册过的 `stakingFarm` 合约能触发；`poolPidByStakingFarmAddress[msg.sender]` 定位池子配置。

### C2. `ratios` 与 `rewards` 如何配合？分母是多少？

**考点**：多代币奖励拆分。

**参考答案要点**：

- 对传入的 `_amount`（奖励计量），对每个 `i`：`amountToMint = _amount * pool.ratios[i] / 10000`，即 **万分比**；需保证配置合理（面试可讨论「是否必须和为 10000」——源码未强制校验，属**运维/审计点**）。

### C3. `_updatePool` 在算什么？`masterchefControlled` 为 false 时呢？

**考点**：全局速率与单池 `rewardRate` 同步。

**参考答案要点**：

- 对 `masterchefControlled == true` 的池，根据 `globalSkullPerSecond` 与 `allocPoint` 算该池应得每秒奖励，并 `setRewardRate` 到对应 `StakingRewards`；可投票池再加上社区部分。
- 若为 false，该分支不自动同步速率（具体行为需结合部署策略；面试强调**读源码分支**）。

### C4. 投票权 `getTotalVotePower` 包含什么？

**考点**：xBASE 与可选质押。

**参考答案要点**：

- `IERC20(xBASE).balanceOf(user)` 加上 `countDepositAmountAsVotingPower` 为 true 的池子上用户的 `balanceOf`（单币质押量）（见 `[MasterchefV2.sol](masterchefv2/MasterchefV2.sol)`）。

### C5. 为什么 `increaseAllocation` 里每 7 天会 `_massUpdatePools`？

**考点**：gas 与状态一致性。

**参考答案要点**：

- 投票改变 `allocPointCommunity` 前，先全量更新各池 `rewardRate`，减少长期偏差；`lastUpdatedTimeVotes` 记录上次触发时间。

### C6. `MasterChefCoin` 比 `MasterchefV2` 多了什么能力？风险点？

**考点**：特权铸币。

**参考答案要点**：

- `mintRewardsByAddress` 允许 `minters` 对任意配置的 `_token` 调 `mint`；面试应强调**信任模型**：`minters` 列表与 Owner 治理至关重要。

---

## D. Vaults（xBASE / oCOIN）

**对应学习指南**：[LEARNING_GUIDE.md](LEARNING_GUIDE.md) **§12**（Vaults 详解）；速览见 **§6**

### D1. `oCOIN` 中 `instantExit` 大致做什么？

**考点**：惩罚、外部支付、MasterChef。

**参考答案要点**：

- 销毁用户 oCOIN，部分比例通过 WETH `transferFrom` 用户到 `_operator`；同时 `mintRewards` 给用户一定计量（见 `[vaultsv2/oCOIN.sol](vaultsv2/oCOIN.sol)`）。细节以源码为准。

### D2. `remainTime` 里用 `msg.sender` 与 `_address` 混用是否有问题？

**考点**：代码审查敏感度。

**参考答案要点**：

- 当前实现里 `timePass` 用 `_address`，`VestPeriod` 判断用 `msg.sender`，属于**潜在 bug 面**（视图函数与调用者不一致）；面试提到「应通读并质疑视图函数一致性」即可展示审查能力。

---

## E. 安全与工程

**对应学习指南**：[LEARNING_GUIDE.md](LEARNING_GUIDE.md) **§16**（诚实边界）、**§14**（Solidity 与依赖）

### E1. 列举本仓库典型的中心化/特权风险。

**考点**：现实 DeFi 面试必问。

**参考答案要点**：

- Owner：`setGlobalSkullPerSecond`、`setTokensAndRatiosFarm`、`pullExtraTokens`、`killFarm` 等。
- `MasterChefCoin` 的 `minters`。
- `oCOIN` 的 `operator`、价格源切换（V2/V3）等。

### E2. 重入在 `getReward` 路径上为何相对可控？

**考点**：`nonReentrant`、CEI。

**参考答案要点**：

- `getReward` 带 `nonReentrant`；且先 `rewards[msg.sender]=0` 再外部 `mintRewards`（可对照源码顺序）。若代币 `mint` 有回调，仍依赖 `nonReentrant` 与 MasterChef 侧逻辑。

### E3. 本仓库没有 Hardhat/Foundry 配置意味着什么？

**考点**：工程诚实性。

**参考答案要点**：

- 自动化测试与覆盖率需自行搭建；面试可说「会 fork 主网 + 写 Foundry 单测验证关键不变量」。

---

## F. 对比与综合题

**对应学习指南**：[LEARNING_GUIDE.md](LEARNING_GUIDE.md) **§2**（整体架构）、**§12**（Vaults）

### F1. `masterchefv2/StakingRewards` 与 `vaultsv2/SingleStakingRewardsBase` 的共同点？

**参考答案要点**：同为质押积分模型，均依赖 `IMasterChef.mintRewards` 发放；差异在质押资产、税费、工厂部署等细节。

### F2. 若 `ratios` 总和远小于 10000，会发生什么？

**参考答案要点**：每次领取只有部分 `_amount` 被铸成代币，其余计量「丢失」在比例外；属于**配置错误风险**，非合约自动钳制。

### F3. 如何用一句话向面试官介绍本项目？

**参考答案示例**：「这是基于 Uniswap V2 的 AMM 配套一套 MasterChef 网关的多代币挖矿：Farm 用 StakingRewards 记账，真正发奖时由 MasterChef 按池配置铸造多种 `IBaseToken`，并带 xBASE 投票调节社区奖励分配。」

（可对照 [LEARNING_GUIDE.md](LEARNING_GUIDE.md) **§1** 微调表述。）

---

## G. 速查清单（面试前 5 分钟）

**对应学习指南**：[LEARNING_GUIDE.md](LEARNING_GUIDE.md) **§0.3**（阅读路线）、**§15**（学习路径）

- 能画出：用户 → StakingRewards → MasterChef → 多 `mint`。（**§2、§9**）
- 能口述：`rewardPerToken`、`earned`、`updateReward`。（**§9、本文件 B**）
- 能解释：`isFarm`、`allocPoint`、`allocPointCommunity`、7 天 `massUpdate`。（**§9、本文件 C**）
- 能说出：Uniswap `lock`、CPAMM 滑点、TWAP 用途。（**§5、本文件 A**）
- 能诚实说：特权面、未校验 `ratios` 总和、仓库无内置测试脚手架。（**§16、本文件 E**）

---

## 附录：代币与工具速查（补充题）

| 若被问到 | 精读章节（[LEARNING_GUIDE.md](LEARNING_GUIDE.md)） |
|----------|----------|
| COIN 谁可 `mint`、`burnFrom` 为何特殊 | **§7** CoinToken |
| BASE 初始分配与 Operator | **§8** BaseToken |
| xBASE→BASE 非 AMM 兑换 | **§10** OtcSwap |
| LP 定时锁仓与费用 | **§11** BaseTokenLocker |

祝面试顺利。
