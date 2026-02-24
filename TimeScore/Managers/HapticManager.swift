//
//  HapticManager.swift
//  TimeScore
//
//  震动反馈管理器
//  P0功能: 计时器开始/暂停/保存时触发震动
//

import UIKit
import CoreHaptics

/// 震动反馈管理器
class HapticManager {
    static let shared = HapticManager()
    
    private var hapticEngine: CHHapticEngine?
    private var supportsHaptics = false
    
    init() {
        setupHaptics()
    }
    
    /// 初始化触觉引擎
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            supportsHaptics = false
            return
        }
        
        supportsHaptics = true
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            // 处理引擎停止后的重启
            hapticEngine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason)")
                do {
                    try self.hapticEngine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
        } catch {
            print("Failed to create haptic engine: \(error)")
            supportsHaptics = false
        }
    }
    
    // MARK: - 基础震动反馈
    
    /// 轻触反馈（选择行为、切换等级）
    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// 中等反馈（开始计时）
    func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// 强反馈（暂停计时、保存记录）
    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// 成功反馈（保存成功）
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// 警告反馈（精力不足等）
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// 错误反馈
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - 高级触觉模式
    
    /// 计时器开始的震动模式
    func timerStart() {
        if supportsHaptics {
            playPattern(events: [
                (0.0, 0.5),      // 立即开始，中等强度
                (0.1, 0.3)       // 100ms后轻震
            ])
        } else {
            mediumImpact()
        }
    }
    
    /// 计时器暂停的震动模式
    func timerPause() {
        if supportsHaptics {
            playPattern(events: [
                (0.0, 0.6),      // 立即强震
                (0.15, 0.2)      // 150ms后轻震
            ])
        } else {
            heavyImpact()
        }
    }
    
    /// 保存成功的震动模式（庆祝感）
    func saveSuccess() {
        if supportsHaptics {
            playPattern(events: [
                (0.0, 0.4),
                (0.08, 0.6),
                (0.16, 0.8),
                (0.24, 1.0)      // 渐强的四连震
            ])
        } else {
            success()
        }
    }
    
    /// 连续打卡的震动（特殊奖励感）
    func streakMilestone() {
        if supportsHaptics {
            playPattern(events: [
                (0.0, 0.3),
                (0.05, 0.5),
                (0.1, 0.7),
                (0.15, 0.9),
                (0.2, 1.0),
                (0.25, 0.8),
                (0.3, 0.6),
                (0.35, 0.4)      // 波浪形震动
            ])
        } else {
            success()
        }
    }
    
    // MARK: - Private Helpers
    
    /// 播放自定义触觉模式
    private func playPattern(events: [(time: Double, intensity: Double)]) {
        guard supportsHaptics, let engine = hapticEngine else { return }
        
        var hapticEvents = [CHHapticEvent]()
        
        for event in events {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(event.intensity))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(event.intensity * 0.5))
            
            let hapticEvent = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: event.time
            )
            hapticEvents.append(hapticEvent)
        }
        
        do {
            let pattern = try CHHapticPattern(events: hapticEvents, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
}
