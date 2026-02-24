//
//  VisualizationViewModel.swift
//  TimeScore
//
//  可视化系统
//  对应 Python: src/visualization/dashboard.py
//

import Foundation
import Combine
import SwiftUI

/// 可视化 ViewModel
/// 负责统计数据生成、图表数据准备
class VisualizationViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 统计数据
    @Published var statistics: DashboardStatistics?

    /// 时间线数据
    @Published var timelineItems: [TimelineItem] = []

    /// 热力图数据
    @Published var heatmapData: HeatmapData?

    /// 周表现数据
    @Published var weeklyData: [DailyPerformance] = []

    /// 分布数据
    @Published var distributionData: GradeDistribution?

    /// 每日贡献数据（当前选中的日期）
    @Published var dailyContribution: DailyContribution?

    /// 当前选中的日期（用于切换不同日期的贡献视图）
    @Published var selectedDate: Date = Date()

    /// 当前视图模式（支持未来扩展）
    @Published var viewMode: ContributionViewMode = .day

    // MARK: - Dependencies

    private let dataManager: CoreDataManager
    private var user: User?

    // MARK: - Initialization

    init(dataManager: CoreDataManager = CoreDataManager.shared) {
        self.dataManager = dataManager
    }

    // MARK: - User Setup

    /// 设置当前用户并加载所有数据
    func setup(for user: User) {
        self.user = user
        refreshAllData()
    }

    // MARK: - Data Refresh

    /// 刷新所有可视化数据
    func refreshAllData() {
        loadStatistics()
        loadTimeline()
        loadWeeklyData()
        loadHeatmap()
        loadDistribution()
        loadDailyContribution(for: selectedDate)
    }

    /// 切换到指定日期
    func selectDate(_ date: Date) {
        selectedDate = date
        loadDailyContribution(for: date)
    }

    // MARK: - Statistics

    /// 加载统计数据
    /// 对应 Python: generate_dashboard()
    func loadStatistics() {
        guard let user = user else { return }

        let stats = dataManager.getStatistics(for: user)

        statistics = DashboardStatistics(
            totalPoints: stats.totalPoints,
            currentEnergy: stats.currentEnergy,
            efficiency: stats.efficiency,
            streak: stats.streak,
            averageMood: stats.averageMood,
            totalBehaviors: stats.totalBehaviors
        )
    }

    // MARK: - Timeline

    /// 生成时间线数据
    /// 对应 Python: generate_timeline()
    func loadTimeline() {
        guard let user = user else { return }

        let behaviors = dataManager.fetchBehaviors(for: user)
        let calendar = Calendar.current

        // 按日期分组
        let grouped = Dictionary(grouping: behaviors) { behavior in
            calendar.startOfDay(for: behavior.timestamp)
        }

        // 生成时间线项（最近7天）
        var items: [TimelineItem] = []
        let today = calendar.startOfDay(for: Date())

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            let dayBehaviors = grouped[date] ?? []

            if !dayBehaviors.isEmpty {
                let totalScore = dayBehaviors.reduce(0) { $0 + $1.score }
                let item = TimelineItem(
                    date: date,
                    behaviors: dayBehaviors,
                    totalScore: totalScore,
                    behaviorCount: dayBehaviors.count
                )
                items.append(item)
            }
        }

        timelineItems = items
    }

    // MARK: - Weekly Performance

    /// 生成周表现数据
    func loadWeeklyData() {
        guard let user = user else { return }

        let behaviors = dataManager.fetchBehaviors(for: user)
        let calendar = Calendar.current

        // 按星期几分组
        let weekdayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]

        var dailyData: [DailyPerformance] = []

        // 获取最近7天
        let today = Date()
        for offset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }

            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let dayBehaviors = behaviors.filter {
                $0.timestamp >= startOfDay && $0.timestamp < endOfDay
            }

            let totalScore = dayBehaviors.reduce(0) { $0 + $1.score }
            let positiveCount = dayBehaviors.filter { $0.score > 0 }.count

            let weekday = calendar.component(.weekday, from: date) - 1 // 0 = Sunday

            let performance = DailyPerformance(
                date: date,
                weekday: weekdayNames[weekday],
                totalScore: totalScore,
                behaviorCount: dayBehaviors.count,
                positiveCount: positiveCount
            )

            dailyData.append(performance)
        }

        weeklyData = dailyData
    }

    // MARK: - Heatmap

    /// 生成热力图数据（90天，支持正负分）
    /// 对应 Python: generate_heatmap()
    func loadHeatmap() {
        guard let user = user else { return }

        let behaviors = dataManager.fetchBehaviors(for: user)
        let calendar = Calendar.current

        // 生成最近90天的数据
        let today = Date()
        var gridData: [HeatmapCell] = []

        for offset in (0..<90).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }

            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let dayBehaviors = behaviors.filter {
                $0.timestamp >= startOfDay && $0.timestamp < endOfDay
            }

            // 分别计算正分和负分
            let positiveScore = dayBehaviors.filter { $0.score > 0 }.reduce(0) { $0 + $1.score }
            let negativeScore = dayBehaviors.filter { $0.score < 0 }.reduce(0) { $0 + $1.score }
            let totalScore = positiveScore + negativeScore // negativeScore 已经是负数

            let cell = HeatmapCell(
                date: date,
                totalScore: totalScore,
                positiveScore: positiveScore,
                negativeScore: negativeScore
            )

            gridData.append(cell)
        }

        heatmapData = HeatmapData(cells: gridData)
    }

    // MARK: - Distribution

    /// 生成等级分布数据
    func loadDistribution() {
        guard let user = user else { return }

        let behaviors = dataManager.fetchBehaviors(for: user)

        var gradeCounts: [String: Int] = [:]
        for grade in ["S", "A", "B", "C", "D", "R1", "R2", "R3"] {
            gradeCounts[grade] = 0
        }

        for behavior in behaviors {
            let grade = behavior.grade
            gradeCounts[grade, default: 0] += 1
        }

        distributionData = GradeDistribution(
            sCount: gradeCounts["S"] ?? 0,
            aCount: gradeCounts["A"] ?? 0,
            bCount: gradeCounts["B"] ?? 0,
            cCount: gradeCounts["C"] ?? 0,
            dCount: gradeCounts["D"] ?? 0,
            rCount: (gradeCounts["R1"] ?? 0) + (gradeCounts["R2"] ?? 0) + (gradeCounts["R3"] ?? 0)
        )
    }

    // MARK: - Daily Contribution

    /// 加载指定日期的行为贡献数据
    /// 合并相同名称和等级的行为，按绝对值分数排序
    func loadDailyContribution(for date: Date) {
        guard let user = user else { return }

        let behaviors = dataManager.fetchBehaviors(for: user)
        let calendar = Calendar.current

        // 获取指定日期的开始和结束
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        // 筛选当天的行为
        let dayBehaviors = behaviors.filter {
            $0.timestamp >= startOfDay && $0.timestamp < endOfDay
        }

        // 合并相同行为（按名称+等级分组）
        var groupedBehaviors: [String: [Behavior]] = [:]
        for behavior in dayBehaviors {
            let key = "\(behavior.name ?? "Unknown")|\(behavior.grade)"
            groupedBehaviors[key, default: []].append(behavior)
        }

        // 生成贡献项
        var items: [ContributionItem] = []
        var positiveScore: Double = 0
        var negativeScore: Double = 0

        for (_, behaviors) in groupedBehaviors {
            guard let first = behaviors.first else { continue }

            let totalScore = behaviors.reduce(0) { $0 + $1.score }
            let totalDuration = behaviors.reduce(0) { $0 + $1.duration }

            if totalScore > 0 {
                positiveScore += totalScore
            } else {
                negativeScore += totalScore // 已经是负数
            }

            let item = ContributionItem(
                name: first.name ?? "Unknown",
                grade: first.grade,
                totalScore: totalScore,
                count: behaviors.count,
                totalDuration: totalDuration
            )
            items.append(item)
        }

        // 按绝对值分数降序排列
        items.sort { $0.sortValue > $1.sortValue }

        dailyContribution = DailyContribution(
            date: date,
            items: items,
            totalScore: positiveScore + negativeScore,
            positiveScore: positiveScore,
            negativeScore: negativeScore
        )
    }
}

