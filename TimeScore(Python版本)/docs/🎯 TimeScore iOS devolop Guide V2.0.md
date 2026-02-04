# 🎯 TimeScore iOS devolop Guide V2.0

## 迁移概述
本指南针对TimeScore Python CLI原型（基于V5.0优化代码）迁移到iOS应用。目标是创建一个原生SwiftUI iOS App，保持极简主义设计哲学：输入极简、计算智能、上瘾循环。迁移分模块进行，先核心逻辑（计算/数据），后UI/可视化。使用Swift 5+、SwiftUI（UI框架）、CoreData（持久化，替换SQLite）、Charts（可视化）。

**前提**：
- Xcode 15+（支持iOS 15+）。
- Python原型作为参考：逻辑函数直接翻译（e.g., Python dict → Swift struct）。
- 测试策略：单元测试（XCTest）匹配Python输出；UI测试用XCUITest。
- 架构：MVVM（Model-View-ViewModel），ViewModel处理逻辑/DB。

**迁移原则**：
- 保持模块化：每个系统对应一个文件夹/模块。
- 极简UI：白空间多、字体SF Pro、颜色方案（黑白为主色调）。
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

### 1. 设计语言系统（Design System）

基于应用截图提炼的极简设计原则，TimeScore采用以下核心设计关键词：

#### 布局结构
- **垂直堆叠信息架构**：单屏内采用顶部数据区→核心输入区→底部导航区的三段式分层。首页将当前积分/精力状态置于视觉重心（约30%屏高），形成"状态在上、操作在下"的F型浏览动线。
- **卡片式内容分组**：行为记录、历史列表、统计数据均采用独立卡片容器，圆角16pt，背景填充浅灰（#F5F5F5），与纯白底色区分层级。

#### 组件形态
- **药丸形主按钮（Pill Button）**："记录行为"主按钮采用全圆角（cornerRadius: 24），占据屏宽80%并居中，区别于尖锐直角，建立视觉锚点。
- **幽灵分段控制器（Ghost Segmented Control）**：行为等级选择（S/A/B/R）使用描边+透明填充样式，选中态转为实心填充，置于白色卡片内。
- **悬浮状态指示器**：当前精力值使用圆形进度条（Circular Progress）悬浮于积分数字右下角，直观显示精力饱和度。

#### 字体与排版
- **SF Pro 动态字重**：积分大数字使用SF Pro Rounded Bold（48pt），标签使用SF Pro Text Regular（16pt），形成强烈对比。
- **截断文本+展开控制**：行为备注（notes）在历史列表中采用单行截断，详情页显示全文，控制信息密度。

#### 色彩系统
- **语义化单色调和**：以黑白灰为基底，功能色严格对应状态。
- **深色底部导航栏**：底部Tab栏采用深色（#1C1C1E）与内容区白色形成强分隔，制造"地面"稳定感，选中态使用品牌绿色点缀。

#### 材质与层级
- **无投影扁平化**：卡片与按钮不使用阴影，依赖背景色块（浅灰卡片vs白底）和间距建立层级，呈现iOS原生风格。
- **毛玻璃效果（可选）**：顶部导航栏使用.ultraThinMaterial，滚动时产生景深分离。

#### 交互定义
- **步进器（Stepper）**：时长输入使用"- 数值 +"紧凑组合，配合数字键盘直接输入，减少摩擦。
- **触觉反馈（Haptic Feedback）**：行为记录成功触发.lightImpact，兑换心愿触发.heavyImpact+成功动效。
- **页面转场**：Tab切换使用默认淡入淡出，详情页进入使用从右向左滑入（push）。

### 2. App结构与页面架构

- **导航模式**：TabView底部三栏（Home记录, Visualize可视化, Redeem兑换）。
- **HomeView（行为记录主屏）**：
  - **顶部区域**：大号积分显示（SF Pro Rounded 48pt）+ 精力环形进度指示器（32pt圆形）。
  - **中部输入卡**：行为等级Picker（S/A/B/R药丸分段器），展开后显示时长Stepper、心情1-5星评分、备注TextField。
  - **底部操作**：渐变绿色"记录"药丸按钮（全宽-32pt边距）。
- **VisualizeView（可视化Tab）**：
  - 顶部Dashboard卡片：总积分、今日效率、连续天数、平均心情（四宫格布局）。
  - 中部时间轴：垂直ScrollView，行为节点用颜色条区分。
  - 底部图表区：Swift Charts柱状图（周统计）+ 热力图（月视图，网格颜色深浅表示积分密度）。
- **RedeemView（兑换Tab）**：
  - 顶部：当前积分余额大字体显示。
  - 中部：新增心愿Form（名称TextField、成本NumberField，最小100pt）。
  - 列表：心愿卡片（名称+进度条+兑换按钮），已兑换置灰并显示日期戳。
  - 兑换成功：全屏粒子动效（AchievementAnimation）覆盖。

### 3. 全局组件与动效

- **AchievementAnimation**：SwiftUI Canvas粒子系统，兑换成功时触发金币/星星粒子爆发，持续1.5秒后自动消失。
- **Error Handling**：Alert modifiers统一处理错误（如积分不足、网络异常），位置居中，红色警示图标。
- **通知UI**：UNUserNotificationCenter本地通知，低精力时推送"该休息一下了"（蓝色背景横幅）。
- **加载状态**：骨架屏（Skeleton Loading）使用浅灰占位（#E5E5E5），匹配电商App截图的极简占位风格。

### 4. 适配与扩展

- **暗模式（Dark Mode）**：自动适配iOS系统设置，卡片背景转为#2C2C2E，文字反白，保持色彩语义不变。
- **动态字体**：支持Accessibility Large Text，积分数字随系统设置缩放，最大支持XXXL。
- **iPad适配**：使用Split View，左侧导航右侧内容，大屏上图表横向展开。

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