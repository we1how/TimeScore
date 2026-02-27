//
//  HomeView.swift
//  TimeScore
//
//  首页/快速记录界面
//  对应 UI 原型: 首页+简易记录行为界面.html
//  P0更新: 添加震动反馈、连续打卡显示、最近行为快捷标签
//

import SwiftUI

struct HomeView: View {

    // MARK: - Properties

    @StateObject private var behaviorVM = BehaviorViewModel()
    @StateObject private var energyVM = EnergyViewModel()
    @StateObject private var recentManager = RecentBehaviorManager.shared

    @State private var user: User?
    @State private var showDetailRecord = false
    @State private var showBehaviorPicker = false

    // 秒表相关状态
    @State private var isRunning = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var startTime: Date?

    // P0: 统计数据
    @State private var streakDays = 0
    @State private var showStreakAnimation = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Bug Fix 3: 使用系统背景色支持暗黑模式
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部工具栏
                topBar

                // 主内容（可滚动）
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // P0: 连续打卡显示
                        streakSection

                        // 积分和能量区域
                        scoreAndEnergySection

                        // P0: 最近行为快捷标签
                        recentBehaviorSection

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
            loadStreak()
            // Bug Fix 1: 加载自定义行为以确保显示最新数据
            if let user = user {
                behaviorVM.loadCustomBehaviors(for: user)
            }
            // 如果之前有正在进行的计时，恢复它
            if isRunning && elapsedTime > 0 {
                startTimer()
            }
            // P0: 请求通知权限
            NotificationManager.shared.requestAuthorization { granted in
                if granted {
                    NotificationManager.shared.setupDefaultReminders()
                }
            }
        }
        .onDisappear {
            // 暂停计时器但保留状态，这样切回来可以继续
            pauseTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: .behaviorRecorded)) { _ in
            // 当行为记录成功时刷新用户数据和最近行为
            loadUser()
            loadStreak()
            // P0: 添加震动反馈
            HapticManager.shared.saveSuccess()
            // P0: 记录最近行为
            if let lastResult = behaviorVM.lastRecordResult {
                recentManager.addRecentBehavior(
                    name: lastResult.behavior.name ?? "",
                    grade: lastResult.behavior.grade ?? "B"
                )
            }
        }
    }

    // MARK: - P0: Streak Section

    private var streakSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 16))
                .foregroundColor(.orange)
                .scaleEffect(showStreakAnimation ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: showStreakAnimation)

            Text(NSLocalizedString("home.streak.title", comment: "Streak title"))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)

            Text("\(streakDays)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.orange)

            Text(NSLocalizedString("home.streak.days", comment: "Days"))
                .font(.system(size: 12))
                .foregroundColor(.gray)

            if streakDays >= 7 {
                Text("🔥")
                    .font(.system(size: 14))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(20)
        .onTapGesture {
            withAnimation {
                showStreakAnimation = true
                HapticManager.shared.streakMilestone()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showStreakAnimation = false
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()

            // 搜索行为按钮
            Button(action: {
                HapticManager.shared.lightImpact()
                showBehaviorPicker = true
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.primary)
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
            Text(NSLocalizedString("home.total_points", comment: "Total points"))
                .font(.system(size: 10, weight: .medium))
                .tracking(2)
                .foregroundColor(.gray)
                .textCase(.uppercase)

            // 大号积分显示
            Text("\(String(format: "%.0f", user?.totalPoints ?? 0))")
                .font(.system(size: 72, weight: .thin, design: .rounded))
                .tracking(-2)
                .foregroundColor(.primary)

            // 能量指示器
            HStack(spacing: 8) {
                Text(NSLocalizedString("home.energy", comment: "Energy"))
                    .font(.system(size: 10, weight: .medium))
                    .tracking(2)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)

                // 能量进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 2)

                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.vibrantGreen)
                            .frame(
                                width: geometry.size.width * ((user?.currentEnergy ?? 100) / 120.0),
                                height: 2
                            )
                    }
                }
                .frame(width: 100, height: 2)

                Text("\(Int(user?.currentEnergy ?? 100))/120")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: 300)
        }
    }

    // MARK: - P0: Recent Behavior Section

    private var recentBehaviorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("home.recent_used", comment: "Recent used"))
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)

                Spacer()

                if !recentManager.recentBehaviors.isEmpty {
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        recentManager.clearRecentBehaviors()
                    }) {
                        Text(NSLocalizedString("home.clear", comment: "Clear"))
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 20)

            // 最近行为标签
            if recentManager.recentBehaviors.isEmpty {
                Text(NSLocalizedString("home.recent_empty_hint", comment: "Recent empty hint"))
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(recentManager.recentBehaviors, id: \.timestamp) { behavior in
                            recentBehaviorPill(behavior)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .frame(height: recentManager.recentBehaviors.isEmpty ? 50 : 80)
    }

    private func recentBehaviorPill(_ behavior: (name: String, grade: String, timestamp: Date)) -> some View {
        Button(action: {
            HapticManager.shared.mediumImpact()
            withAnimation(.easeOut(duration: 0.2)) {
                // 设置等级和行为
                behaviorVM.grade = behavior.grade
                behaviorVM.selectBehavior(behavior.name)
            }
        }) {
            HStack(spacing: 6) {
                // 等级标识
                Text(behavior.grade.prefix(1))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(gradeColor(behavior.grade))
                    .clipShape(Circle())

                Text(behavior.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.08))
            .overlay(
                Capsule()
                    .stroke(gradeColor(behavior.grade).opacity(0.3), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isRunning)
        .opacity(isRunning ? 0.5 : 1.0)
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade.prefix(1) {
        case "S": return Color(red: 0.2, green: 0.8, blue: 0.4)
        case "A": return Color(red: 0.3, green: 0.7, blue: 0.9)
        case "B": return Color(red: 0.5, green: 0.5, blue: 0.5)
        case "C": return Color(red: 0.9, green: 0.6, blue: 0.2)
        case "D": return Color(red: 0.9, green: 0.3, blue: 0.3)
        case "R": return Color(red: 0.5, green: 0.4, blue: 0.9)
        default: return Color.gray
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
        if grade.hasPrefix("S") { return NSLocalizedString("home.grade.desc.s", comment: "Grade S description") }
        if grade.hasPrefix("A") { return NSLocalizedString("home.grade.desc.a", comment: "Grade A description") }
        if grade.hasPrefix("B") { return NSLocalizedString("home.grade.desc.b", comment: "Grade B description") }
        if grade.hasPrefix("C") { return NSLocalizedString("home.grade.desc.c", comment: "Grade C description") }
        if grade.hasPrefix("D") { return NSLocalizedString("home.grade.desc.d", comment: "Grade D description") }
        if grade.hasPrefix("R") { return NSLocalizedString("home.grade.desc.r", comment: "Grade R description") }
        return NSLocalizedString("home.grade.desc.default", comment: "Default grade description")
    }

    private func gradeButton(_ grade: String) -> some View {
        let isSelected = behaviorVM.grade.hasPrefix(grade)

        return Button(action: {
            HapticManager.shared.lightImpact()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                // 设置新等级
                let newGrade = grade == "R" ? "R2" : grade
                behaviorVM.grade = newGrade

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
        .disabled(isRunning)
        .opacity(isRunning ? 0.5 : 1.0)
    }

    // MARK: - Stopwatch Section

    private var stopwatchSection: some View {
        VStack(spacing: 16) {
            // 秒表显示
            Text(formattedTime)
                .font(.system(size: 56, weight: .light, design: .monospaced))
                .foregroundColor(isRunning ? .vibrantGreen : .primary)
                .tracking(2)

            // 播放/暂停按钮
            Button(action: {
                if isRunning {
                    HapticManager.shared.timerPause()
                    pauseTimer()
                } else {
                    HapticManager.shared.timerStart()
                    startTimer()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(canStartTimer ? Color.vibrantGreen : Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .shadow(color: canStartTimer ? Color.vibrantGreen.opacity(0.4) : Color.clear, radius: 12, x: 0, y: 6)

                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.leading, isRunning ? 0 : 4)
                }
            }
            .disabled(!canStartTimer)

            // 停止并保存按钮（仅在暂停时显示）
            if !isRunning && elapsedTime > 0 {
                Button(action: {
                    HapticManager.shared.heavyImpact()
                    saveRecord()
                }) {
                    Text(NSLocalizedString("home.timer.save", comment: "Save timer"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 160, height: 48)
                        .background(Color.vibrantGreen)
                        .cornerRadius(24)
                }

                Button(action: {
                    HapticManager.shared.lightImpact()
                    resetStopwatch()
                }) {
                    Text(NSLocalizedString("home.timer.cancel", comment: "Cancel timer"))
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

        // Bug Fix: 更新记录时间为当前时间，避免使用 ViewModel 初始化时的旧时间
        behaviorVM.recordTime = Date()

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
        if grade.hasPrefix("S") { return NSLocalizedString("home.grade.s", comment: "Grade S label") }
        if grade.hasPrefix("A") { return NSLocalizedString("home.grade.a", comment: "Grade A label") }
        if grade.hasPrefix("B") { return NSLocalizedString("home.grade.b", comment: "Grade B label") }
        if grade.hasPrefix("C") { return NSLocalizedString("home.grade.c", comment: "Grade C label") }
        if grade.hasPrefix("D") { return NSLocalizedString("home.grade.d", comment: "Grade D label") }
        if grade.hasPrefix("R") { return NSLocalizedString("home.grade.r", comment: "Grade R label") }
        return NSLocalizedString("home.recommended", comment: "Recommended label")
    }

    private func behaviorPill(_ behavior: (name: String, desc: String)) -> some View {
        let isSelected = behaviorVM.behaviorName == behavior.name

        return Button(action: {
            HapticManager.shared.lightImpact()
            withAnimation(.easeOut(duration: 0.2)) {
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
            .foregroundColor(isSelected ? .white : .primary)
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
        .disabled(isRunning)
        .opacity(isRunning ? 0.5 : 1.0)
    }

    // MARK: - Helpers

    private func loadUser() {
        // 刷新 CoreData 上下文以确保获取最新数据
        CoreDataStack.shared.viewContext.refreshAllObjects()

        user = CoreDataManager.shared.fetchOrCreateUser()
        if let user = user {
            // Bug Fix 7: 检查并执行每日精力重置
            let wasReset = CoreDataManager.shared.checkAndResetDailyEnergy(for: user)
            if wasReset {
                // 如果重置了，更新 ViewModel
                energyVM.updateEnergy(EnergyViewModel.defaultEnergy)
            } else {
                energyVM.updateEnergy(user.currentEnergy)
            }
        }
    }

    private func loadStreak() {
        if let user = user {
            let stats = CoreDataManager.shared.getStatistics(for: user)
            streakDays = stats.streak

            // 如果 streak 达到里程碑，触发特殊效果
            if streakDays > 0 && streakDays % 7 == 0 {
                withAnimation {
                    showStreakAnimation = true
                }
            }
        }
    }
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