// MARK: - Supporting Types

/// 仪表板统计数据
struct DashboardStatistics {
    let totalPoints: Double
    let currentEnergy: Double
    let efficiency: Double
    let streak: Int
    let averageMood: Double
    let totalBehaviors: Int

    /// 效率百分比文本
    var efficiencyText: String {
        return "\(Int(efficiency))%"
    }

    /// 平均心情文本
    var averageMoodText: String {
        return String(format: "%.1f", averageMood)
    }
}

/// 时间线项
struct TimelineItem {
    let date: Date
    let behaviors: [Behavior]
    let totalScore: Double
    let behaviorCount: Int

    /// 日期显示文本
    var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    /// 是否是今天
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

/// 每日表现
struct DailyPerformance {
    let date: Date
    let weekday: String
    let totalScore: Double
    let behaviorCount: Int
    let positiveCount: Int

    /// 柱状图高度比例 (0-1) - 基于动态最大值
    func barHeightRatio(maxScore: Double) -> Double {
        guard maxScore > 0 else { return 0.1 }
        return min(1.0, max(0.1, totalScore / maxScore))
    }

    /// 是否是今天
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

/// 热力图单元格 - 支持正负分显示
struct HeatmapCell: Identifiable {
    let id = UUID()
    let date: Date
    let totalScore: Double      // 净分值（可正可负）
    let positiveScore: Double   // 正分总和
    let negativeScore: Double   // 负分总和（负数）

    /// 显示颜色：正数绿色，负数红色
    var displayColor: Color {
        if totalScore >= 0 {
            return .primaryGreen
        } else {
            return .red
        }
    }

    /// 根据最大值计算透明度
    func opacity(maxScore: Double) -> Double {
        guard maxScore > 0 else { return 0.1 }
        let absScore = abs(totalScore)
        let ratio = absScore / maxScore
        // 最小0.2，最大1.0
        return min(1.0, max(0.2, ratio))
    }

