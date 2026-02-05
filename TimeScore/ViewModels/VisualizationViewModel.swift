//
//  VisualizationViewModel.swift
//  TimeScore
//
//  可视化系统
//  对应 Python: src/visualization/dashboard.py
//

import Foundation
import Combine

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

    /// 生成热力图数据
    /// 对应 Python: generate_heatmap()
    func loadHeatmap() {
        guard let user = user else { return }

        let behaviors = dataManager.fetchBehaviors(for: user)
        let calendar = Calendar.current

        // 生成最近30天的数据
        let today = Date()
        var gridData: [HeatmapCell] = []

        for offset in (0..<30).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }

            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let dayBehaviors = behaviors.filter {
                $0.timestamp >= startOfDay && $0.timestamp < endOfDay
            }

            let totalScore = dayBehaviors.reduce(0) { $0 + $1.score }

            // 计算强度级别 (0-4)
            let intensity: Int
            if totalScore == 0 {
                intensity = 0
            } else if totalScore < 100 {
                intensity = 1
            } else if totalScore < 300 {
                intensity = 2
            } else if totalScore < 500 {
                intensity = 3
            } else {
                intensity = 4
            }

            let cell = HeatmapCell(
                date: date,
                score: totalScore,
                intensity: intensity
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

    /// 柱状图高度比例 (0-1)
    var barHeightRatio: Double {
        // 假设最大500分作为100%
        return min(1.0, max(0.1, totalScore / 500.0))
    }
}

/// 热力图单元格
struct HeatmapCell {
    let date: Date
    let score: Double
    let intensity: Int // 0-4

    /// 颜色透明度
    var opacity: Double {
        switch intensity {
        case 0: return 0.0
        case 1: return 0.2
        case 2: return 0.4
        case 3: return 0.7
        case 4: return 1.0
        default: return 0.0
        }
    }
}

/// 热力图数据
struct HeatmapData {
    let cells: [HeatmapCell]

    /// 按周分组
    var weeks: [[HeatmapCell?]] {
        var result: [[HeatmapCell?]] = []
        var currentWeek: [HeatmapCell?] = []

        // 填充第一周前的空白
        if let firstDate = cells.first?.date {
            let weekday = Calendar.current.component(.weekday, from: firstDate) - 1
            currentWeek = Array(repeating: nil, count: weekday)
        }

        for cell in cells {
            currentWeek.append(cell)

            if currentWeek.count == 7 {
                result.append(currentWeek)
                currentWeek = []
            }
        }

        // 补齐最后一周
        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                currentWeek.append(nil)
            }
            result.append(currentWeek)
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
