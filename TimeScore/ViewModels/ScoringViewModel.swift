//
//  ScoringViewModel.swift
//  TimeScore
//
//  积分计算系统
//  对应 Python: src/scoring/calculator.py
//

import Foundation
import Combine

/// 积分计算 ViewModel
/// 负责所有积分相关计算逻辑
class ScoringViewModel: ObservableObject {

    // MARK: - Constants

    /// 行为等级配置
    /// 对应 Python: GRADE_CONFIG
    static let gradeConfig: [String: (baseScore: Double, energyCost: Double)] = [
        // 正向行为
        "S":  (baseScore: 1.8,  energyCost: 0.35),  // Breakthrough growth
        "A":  (baseScore: 1.2,  energyCost: 0.25),  // Effective progress
        "B":  (baseScore: 0.7,  energyCost: 0.18),  // Stable maintenance

        // 负面行为
        "C":  (baseScore: -0.5, energyCost: 0.10),  // Time wasting
        "D":  (baseScore: -1.0, energyCost: 0.15),  // Self-harm

        // 恢复行为
        "R1": (baseScore: 0.2,  energyCost: -0.10), // Light relaxation
        "R2": (baseScore: 0.3,  energyCost: -0.20), // Medium recovery
        "R3": (baseScore: 0.4,  energyCost: -0.30)  // Deep recovery
    ]

    // MARK: - Properties

    @Published var lastCalculatedScore: Double = 0.0
    @Published var calculationDetails: CalculationDetails?

    // MARK: - Public Methods

    /// 计算行为得分
    /// 对应 Python: calculate_score()
    ///
    /// 公式: final_score = base_score × duration × (energy_coeff × combo_coeff) × start_bonus × novice_bonus
    ///
    /// - Parameters:
    ///   - grade: 行为等级 (S/A/B/C/D/R1/R2/R3)
    ///   - duration: 时长（分钟）
    ///   - currentEnergy: 当前精力值
    ///   - combo: 连续记录次数（用于连击系数）
    /// - Returns: 最终得分
    func calculateScore(
        grade: String,
        duration: Int,
        currentEnergy: Double,
        combo: Int = 0
    ) -> Double {
        // 获取基础配置
        guard let config = ScoringViewModel.gradeConfig[grade] else {
            print("未知的等级: \(grade)")
            return 0.0
        }

        // 基础分 × 时长
        let baseScore = config.baseScore * Double(duration)

        // 动态系数
        let energyCoeff = calculateEnergyCoefficient(energy: currentEnergy, grade: grade)
        let comboCoeff = calculateComboCoefficient(combo: combo)
        let startBonus = calculateStartBonus()
        let noviceBonus = calculateNoviceBonus(totalBehaviors: 0) // 可从统计中获取

        // 最终计算
        let finalScore = baseScore * energyCoeff * comboCoeff * startBonus * noviceBonus

        // 保存计算详情
        calculationDetails = CalculationDetails(
            baseScore: baseScore,
            energyCoefficient: energyCoeff,
            comboCoefficient: comboCoeff,
            startBonus: startBonus,
            noviceBonus: noviceBonus,
            finalScore: finalScore
        )

        lastCalculatedScore = finalScore
        return finalScore
    }

    /// 计算等级对应的精力消耗
    /// 对应 Python: 从 GRADE_CONFIG 中读取
    func getEnergyCost(for grade: String, duration: Int) -> Double {
        guard let config = ScoringViewModel.gradeConfig[grade] else {
            return 0.0
        }
        return config.energyCost * Double(duration)
    }

    /// 是否是恢复行为（R 等级）
    func isRecoveryGrade(_ grade: String) -> Bool {
        return grade.hasPrefix("R")
    }

    /// 是否是负面行为（C/D 等级）
    func isNegativeGrade(_ grade: String) -> Bool {
        return grade == "C" || grade == "D"
    }

    /// 是否是高效行为（S/A 等级）
    func isHighEfficiencyGrade(_ grade: String) -> Bool {
        return grade == "S" || grade == "A"
    }

    // MARK: - Private Methods

    /// 计算精力系数
    /// 对应 Python: _calculate_energy_coefficient()
    ///
    /// 精力 > 70: 1.0 + (energy - 70) / 100
    /// 精力 30-70: 1.0
    /// 精力 < 30: 0.8 + energy / 150
    private func calculateEnergyCoefficient(energy: Double, grade: String) -> Double {
        // 恢复行为不受精力系数影响
        if isRecoveryGrade(grade) {
            return 1.0
        }

        if energy > 70 {
            return 1.0 + (energy - 70) / 100.0
        } else if energy >= 30 {
            return 1.0
        } else {
            return 0.8 + energy / 150.0
        }
    }

    /// 计算连击系数
    /// 对应 Python: _calculate_combo_coefficient()
    ///
    /// combo > 5: 1.2
    /// combo > 3: 1.1
    /// 其他: 1.0
    private func calculateComboCoefficient(combo: Int) -> Double {
        if combo >= 5 {
            return 1.2
        } else if combo >= 3 {
            return 1.1
        }
        return 1.0
    }

    /// 计算起始时间奖励
    /// 对应 Python: _calculate_start_bonus()
    ///
    /// 早上 5-8 点有额外奖励
    private func calculateStartBonus() -> Double {
        let hour = Calendar.current.component(.hour, from: Date())

        // 早起奖励: 5-8 点
        if hour >= 5 && hour <= 8 {
            return 1.15
        }

        return 1.0
    }

    /// 计算新手奖励
    /// 对应 Python: _calculate_novice_bonus()
    ///
    /// 前 10 个行为有额外奖励
    private func calculateNoviceBonus(totalBehaviors: Int) -> Double {
        if totalBehaviors < 10 {
            return 1.0 + Double(10 - totalBehaviors) * 0.02
        }
        return 1.0
    }
}

// MARK: - Supporting Types

/// 计算详情
struct CalculationDetails {
    let baseScore: Double
    let energyCoefficient: Double
    let comboCoefficient: Double
    let startBonus: Double
    let noviceBonus: Double
    let finalScore: Double

    var description: String {
        """
        基础分: \(String(format: "%.2f", baseScore))
        精力系数: \(String(format: "%.2f", energyCoefficient))
        连击系数: \(String(format: "%.2f", comboCoefficient))
        起始奖励: \(String(format: "%.2f", startBonus))
        新手奖励: \(String(format: "%.2f", noviceBonus))
        最终得分: \(String(format: "%.2f", finalScore))
        """
    }
}

// Note: gradeDisplayName and gradeColor extensions are defined in Extensions.swift