    /// 净分值显示文本
    var scoreText: String {
        if totalScore >= 0 {
            return "+\(Int(totalScore))"
        } else {
            return "\(Int(totalScore))"
        }
    }

    /// 是否是今天
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    /// 月份标签（用于在UI上显示月份分隔）
    var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        return formatter.string(from: date)
    }

    /// 周几标签
    var weekdayLabel: String {
        let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
        let weekday = Calendar.current.component(.weekday, from: date) - 1
        return weekdays[weekday]
    }
}

/// 热力图数据
struct HeatmapData {
    let cells: [HeatmapCell]

    /// 计算用于归一化的最大值
    var maxAbsScore: Double {
        let maxScore = cells.map { abs($0.totalScore) }.max() ?? 0
        return maxScore > 0 ? maxScore : 100 // 默认100防止除零
    }

    /// 按月分组用于显示月份标签
    var monthGroups: [(month: String, cells: [HeatmapCell])] {
        var result: [(month: String, cells: [HeatmapCell])] = []
        var currentMonth = ""
        var currentCells: [HeatmapCell] = []

        for cell in cells {
            let month = cell.monthLabel
            if month != currentMonth {
                if !currentCells.isEmpty {
                    result.append((month: currentMonth, cells: currentCells))
                }
                currentMonth = month
                currentCells = [cell]
            } else {
                currentCells.append(cell)
            }
        }

        if !currentCells.isEmpty {
            result.append((month: currentMonth, cells: currentCells))
        }

        return result
    }
}

/// 等级分布
struct GradeDistribution {
    let sCount: Int
    let aCount: Int
    let bCount: Int
    let cCount: Int
    let dCount: Int
    let rCount: Int

    var total: Int {
        sCount + aCount + bCount + cCount + dCount + rCount
    }

    func percentage(for grade: String) -> Double {
        guard total > 0 else { return 0.0 }

        let count: Int
        switch grade {
        case "S": count = sCount
        case "A": count = aCount
        case "B": count = bCount
        case "C": count = cCount
        case "D": count = dCount
        case "R": count = rCount
        default: count = 0
        }

        return Double(count) / Double(total) * 100.0
    }
}

// MARK: - Daily Contribution

/// 视图模式 - 支持日/周/月/年视图扩展
enum ContributionViewMode: String, CaseIterable {
    case day = "日"
    case week = "周"
    case month = "月"
    case year = "年"
}

/// 行为贡献项 - 合并相同行为后的数据
struct ContributionItem: Identifiable {
    let id = UUID()
    let name: String
    let grade: String
    let totalScore: Double
    let count: Int // 相同行为出现的次数
    let totalDuration: Int32 // 总时长（分钟）

    /// 唯一标识（用于合并）
    var uniqueKey: String { "\(name)|\(grade)" }

    /// 颜色强度（基于绝对值分数的对数映射）
    func colorIntensity(maxAbsScore: Double) -> Double {
        guard maxAbsScore > 0 else { return 0.2 }
        let absScore = abs(totalScore)
        // 使用平方根映射，让小分数也有明显颜色差异
        let normalized = sqrt(absScore) / sqrt(maxAbsScore)
        return min(1.0, max(0.15, normalized))
    }

    /// 背景颜色（森林绿/深海蓝配色）
    func backgroundColor(maxAbsScore: Double) -> Color {
        let intensity = colorIntensity(maxAbsScore: maxAbsScore)
        if totalScore >= 0 {
            // 正分：森林绿 #2E7D32
            return Color(red: 46/255, green: 125/255, blue: 50/255)
                .opacity(intensity)
        } else {
            // 负分：深海蓝 #1565C0
            return Color(red: 21/255, green: 101/255, blue: 192/255)
                .opacity(intensity)
        }
    }

    /// 文字颜色（根据背景深度自动调整）
    func textColor(maxAbsScore: Double) -> Color {
        let intensity = colorIntensity(maxAbsScore: maxAbsScore)
        // 颜色较深时使用白色文字，否则使用深色
        return intensity > 0.5 ? .white : (totalScore >= 0 ? Color(red: 46/255, green: 125/255, blue: 50/255) : Color(red: 21/255, green: 101/255, blue: 192/255))
    }

    /// 显示分数（带+号）
    var displayScore: String {
        if totalScore > 0 {
            return "+\(Int(totalScore))"
        } else {
            return "\(Int(totalScore))"
        }
    }

    /// 排序值（用于按绝对值排序）
    var sortValue: Double { abs(totalScore) }
}

/// 每日贡献数据
struct DailyContribution {
    let date: Date
    let items: [ContributionItem]
    let totalScore: Double
    let positiveScore: Double
    let negativeScore: Double

    /// 最大绝对值分数（用于颜色归一化）
    var maxAbsScore: Double {
        let maxValue = items.map { $0.sortValue }.max() ?? 0
        return maxValue > 0 ? maxValue : 100
    }

    /// 日期显示文本
    var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    /// 星期显示
    var weekdayText: String {
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let weekday = Calendar.current.component(.weekday, from: date) - 1
        return weekdays[weekday]
    }

    /// 是否今天
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}
