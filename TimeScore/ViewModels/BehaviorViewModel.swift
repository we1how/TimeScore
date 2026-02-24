//
//  BehaviorViewModel.swift
//  TimeScore
//
//  行为记录 ViewModel
//  对应 Python: main.py 行为记录部分
//

import Foundation
import Combine

/// 行为记录 ViewModel
/// 负责行为记录的状态管理和保存
class BehaviorViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 行为等级 (S/A/B/C/D/R1/R2/R3)
    @Published var grade: String = "B" {
        didSet {
            updateScorePreview()
        }
    }

    /// 行为名称
    @Published var behaviorName: String = ""

    /// 时长（分钟）
    @Published var duration: Int = 30 {
        didSet {
            updateScorePreview()
        }
    }

    /// 记录时间
    @Published var recordTime: Date = Date()

    /// 心情 (1-5)
    @Published var mood: Int = 3 {
        didSet {
            // 如果是 R 等级，根据心情和时长推断子级别
            if grade.hasPrefix("R") {
                grade = energyViewModel.inferRSublevel(mood: mood, duration: duration)
            }
        }
    }

    /// 备注
    @Published var notes: String = ""

    /// 预览得分
    @Published var previewScore: Double = 0.0

    /// 预览精力变化
    @Published var previewEnergyChange: Double = 0.0

    /// 是否显示成功弹窗
    @Published var showSuccessOverlay: Bool = false

    /// 最后记录的结果
    @Published var lastRecordResult: RecordResult?

    // MARK: - Dependencies

    private let scoringViewModel: ScoringViewModel
    private let energyViewModel: EnergyViewModel
    private let dataManager: CoreDataManager

    // MARK: - Available Options

    /// 可选等级
    let availableGrades = ["S", "A", "B", "C", "D", "R1", "R2", "R3"]

    /// 预设行为名称（按等级分类）
    let presetBehaviors: [String: [(name: String, desc: String)]] = [
        "S": [("深度学习", "深度专注学习"), ("创意突破", "创造性工作")],
        "A": [("项目工作", "项目开发"), ("学习新技能", "技能学习")],
        "B": [ ("日常事务", "日常任务")],
        "C": [("无目的刷手机", "无意识浏览"), ("拖延", "任务拖延")],
        "D": [("熬夜", "熬夜不睡"),("负面情绪沉溺", "情绪内耗")],
        "R1": [("喝水", "补充水分"), ("伸展", "身体伸展"), ("深呼吸", "呼吸放松"), ("听音乐", "音乐放松")],
        "R2": [("小憩", "短暂休息"), ("冥想", "冥想练习"), ("散步", "轻松散步"), ("轻度运动", "轻度活动")],
        "R3": [("午睡", "午休睡眠"), ("泡澡", "热水泡澡"), ("瑜伽", "瑜伽练习"), ("户外运动", "户外活动"), ("社交聚会", "社交活动")]
    ]

    /// 用户自定义行为
    @Published var customBehaviors: [String: [(name: String, desc: String)]] = [:]

    // MARK: - Initialization

    init(
        scoringViewModel: ScoringViewModel = ScoringViewModel(),
        energyViewModel: EnergyViewModel = EnergyViewModel(),
        dataManager: CoreDataManager = CoreDataManager.shared
    ) {
        self.scoringViewModel = scoringViewModel
        self.energyViewModel = energyViewModel
        self.dataManager = dataManager

        // 初始化预览
        updateScorePreview()
    }

    // MARK: - Public Methods

    /// 记录行为
    /// 对应 Python: record_behavior()
    ///
    /// 完整的记录流程：计算分数 -> 计算精力变化 -> 保存到 CoreData -> 显示成功
    /// - Parameter user: 关联用户
    /// - Returns: 是否成功
    @discardableResult
    func recordBehavior(for user: User) -> Bool {
        // 1. 计算得分
        let score = scoringViewModel.calculateScore(
            grade: grade,
            duration: duration,
            currentEnergy: user.currentEnergy,
            combo: 0 // 可从历史计算
        )

        print("[DEBUG] Calculated score: \(score), Grade: \(grade), Duration: \(duration)")
        print("[DEBUG] User totalPoints before: \(user.totalPoints)")

        // 2. 计算精力变化
        let energyChange = energyViewModel.calculateEnergyChange(
            grade: grade,
            duration: duration
        )

        // 3. 保存到 CoreData
        let behavior = dataManager.addBehavior(
            to: user,
            grade: grade,
            name: behaviorName.isEmpty ? nil : behaviorName,
            duration: Int32(duration),
            mood: Int16(mood),
            notes: notes.isEmpty ? nil : notes,
            score: score,
            energyChange: energyChange,
            timestamp: recordTime
        )

        print("[DEBUG] User totalPoints after: \(user.totalPoints)")

        // 4. 更新精力 ViewModel
        energyViewModel.updateEnergy(user.currentEnergy)

        // 5. 更新心愿进度
        dataManager.updateAllWishesProgress(for: user)

        // 6. 保存结果并显示成功弹窗
        lastRecordResult = RecordResult(
            behavior: behavior,
            score: score,
            energyChange: energyChange,
            newTotalPoints: user.totalPoints,
            newEnergy: user.currentEnergy
        )

        showSuccessOverlay = true

        // 7. 重置表单
        resetForm()

        // 8. 发送数据更新通知，让首页刷新
        NotificationCenter.default.post(name: .behaviorRecorded, object: nil)

        return true
    }

    /// 快速记录（简化版）
    func quickRecord(grade: String, name: String? = nil, for user: User) {
        self.grade = grade
        self.behaviorName = name ?? ""
        self.duration = 30 // 默认30分钟
        self.mood = 3
        self.notes = ""

        recordBehavior(for: user)
    }

    /// 更新时长（用于步进器）
    func updateDuration(delta: Int) {
        let newDuration = duration + delta
        if newDuration >= 5 && newDuration <= 480 { // 5分钟到8小时
            duration = newDuration
        }
    }

    /// 设置行为名称
    func selectBehavior(_ name: String) {
        behaviorName = name
    }

    /// 获取推荐的行为列表（预设 + 自定义）
    /// R等级特殊处理：返回R1+R2+R3的所有行为
    func recommendedBehaviors() -> [(name: String, desc: String)] {
        if grade.hasPrefix("R") {
            // R等级显示所有R1、R2、R3的行为
            let r1Presets = presetBehaviors["R1"] ?? []
            let r1Customs = customBehaviors["R1"] ?? []
            let r2Presets = presetBehaviors["R2"] ?? []
            let r2Customs = customBehaviors["R2"] ?? []
            let r3Presets = presetBehaviors["R3"] ?? []
            let r3Customs = customBehaviors["R3"] ?? []
            return r1Presets + r1Customs + r2Presets + r2Customs + r3Presets + r3Customs
        } else {
            let presets = presetBehaviors[grade] ?? []
            let customs = customBehaviors[grade] ?? []
            return presets + customs
        }
    }

    /// 加载用户的自定义行为
    func loadCustomBehaviors(for user: User) {
        let behaviors = dataManager.fetchCustomBehaviors(for: user)
        var grouped: [String: [(name: String, desc: String)]] = [:]
        for behavior in behaviors {
            let entry = (name: behavior.name, desc: behavior.behaviorDescription ?? "")
            if grouped[behavior.grade] == nil {
                grouped[behavior.grade] = []
            }
            grouped[behavior.grade]?.append(entry)
        }
        customBehaviors = grouped
    }

    /// 添加自定义行为
    func addCustomBehavior(for user: User, name: String, description: String?, grade: String) {
        let _ = dataManager.addCustomBehavior(to: user, name: name, description: description, grade: grade)
        loadCustomBehaviors(for: user)
    }

    // MARK: - Private Methods

    private func updateScorePreview() {
        // 使用默认精力 100 计算预览
        previewScore = scoringViewModel.calculateScore(
            grade: grade,
            duration: duration,
            currentEnergy: 100.0,
            combo: 0
        )

        previewEnergyChange = energyViewModel.calculateEnergyChange(
            grade: grade,
            duration: duration
        )
    }

    private func resetForm() {
        grade = "B"
        behaviorName = ""
        duration = 30
        mood = 3
        notes = ""
        recordTime = Date()
        updateScorePreview()
    }
}

// MARK: - Supporting Types

/// 记录结果
struct RecordResult {
    let behavior: Behavior
    let score: Double
    let energyChange: Double
    let newTotalPoints: Double
    let newEnergy: Double

    /// 积分变化描述
    var scoreDescription: String {
        if score > 0 {
            return "+\(Int(score)) Points"
        } else {
            return "\(Int(score)) Points"
        }
    }

    /// 精力变化描述
    var energyDescription: String {
        if energyChange > 0 {
            return "恢复 \(Int(energyChange)) 精力"
        } else {
            return "消耗 \(Int(abs(energyChange))) 精力"
        }
    }
}

// MARK: - Form Validation

extension BehaviorViewModel {
    /// 表单是否有效
    var isValid: Bool {
        duration >= 5 && duration <= 480
    }

    /// 验证错误信息
    var validationError: String? {
        if duration < 5 {
            return "时长至少需要 5 分钟"
        }
        if duration > 480 {
            return "时长不能超过 8 小时"
        }
        return nil
    }
}

// MARK: - Notifications

extension Notification.Name {
    /// 行为记录成功通知
    static let behaviorRecorded = Notification.Name("behaviorRecorded")
}
