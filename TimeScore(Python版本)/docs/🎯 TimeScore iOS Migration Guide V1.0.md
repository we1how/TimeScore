# 🎯 TimeScore iOS Migration Guide V1.0

## 迁移概述
本指南针对TimeScore Python CLI原型（基于V5.0优化代码）迁移到iOS应用。目标是创建一个原生SwiftUI iOS App，保持极简主义设计哲学：输入极简、计算智能、上瘾循环。迁移分模块进行，先核心逻辑（计算/数据），后UI/可视化。使用Swift 5+、SwiftUI（UI框架）、CoreData（持久化，替换SQLite）、Charts（可视化）。

**前提**：
- Xcode 15+（支持iOS 15+）。
- Python原型作为参考：逻辑函数直接翻译（e.g., Python dict → Swift struct）。
- 测试策略：单元测试（XCTest）匹配Python输出；UI测试用XCUITest。
- 架构：MVVM（Model-View-ViewModel），ViewModel处理逻辑/DB。

**迁移原则**：
- 保持模块化：每个系统对应一个文件夹/模块。
- 极简UI：白空间多、字体SF Pro、颜色方案（绿正面、蓝恢复、红负）。
- 性能：本地CoreData，无云端。
- 扩展：支持暗模式、通知（e.g., 低精力提醒）。

此文档可作为大模型（如LLM）理解和实现的Prompt基础：**"基于TimeScore Python V5.0代码和此迁移指南，实现iOS SwiftUI App。从核心计算模块开始，生成Swift代码框架，包括CoreData schema、ViewModels和主要Views。确保逻辑匹配Python（e.g., calculate_score func 等效）。输出格式：每个模块的代码片段+整体AppDelegate。"**

---

## 一、数据结构与持久化（CoreData替换SQLite）

### 1. CoreData Schema
- **实体映射**（从Python models.py）：
  - **User**：用户实体（单例，默认ID=1）。
    - Attributes: id (Int64), totalPoints (Double), currentEnergy (Double, 默认100), lastResetDate (Date)。
    - Relationships: behaviors (To-Many → Behavior), wishes (To-Many → Wish)。
  - **Behavior**：行为记录。
    - Attributes: id (UUID), grade (String, e.g., "S"/"R2"), duration (Int32), mood (Int16, 1-5), timestamp (Date), notes (String, 可选感受), score (Double), energyChange (Double)。
    - Relationships: user (To-One → User)。
  - **Wish**：心愿。
    - Attributes: id (UUID), name (String), cost (Double), status (String, "pending"/"redeemed"), createdAt (Date), redeemedAt (Date? 可空), progress (Double)。
    - Relationships: user (To-One → User)。

- **实现步骤**：
  - Xcode中创建CoreData Model (.xcdatamodeld)。
  - 生成NSManagedObject子类（自动）。
  - 迁移脚本：从Python SQLite导出JSON，iOS导入到CoreData（可选App启动时检查）。

### 2. 数据访问层（从db/sqlite.py）
- **CoreDataManager** 类（单例）。
  - Methods:
    - `saveContext()`：保存变化（try-catch错误处理）。
    - `fetchUser(id: Int) -> User?`：获取用户（默认创建）。
    - `addBehavior(to user: User, grade: String, duration: Int, mood: Int, notes: String?)`：添加行为，触发计算。
    - `fetchBehaviors(for user: User, dateRange: DateInterval?) -> [Behavior]`：历史查询。
    - 类似 for Wishes: `addWish()`, `fetchWishes(status: String?)`。
- **优化**：背景线程（DispatchQueue），谓词过滤（NSPredicate for queries）。

---

## 二、核心逻辑模块迁移

### 1. 行为记录系统（从main.py记录部分）
- **ViewModel**：BehaviorViewModel。
  - Properties: @Published grade, duration, mood, notes。
  - Methods: `recordBehavior()` → 调用ScoringViewModel计算score/energy，保存到CoreData。
- **UI映射**：见UI设计部分。

### 2. 积分计算系统（从scoring/calculator.py）
- **ViewModel**：ScoringViewModel。
  - Constants: 基础分表（Dictionary<String, (baseScore: Double, energyCost: Double)>）。
  - Methods:
    - `calculateScore(grade: String, duration: Int, energy: Double, combo: Int) -> Double`：公式 = base × duration × (energyCoef × comboCoef)。匹配Python calculate_score()。
    - `getDynamicCoefficients(energy: Double, combo: Int) -> Double`：精力系数（if energy >70: 1.0 + ...）。
    - `updateTotalPoints(user: User, newScore: Double)`：user.totalPoints += newScore。
