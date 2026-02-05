//
//  HomeView.swift
//  TimeScore
//
//  首页/快速记录界面
//  对应 UI 原型: 首页+简易记录行为界面.html
//

import SwiftUI

struct HomeView: View {

    // MARK: - Properties

    @StateObject private var behaviorVM = BehaviorViewModel()
    @StateObject private var energyVM = EnergyViewModel()

    @State private var user: User?
    @State private var showDetailRecord = false
    @State private var showBehaviorPicker = false

    // 秒表相关状态
    @State private var isRunning = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var startTime: Date?

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部工具栏
                topBar

                // 主内容（可滚动）
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // 积分和能量区域
                        scoreAndEnergySection

                        // 等级选择器
                        gradeSelector

                        // 行为选择区域（轮播或提示文本）
                        behaviorSelectionArea

                        // 秒表显示区域
                        stopwatchSection

                        Spacer(minLength: 20)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .sheet(isPresented: $showDetailRecord) {
            DetailRecordView()
        }
        .sheet(isPresented: $showBehaviorPicker) {
            BehaviorPickerView(
                selectedGrade: behaviorVM.grade,
                onSelect: { name in
                    behaviorVM.selectBehavior(name)
                }
            )
        }
        .fullScreenCover(isPresented: $behaviorVM.showSuccessOverlay) {
            if let result = behaviorVM.lastRecordResult {
                SuccessOverlayView(result: result) {
                    behaviorVM.showSuccessOverlay = false
                    // 重置秒表
                    resetStopwatch()
                }
            }
        }
        .onAppear {
            loadUser()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()

            // 搜索行为按钮
            Button(action: { showBehaviorPicker = true }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Score and Energy

    private var scoreAndEnergySection: some View {
        VStack(spacing: 12) {
            // Total Points 标签
            Text("Total Points")
                .font(.system(size: 10, weight: .medium))
                .tracking(2)
                .foregroundColor(.gray)
                .textCase(.uppercase)

            // 大号积分显示
            Text("\(Int(user?.totalPoints ?? 0))")
                .font(.system(size: 72, weight: .thin, design: .rounded))
                .tracking(-2)
                .foregroundColor(.black)

            // 能量指示器
            HStack(spacing: 8) {
                Text("\(Int(user?.currentEnergy ?? 100))% Energy")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.secondaryText)

                // 能量进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 2)

                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.vibrantGreen)
                            .frame(
                                width: geometry.size.width * ((user?.currentEnergy ?? 100) / 100.0),
                                height: 2
                            )
                    }
                }
                .frame(width: 100, height: 2)
            }
            .frame(maxWidth: 200)
        }
    }

    // MARK: - Grade Selector

    private var gradeSelector: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(["S", "A", "B", "C", "D", "R"], id: \.self) { grade in
                    gradeButton(grade)
                }
            }

            // 等级描述
            Text(currentGradeDescription)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.2), value: behaviorVM.grade)
        }
    }

    // 当前等级描述
    private var currentGradeDescription: String {
        let grade = behaviorVM.grade
        if grade.hasPrefix("S") { return "深度工作 · 高价值产出" }
        if grade.hasPrefix("A") { return "高效产出 · 专注执行" }
        if grade.hasPrefix("B") { return "日常事务 · 维持运转" }
        if grade.hasPrefix("C") { return "低效行为 · 时间浪费" }
        if grade.hasPrefix("D") { return "消极行为 · 损害成长" }
        if grade.hasPrefix("R") { return "恢复精力 · 充电休息" }
        return "选择等级开始计时"
    }

    private func gradeButton(_ grade: String) -> some View {
        let isSelected = behaviorVM.grade.hasPrefix(grade)

        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                // 设置新等级
                let newGrade = grade == "R" ? "R2" : grade
                behaviorVM.grade = newGrade

                // 如果正在计时，先停止
                if isRunning {
                    pauseTimer()
                }

                // 自动选择该等级的第一个推荐行为
                let recommendedBehaviors = behaviorVM.recommendedBehaviors()
                if let firstBehavior = recommendedBehaviors.first {
                    behaviorVM.selectBehavior(firstBehavior.name)
                }
            }
        }) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.vibrantGreen)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.vibrantGreen.opacity(0.3), radius: 6, x: 0, y: 3)
                }

                Text(grade)
                    .font(.system(size: isSelected ? 20 : 16, weight: isSelected ? .bold : .light, design: .rounded))
                    .italic(!isSelected)
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
            }
            .frame(width: 44, height: 44)
        }
    }

    // MARK: - Stopwatch Section

    private var stopwatchSection: some View {
        VStack(spacing: 16) {
            // 秒表显示
            Text(formattedTime)
                .font(.system(size: 56, weight: .light, design: .monospaced))
                .foregroundColor(isRunning ? .vibrantGreen : .black)
                .tracking(2)

            // 预计得分
//            if elapsedTime > 0 {
//                Text("预计获得 \(Int(behaviorVM.previewScore * (elapsedTime / 60.0))) 分")
//                    .font(.system(size: 14))
//                    .foregroundColor(.secondaryText)
//            }

            // 播放/暂停按钮
            Button(action: {
                if isRunning {
                    pauseTimer()
                } else {
                    startTimer()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.vibrantGreen)
                        .frame(width: 80, height: 80)
                        .shadow(color: canStartTimer ? Color.vibrantGreen.opacity(0.4) : Color.clear, radius: 12, x: 0, y: 6)

                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.leading, isRunning ? 0 : 4)
                }
            }
            .disabled(!canStartTimer)
//            .opacity(canStartTimer ? 1.0 : 0.5)

            // 停止并保存按钮（仅在暂停时显示）
            if !isRunning && elapsedTime > 0 {
                Button(action: {
                    saveRecord()
                }) {
                    Text("完成并保存")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 160, height: 48)
                        .background(Color.vibrantGreen)
                        .cornerRadius(24)
                }

                Button(action: {
                    resetStopwatch()
                }) {
                    Text("放弃")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // 是否可以开始计时（已选择有效行为）
    private var canStartTimer: Bool {
        !behaviorVM.behaviorName.isEmpty &&
        behaviorVM.recommendedBehaviors().contains(where: { $0.name == behaviorVM.behaviorName })
    }

    // 格式化时间显示
    private var formattedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    // MARK: - Timer Functions

    private func startTimer() {
        guard canStartTimer else { return }

        isRunning = true
        startTime = Date().addingTimeInterval(-elapsedTime)

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let startTime = startTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func resetStopwatch() {
        stopTimer()
        isRunning = false
        elapsedTime = 0
        startTime = nil
    }

    private func saveRecord() {
        // 将秒表时间转换为分钟，更新 duration
        let minutes = Int(elapsedTime / 60)
        behaviorVM.duration = max(1, minutes) // 至少 1 分钟

        // 保存记录
        if let user = user {
            behaviorVM.recordBehavior(for: user)
        }
    }

    // MARK: - Behavior Selection Area

    private var behaviorSelectionArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 分类标题
            HStack {
                Text(gradeLabel)
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 20)

            // 水平滚动的行为标签
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    let behaviors = behaviorVM.recommendedBehaviors()
                    ForEach(0..<behaviors.count, id: \.self) { index in
                        behaviorPill(behaviors[index])
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .frame(height: 80)
    }

    // 根据等级返回标签文字
    private var gradeLabel: String {
        let grade = behaviorVM.grade
        if grade.hasPrefix("S") { return "S级 · 深度工作" }
        if grade.hasPrefix("A") { return "A级 · 高效产出" }
        if grade.hasPrefix("B") { return "B级 · 日常事务" }
        if grade.hasPrefix("C") { return "C级 · 低效行为" }
        if grade.hasPrefix("D") { return "D级 · 消极行为" }
        if grade.hasPrefix("R") { return "R级 · 恢复精力" }
        return "推荐行为"
    }

    private func behaviorPill(_ behavior: (name: String, desc: String)) -> some View {
        let isSelected = behaviorVM.behaviorName == behavior.name

        return Button(action: {
            withAnimation(.easeOut(duration: 0.2)) {
                // 如果正在计时，先停止
                if isRunning {
                    pauseTimer()
                }
                behaviorVM.selectBehavior(behavior.name)
            }
        }) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(behavior.name)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? .white : .black.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.vibrantGreen : Color.gray.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helpers

    private func loadUser() {
        user = CoreDataManager.shared.fetchOrCreateUser()
        if let user = user {
            energyVM.updateEnergy(user.currentEnergy)
        }
    }
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
