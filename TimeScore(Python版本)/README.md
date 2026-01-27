# TimeScore 时间管理系统

## 项目概述

TimeScore 是一个基于极简输入的时间管理CLI应用，通过记录行为（等级、时长、心情），自动计算积分和精力变化，并提供可视化和积分兑换系统。

## 核心功能

1. **行为记录系统**：记录用户行为（等级、时长、心情），支持详细备注
2. **积分计算系统**：基于等级基础分、时长、动态系数（精力、连击等）计算得分
3. **精力管理系统**：精力初始100，S/A/B消耗，R恢复，自动间隔恢复，跨天重置
4. **可视化系统**：CLI仪表盘、时间轴、热力图、RPG反馈、分布图
5. **积分兑换系统**：心愿表管理，积分兑换心愿

## 安装

1. 确保已安装 Python 3.7 或更高版本
2. 克隆或下载项目代码
3. 安装依赖：
   ```bash
   pip install -r requirements.txt
   ```

## 运行

1. 启动主程序：
   ```bash
   python main.py
   ```

2. 选择要进入的界面：
   - 1. 增加行为界面
   - 2. 记录行为界面
   - 3. 历史回顾系统
   - 4. 积分兑换系统
   - 5. 退出系统

## 项目架构

### 目录结构

```
src/
├── models/          # 数据模型
│   ├── __init__.py
│   ├── behavior.py  # 行为数据模型
│   ├── user.py      # 用户数据模型
│   └── wish.py      # 心愿数据模型
├── db/              # 数据库操作
│   ├── __init__.py
│   └── sqlite.py    # SQLite数据库管理
├── scoring/         # 积分计算
│   ├── __init__.py
│   ├── calculator.py  # 积分计算逻辑
│   └── energy.py     # 精力管理
├── visualization/   # 可视化
│   ├── __init__.py
│   └── dashboard.py  # CLI仪表盘
├── redeem/          # 积分兑换
│   ├── __init__.py
│   └── exchange.py   # 积分兑换系统
├── utils/           # 工具函数
│   ├── __init__.py
│   └── config.py     # 配置管理
└── main.py          # 主程序入口
```

### 核心模块说明

1. **数据模型层**：
   - `Behavior`：行为记录的数据结构
   - `User`：用户状态和数据
   - `Wish`：心愿表数据结构

2. **数据库层**：
   - 基于SQLite的数据库操作
   - 使用context manager管理连接
   - 支持行为记录、用户状态、心愿表等数据存储

3. **积分计算层**：
   - 基于等级、时长、精力、连击等计算得分
   - 精力消耗/恢复计算
   - 防滥用与平衡机制

4. **可视化层**：
   - CLI仪表盘展示
   - 历史数据可视化
   - RPG风格反馈

5. **积分兑换层**：
   - 心愿管理
   - 积分兑换
   - 进度跟踪

## 技术栈

- Python 3.7+
- SQLite (内置)
- termcolor (用于彩色输出)
- texttable (用于表格输出)
- pytest (用于测试)

## 开发指南

### 代码规范

- 函数名使用 snake_case
- 类名使用 CamelCase
- 变量名使用 snake_case
- 所有函数和类必须添加详细的 docstring 和类型提示
- 使用 context manager 管理数据库连接

### 测试

使用 pytest 运行测试：

```bash
pytest
```

## 迁移到 iOS

### 数据模型对应

| Python 模型 | iOS 模型 | 说明 |
|-------------|----------|------|
| `Behavior` | `Behavior` struct | 行为记录数据结构 |
| `User` | `User` struct | 用户状态数据结构 |
| `Wish` | `Wish` struct | 心愿数据结构 |

### 核心函数对应

| Python 函数 | iOS 函数 | 说明 |
|-------------|----------|------|
| `ScoringCalculator.calculate_score()` | `ScoringViewModel.calculateScore()` | 计算行为得分 |
| `ScoringCalculator.calculate_energy_cost()` | `ScoringViewModel.calculateEnergyCost()` | 计算精力消耗/恢复 |
| `SQLiteDB.get_total_score()` | `CoreDataManager.getTotalScore()` | 获取总积分 |
| `ExchangeSystem.redeem_wish()` | `ExchangeViewModel.redeemWish()` | 兑换心愿 |

### 数据库对应

- 使用 Core Data 替代 SQLite
- 表结构可直接映射为 Core Data 实体

## 版本历史

- V1.0: 基础时间管理功能
- V2.0: 积分计算系统
- V3.0: 精力管理系统
- V4.0: 可视化系统
- V5.0: 积分兑换系统

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！