- **测试**：XCTest断言匹配Python输出（e.g., S级90min → ~231分）。

### 3. 精力管理系统（从scoring/energy.py，V3.0）
- **整合到ScoringViewModel**。
  - Methods:
    - `calculateEnergyChange(grade: String, duration: Int) -> Double`：消耗/恢复（R级正值）。
    - `applyAutoRecovery(user: User, since lastTimestamp: Date)`：间隔恢复（每min 0.02），跨天重置（if new day, energy = 100 + sleepBonus）。
    - `inferRSublevel(mood: Int, duration: Int) -> String`：推测R1/R2/R3。
- **逻辑**：行为前调用recovery，计算change，更新user.currentEnergy（上限120）。

### 4. 可视化系统（从visualization/dashboard.py，V4.0）
- **ViewModel**：VisualizationViewModel。
  - Properties: @Published dashboardData (struct: totalPoints, efficiency, streak, avgMood)。
  - Methods:
    - `generateTimeline(behaviors: [Behavior]) -> [TimelineItem]`：自定义struct for时间轴（时间、条形数据）。
    - `generateHeatmap(for month: Date) -> HeatmapData`：网格数组（颜色基于积分）。
    - `generateRPGStats(user: User) -> RPGStats`：XP、levels计算。
    - `generateDistribution(behaviors: [Behavior]) -> PieChartData`。
- **UI**：用Swift Charts（时间轴/柱/饼），Fallback Text for CLI-like（但iOS图形化）。
- **动画**：积分更新用.withAnimation {}。

### 5. 积分兑换系统（从redeem/exchange.py，V5.0）
- **ViewModel**：ExchangeViewModel。
  - Properties: @Published wishes: [Wish]。
  - Methods:
    - `addWish(name: String, cost: Double)`：创建Wish，保存。
    - `redeemWish(wish: Wish, user: User)`：if user.totalPoints >= cost { deduct; status = "redeemed"; } else { alert }。
    - `updateProgress(wish: Wish, currentPoints: Double)`：progress = min(1.0, currentPoints / cost)。
- **平衡**：成本下限100，单日限3兑换。

---

## 三、UI与交互设计（SwiftUI）

### 1. App结构
- **Navigation**：TabView底部（Home, Visualize, Redeem）。
- **主界面（HomeView）**：
  - 顶部：积分显示（大Text）。
  - 中间：行为输入Form（Picker for grade, TextField duration/mood/notes）。
  - 按钮：记录行为 → 计算&保存。
- **历史回顾**：List of Behaviors，tap查看详情。
- **可视化**：Tab子视图（Dashboard Card, Timeline ScrollView, Heatmap Grid, RPG Card, Charts）。
- **兑换**：Form新增，List兑换（ProgressView进度条，Button redeem）。
- **极简美感**：字体SF Pro (Bold标题24pt, Regular正文16pt)，颜色#4CAF50绿、#2196F3蓝，圆角8pt，动画fadeIn。

### 2. 全局组件
- **AchievementAnimation**：粒子系统（SwiftUI Canvas） for 成就/兑换。
- **Error Handling**：Alert modifiers。
- **通知**：UNUserNotificationCenter for 低精力/进度提醒。

---

## 四、实现与测试步骤

### 1. 分步实现
- **步骤1**：设置CoreData栈（AppDelegate/PersistenceController）。
- **步骤2**：核心ViewModels（Scoring/Energy），XCTest匹配Python。
- **步骤3**：行为记录View+VM，集成计算。
- **步骤4**：可视化Views，用Charts渲染。
- **步骤5**：兑换Views，完整集成。
- **全App**：SceneDelegate/TabView。

### 2. 测试
- 单元：XCTest for calculateScore() 等（输入Python样例，assert输出）。
- UI：XCUITest模拟tap记录，验证积分更新。
- 端到端：模拟小明一天，检查总分/精力。

### 3. 部署
- App Icon：极简时钟+积分符号。
- App Store：最小Viable Product，iPhone/iPad兼容。

---
