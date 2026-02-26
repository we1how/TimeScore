//
//  InsightsView.swift
//  TimeScore
//
//  历史行为回顾界面
//  对应 UI 原型: 历史行为回顾界面.html
//

import SwiftUI
import Charts

struct InsightsView: View {

    // MARK: - Properties

    @StateObject private var vizVM = VisualizationViewModel()
    @State private var user: User?
    @State private var showHistoryView = false

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 顶部导航
                topBar

                // Dashboard 统计网格
                dashboardGrid

                // 行为时间线
                timelineSection

                // 周表现图表
                weeklyChartSection

                // 每日行为贡献
                dailyContributionSection

                // 底部空间
                Spacer().frame(height: 40)
            }
            .padding(.horizontal)
        }
        // Bug Fix 3: 使用系统背景色支持暗黑模式
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            loadUser()
        }
        .onReceive(NotificationCenter.default.publisher(for: .behaviorRecorded)) { _ in
            loadUser()
        }
        .sheet(isPresented: $showHistoryView) {
            BehaviorHistoryView()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()

            Text(NSLocalizedString("insights.title", comment: "Insights title"))
                .font(.system(size: 17, weight: .bold))

            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Dashboard Grid

    private var dashboardGrid: some View {
        let stats = vizVM.statistics

        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            statCard(
                title: NSLocalizedString("insights.total_points", comment: "Total points"),
                value: stats?.totalPoints.pointsDisplay ?? "0",
                color: .black
            )

            statCard(
                title: NSLocalizedString("insights.energy", comment: "Energy"),
                value: "\(Int(stats?.currentEnergy ?? 100))/120",
                color: .primaryGreen
            )

            statCard(
                title: NSLocalizedString("insights.streak", comment: "Streak"),
                value: "\(stats?.streak ?? 0)",
                icon: "🔥",
                color: .black
            )

            statCard(
                title: NSLocalizedString("insights.avg_mood", comment: "Avg mood"),
                value: stats?.averageMoodText ?? "0.0",
                color: .black
            )
        }
    }

    private func statCard(title: String, value: String, icon: String? = nil, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .tracking(0.5)
                .foregroundColor(.gray)
                .textCase(.uppercase)

            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(color)

                if let icon = icon {
                    Text(icon)
                        .font(.system(size: 20))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏带导航按钮
            HStack {
                Text(NSLocalizedString("insights.behavior_nodes", comment: "Behavior nodes"))
                    .font(.system(size: 17, weight: .bold))

                Spacer()

                Button(action: { showHistoryView = true }) {
                    HStack(spacing: 4) {
                        Text(NSLocalizedString("insights.view_all", comment: "View all"))
                            .font(.system(size: 14))
                            .foregroundColor(.primaryGreen)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primaryGreen)
                    }
                }
            }

            // Bug Fix 4: 只显示今日行为记录，避免与"查看全部"重复
            if let todayItem = vizVM.timelineItems.first(where: { $0.isToday }) {
                VStack(spacing: 8) {
                    ForEach(Array(todayItem.behaviors.enumerated()), id: \.offset) { index, behavior in
                        behaviorRow(behavior, isLast: index == todayItem.behaviors.count - 1)
                    }
                }
            } else {
                // 空状态提示
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "bolt.slash")
                            .font(.system(size: 32))
                            .foregroundColor(.gray.opacity(0.5))
                        Text(NSLocalizedString("insights.no_behaviors", comment: "No behaviors"))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 32)
                    Spacer()
                }
            }
        }
    }

    private func timelineDaySection(_ item: TimelineItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 日期标题
            Text(item.dateText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
                .padding(.leading, 4)

            // 当天所有行为
            VStack(spacing: 8) {
                ForEach(Array(item.behaviors.enumerated()), id: \.offset) { index, behavior in
                    behaviorRow(behavior, isLast: index == item.behaviors.count - 1)
                }
            }
        }
    }

    // Bug Fix 4: 添加心情和备注显示
    private func behaviorRow(_ behavior: Behavior, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 时间线
            VStack(spacing: 0) {
                // 图标圆圈
                ZStack {
                    Circle()
                        .fill(behavior.grade.hasPrefix("R") == true ?
                              Color.recoveryBlue.opacity(0.2) : Color.primaryGreen.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: behavior.grade.hasPrefix("R") == true ?
                          "sparkles" : "bolt.fill")
                        .font(.system(size: 16))
                        .foregroundColor(behavior.grade.hasPrefix("R") == true ?
                                         .recoveryBlue : .primaryGreen)
                }

                // 连接线
                if !isLast {
                    Rectangle()
                        .fill(behavior.grade.hasPrefix("R") == true ?
                              Color.recoveryBlue.opacity(0.3) : Color.primaryGreen.opacity(0.3))
                        .frame(width: 2, height: 50)
                }
            }

            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(behavior.name ?? NSLocalizedString("insights.activity", comment: "Activity"))
                    .font(.system(size: 15, weight: .semibold))

                Text("\(behavior.timestamp.formattedTime()) • \(behavior.duration) \(NSLocalizedString("insights.minutes", comment: "Minutes"))")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                // 心情显示
                if behavior.mood > 0 {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= behavior.mood ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundColor(star <= behavior.mood ? .primaryGreen : .gray.opacity(0.3))
                        }
                    }
                }

                // 备注显示
                if let notes = behavior.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }

                if behavior.score > 0 {
                    Text("+\(String(format: "%.0f", behavior.score)) pts")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primaryGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.primaryGreen.opacity(0.1))
                        .cornerRadius(4)
                } else if behavior.score < 0 {
                    Text("\(String(format: "%.0f", behavior.score)) pts")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, 4)

            Spacer()
        }
    }

    // MARK: - Weekly Chart Section

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("insights.weekly_performance", comment: "Weekly performance"))
                .font(.system(size: 17, weight: .bold))

            if vizVM.weeklyData.isEmpty || vizVM.weeklyData.allSatisfy({ $0.totalScore == 0 }) {
                // 空状态提示
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 32))
                            .foregroundColor(.gray.opacity(0.5))
                        Text(NSLocalizedString("insights.no_data", comment: "No data"))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 32)
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            } else {
                // 计算动态最大值
                let maxScore = max(1, vizVM.weeklyData.map { $0.totalScore }.max() ?? 1)

                // 柱状图
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(vizVM.weeklyData.enumerated()), id: \.offset) { index, day in
                        VStack(spacing: 4) {
                            // 数值标签
                            Text(day.totalScore > 0 ? "+\(Int(day.totalScore))" : "\(Int(day.totalScore))")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(day.totalScore >= 0 ? .primaryGreen : .red)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)

                            // 柱子
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 80)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(day.totalScore >= 0 ? Color.primaryGreen : Color.red)
                                    .frame(height: max(4, 80 * day.barHeightRatio(maxScore: maxScore)))
                            }
                            .frame(width: 32)

                            // 星期标签
                            Text(day.weekday.replacingOccurrences(of: "周", with: ""))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(day.isToday ? .primaryGreen : .gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Daily Contribution Section

    private var dailyContributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏带日期选择
            HStack {
                Text(NSLocalizedString("insights.daily_contribution", comment: "Daily contribution"))
                    .font(.system(size: 17, weight: .bold))

                Spacer()

                // 日期选择器
                HStack(spacing: 8) {
                    Button(action: { shiftDate(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primaryGreen)
                    }

                    Text(vizVM.dailyContribution?.dateText ?? "")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)

                    if let contribution = vizVM.dailyContribution, contribution.isToday {
                        Text(NSLocalizedString("insights.today", comment: "Today"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primaryGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primaryGreen.opacity(0.1))
                            .cornerRadius(4)
                    }

                    Button(action: { shiftDate(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primaryGreen)
                    }
                    .disabled(vizVM.dailyContribution?.isToday == true)
                }
            }

            if let contribution = vizVM.dailyContribution, !contribution.items.isEmpty {
                // 汇总信息
                HStack(spacing: 16) {
                    ContributionSummaryItem(
                        label: NSLocalizedString("insights.positive_score", comment: "Positive"),
                        value: "+\(Int(contribution.positiveScore))",
                        color: Color(red: 46/255, green: 125/255, blue: 50/255)
                    )

                    ContributionSummaryItem(
                        label: NSLocalizedString("insights.negative_score", comment: "Negative"),
                        value: "\(Int(contribution.negativeScore))",
                        color: Color(red: 21/255, green: 101/255, blue: 192/255)
                    )

                    ContributionSummaryItem(
                        label: NSLocalizedString("insights.net_score", comment: "Net"),
                        value: contribution.totalScore > 0 ? "+\(Int(contribution.totalScore))" : "\(Int(contribution.totalScore))",
                        color: contribution.totalScore >= 0 ? Color(red: 46/255, green: 125/255, blue: 50/255) : Color(red: 21/255, green: 101/255, blue: 192/255)
                    )
                }

                // 行为贡献网格
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(contribution.items) { item in
                        ContributionCard(item: item, maxAbsScore: contribution.maxAbsScore)
                    }
                }
            } else {
                // 空状态
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 32))
                            .foregroundColor(.gray.opacity(0.5))
                        Text(NSLocalizedString("insights.no_activity", comment: "No activity"))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 32)
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.05))
                )
            }
        }
    }

    private func shiftDate(by days: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: days, to: vizVM.selectedDate) {
            vizVM.selectDate(newDate)
        }
    }

    // MARK: - Helpers

    @MainActor
    private func loadUser() {
        // 刷新 CoreData 上下文以确保获取最新数据
        CoreDataStack.shared.viewContext.refreshAllObjects()

        user = CoreDataManager.shared.fetchOrCreateUser()
        if let user = user {
            print("[DEBUG] InsightsView - User totalPoints: \(user.totalPoints)")
            print("[DEBUG] InsightsView - Behaviors count: \(user.behaviorsArray.count)")
            for (index, behavior) in user.behaviorsArray.enumerated() {
                print("[DEBUG] Behavior \(index): name=\(behavior.name ?? "N/A"), score=\(behavior.score)")
            }
            vizVM.setup(for: user)
            vizVM.refreshAllData()
        }
    }
}

// MARK: - Contribution Card

struct ContributionCard: View {
    let item: ContributionItem
    let maxAbsScore: Double

    var body: some View {
        HStack(spacing: 8) {
            // 等级标识
            Text(item.grade)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(item.textColor(maxAbsScore: maxAbsScore))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(item.textColor(maxAbsScore: maxAbsScore).opacity(0.2))
                )

            // 行为名称和次数
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(item.textColor(maxAbsScore: maxAbsScore))
                    .lineLimit(1)

                if item.count > 1 {
                    Text("×\(item.count)")
                        .font(.system(size: 11))
                        .foregroundColor(item.textColor(maxAbsScore: maxAbsScore).opacity(0.7))
                }
            }

            Spacer()

            // 分数
            Text(item.displayScore)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(item.textColor(maxAbsScore: maxAbsScore))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(item.backgroundColor(maxAbsScore: maxAbsScore))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(item.totalScore >= 0 ? Color(red: 46/255, green: 125/255, blue: 50/255).opacity(0.3) : Color(red: 21/255, green: 101/255, blue: 192/255).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Contribution Summary Item

struct ContributionSummaryItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Preview

struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView()
    }
}
