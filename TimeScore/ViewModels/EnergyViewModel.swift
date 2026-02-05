//
//  EnergyViewModel.swift
//  TimeScore
//
//  精力管理系统
//  对应 Python: src/scoring/energy.py
//

import Foundation
import Combine

/// 精力管理 ViewModel
/// 负责精力计算、自动恢复、R 等级子级别推断
class EnergyViewModel: ObservableObject {

    // MARK: - Constants

    /// 最大精力值
    static let maxEnergy: Double = 120.0

    /// 默认精力值
    static let defaultEnergy: Double = 100.0

    /// 自动恢复速率（每分钟）
    static let recoveryRate: Double = 0.02

    /// 自动恢复触发时间（分钟）
    static let recoveryThreshold: Double = 30.0

    // MARK: - Properties

    @Published var currentEnergy: Double = 100.0
    @Published var isInRecovery: Bool = false

    // MARK: - Public Methods

    /// 计算精力变化
    /// 对应 Python: calculate_energy_change()
    ///
    /// - Parameters:
    ///   - grade: 行为等级
    ///   - duration: 时长（分钟）
    /// - Returns: 精力变化值（负值为消耗，正值为恢复）
    func calculateEnergyChange(grade: String, duration: Int) -> Double {
        guard let config = ScoringViewModel.gradeConfig[grade] else {
            return 0.0
        }

        // 从配置中获取基础精力变化
        let baseChange = config.energyCost * Double(duration)

        // 对于非恢复行为，添加额外的精力消耗系数
        if !isRecoveryGrade(grade) {
            return -baseChange // 消耗精力，返回负值
        } else {
            return -baseChange // 恢复行为，energyCost 已经是负值，所以取反后为正
        }
    }

    /// 应用自动恢复
    /// 对应 Python: apply_auto_recovery()
    ///
    /// 根据上次活动时间计算应恢复的精力
    /// - Parameters:
    ///   - lastActiveTime: 上次活动时间
    ///   - currentTime: 当前时间
    /// - Returns: 恢复的精力值
    func applyAutoRecovery(lastActiveTime: Date, currentTime: Date = Date()) -> Double {
        let timeInterval = currentTime.timeIntervalSince(lastActiveTime)
        let minutes = timeInterval / 60.0

        // 只有当闲置时间超过阈值时才恢复
        guard minutes >= EnergyViewModel.recoveryThreshold else {
            return 0.0
        }

        // 计算可恢复量（扣除阈值时间）
        let recoverableMinutes = minutes - EnergyViewModel.recoveryThreshold
        let recovery = recoverableMinutes * EnergyViewModel.recoveryRate

        return min(recovery, EnergyViewModel.maxEnergy - currentEnergy)
    }

    /// 推断 R 等级子级别
    /// 对应 Python: infer_r_sublevel()
    ///
    /// 根据心情和时长推断 R1/R2/R3
    /// - Parameters:
    ///   - mood: 心情 (1-5)
    ///   - duration: 时长（分钟）
    /// - Returns: R1/R2/R3
    func inferRSublevel(mood: Int, duration: Int) -> String {
        // 高心情 + 适当时长 = 深度恢复
        if mood >= 4 && duration >= 30 {
            return "R3"
        }

        // 中等条件 = 中度恢复
        if mood >= 3 && duration >= 15 {
            return "R2"
        }

        // 其他情况 = 轻度恢复
        return "R1"
    }

    /// 检查是否需要提醒休息
    /// - Returns: 当精力低于 30 时返回 true
    func shouldRest() -> Bool {
        return currentEnergy < 30.0
    }

    /// 检查是否处于高精力状态
    /// - Returns: 当精力高于 70 时返回 true
    func isHighEnergy() -> Bool {
        return currentEnergy > 70.0
    }

    /// 获取精力百分比
    func energyPercentage() -> Double {
        return currentEnergy / EnergyViewModel.maxEnergy
    }

    /// 更新当前精力值
    func updateEnergy(_ energy: Double) {
        currentEnergy = min(EnergyViewModel.maxEnergy, max(0.0, energy))
    }

    /// 增加精力
    func addEnergy(_ delta: Double) {
        updateEnergy(currentEnergy + delta)
    }

    /// 减少精力
    func consumeEnergy(_ amount: Double) {
        updateEnergy(currentEnergy - amount)
    }

    // MARK: - Energy Status

    /// 精力状态描述
    var energyStatusDescription: String {
        switch currentEnergy {
        case 90...120:
            return "精力充沛"
        case 70..<90:
            return "状态良好"
        case 40..<70:
            return "精力一般"
        case 20..<40:
            return "需要休息"
        default:
            return "极度疲劳"
        }
    }

    /// 精力状态颜色
    var energyStatusColor: String {
        switch currentEnergy {
        case 90...120:
            return "#00E600"  // 亮绿
        case 70..<90:
            return "#1ded23"  // 主绿色
        case 40..<70:
            return "#FFEB3B"  // 黄色
        case 20..<40:
            return "#FF9800"  // 橙色
        default:
            return "#F44336"  // 红色
        }
    }

    // MARK: - Private Helpers

    private func isRecoveryGrade(_ grade: String) -> Bool {
        return grade.hasPrefix("R")
    }
}

// MARK: - R Level Configuration

extension EnergyViewModel {
    /// R 等级推荐配置
    struct RLevelRecommendation {
        let level: String
        let minDuration: Int
        let maxDuration: Int
        let minMood: Int
        let description: String

        static let all: [RLevelRecommendation] = [
            RLevelRecommendation(
                level: "R1",
                minDuration: 5,
                maxDuration: 15,
                minMood: 1,
                description: "短暂休息，如喝水、伸展"
            ),
            RLevelRecommendation(
                level: "R2",
                minDuration: 15,
                maxDuration: 30,
                minMood: 3,
                description: "中度休息，如小憩、冥想"
            ),
            RLevelRecommendation(
                level: "R3",
                minDuration: 30,
                maxDuration: 120,
                minMood: 4,
                description: "深度恢复，如午睡、运动"
            )
        ]
    }
}
