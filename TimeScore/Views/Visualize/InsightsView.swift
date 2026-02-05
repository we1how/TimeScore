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

                // 一致性热力图
                heatmapSection

                // 底部空间
                Spacer().frame(height: 40)
            }
            .padding(.horizontal)
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            loadUser()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // 头像
            Circle()
                .fill(Color.primaryGreen.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.primaryGreen)
                )

            Spacer()

            Text("Insights")
                .font(.system(size: 17, weight: .bold))

            Spacer()

            Button(action: {}) {
                Image(systemName: "gear")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
            }
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
                title: "Total Points",
                value: stats?.totalPoints.pointsDisplay ?? "0",
                color: .black
            )

            statCard(
                title: "Efficiency",
                value: stats?.efficiencyText ?? "0%",
                color: .primaryGreen
            )

            statCard(
                title: "Streak",
                value: "\(stats?.streak ?? 0)",
                icon: "🔥",
                color: .black
            )

            statCard(
                title: "Avg Mood",
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
            Text("Behavior Nodes")
                .font(.system(size: 17, weight: .bold))

            VStack(spacing: 0) {
                ForEach(vizVM.timelineItems.prefix(5), id: \.date) { item in
                    timelineRow(item)
                }
            }
        }
    }

    private func timelineRow(_ item: TimelineItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 时间线
            VStack(spacing: 0) {
                // 图标圆圈
                ZStack {
                    Circle()
                        .fill(item.behaviors.first?.grade.hasPrefix("R") == true ?
                              Color.recoveryBlue.opacity(0.2) : Color.primaryGreen.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: item.behaviors.first?.grade.hasPrefix("R") == true ?
                          "sparkles" : "bolt.fill")
                        .font(.system(size: 16))
                        .foregroundColor(item.behaviors.first?.grade.hasPrefix("R") == true ?
                                         .recoveryBlue : .primaryGreen)
                }

                // 连接线
                if !Calendar.current.isDateInToday(item.date) {
                    Rectangle()
                        .fill(item.behaviors.first?.grade.hasPrefix("R") == true ?
                              Color.recoveryBlue.opacity(0.3) : Color.primaryGreen.opacity(0.3))
                        .frame(width: 2, height: 40)
                }
            }

            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(item.behaviors.first?.name ?? "Activity")
                    .font(.system(size: 15, weight: .semibold))

                Text("\(item.date.formattedTime()) • \(item.behaviorCount) behaviors")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                if item.totalScore > 0 {
                    Text("+\(Int(item.totalScore)) pts")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primaryGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.primaryGreen.opacity(0.1))
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
            Text("Weekly Performance")
                .font(.system(size: 17, weight: .bold))

            // 柱状图
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(vizVM.weeklyData, id: \.date) { day in
                    VStack(spacing: 6) {
                        // 柱子
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primaryGreen.opacity(0.2))
                                .frame(height: 80)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primaryGreen)
                                .frame(height: max(4, 80 * day.barHeightRatio))
                        }
                        .frame(width: 32)

                        // 星期标签
                        Text(day.weekday.prefix(1))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
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

    // MARK: - Heatmap Section

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Consistency")
                .font(.system(size: 17, weight: .bold))

            VStack(spacing: 12) {
                // 热力图网格
                if let heatmap = vizVM.heatmapData {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                        ForEach(heatmap.cells, id: \.date) { cell in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(cell.intensity == 0 ? Color.gray.opacity(0.1) : Color.primaryGreen)
                                .opacity(cell.opacity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }

                // 图例
                HStack {
                    Text("Less")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)

                    HStack(spacing: 3) {
                        ForEach([0.1, 0.3, 0.5, 0.8, 1.0], id: \.self) { opacity in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.primaryGreen)
                                .opacity(opacity)
                                .frame(width: 10, height: 10)
                        }
                    }

                    Text("More")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
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

    // MARK: - Helpers

    private func loadUser() {
        user = CoreDataManager.shared.fetchOrCreateUser()
        if let user = user {
            vizVM.setup(for: user)
        }
    }
}

// MARK: - Preview

struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView()
    }
}
