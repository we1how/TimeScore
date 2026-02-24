//
//  NotificationManager.swift
//  TimeScore
//
//  本地通知管理器
//  P0功能: 每日提醒通知
//

import UserNotifications
import Foundation

/// 通知管理器
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorization()
    }
    
    // MARK: - 授权管理
    
    /// 请求通知权限
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if let error = error {
                    print("通知授权失败: \(error.localizedDescription)")
                }
                completion(granted)
            }
        }
    }
    
    /// 检查授权状态
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - 每日提醒
    
    /// 设置每日提醒
    /// - Parameters:
    ///   - hour: 小时 (0-23)
    ///   - minute: 分钟 (0-59)
    ///   - title: 通知标题
    ///   - body: 通知内容
    ///   - identifier: 唯一标识
    func scheduleDailyReminder(hour: Int, minute: Int, title: String, body: String, identifier: String) {
        guard isAuthorized else {
            print("通知未授权，无法设置提醒")
            return
        }
        
        // 移除旧的同名提醒
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // 添加自定义数据
        content.userInfo = ["type": "daily_reminder", "identifier": identifier]
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("设置提醒失败: \(error.localizedDescription)")
            } else {
                print("已设置每日提醒 [\(identifier)]: \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    /// 设置默认的每日提醒（早晨计划 + 晚上总结）
    func setupDefaultReminders() {
        // 早晨8点：今日计划提醒
        scheduleDailyReminder(
            hour: 8,
            minute: 0,
            title: "🌅 新的一天开始了",
            body: "规划今天的目标，让每一分钟都有价值。点击开始记录你的第一个行为！",
            identifier: "morning_plan"
        )
        
        // 晚上10点：今日总结提醒
        scheduleDailyReminder(
            hour: 22,
            minute: 0,
            title: "🌙 今日回顾时间",
            body: "回顾一下今天的时间分配，看看你的成长轨迹。连续打卡进行中！",
            identifier: "evening_summary"
        )
    }
    
    /// 设置自定义提醒
    /// - Parameters:
    ///   - time: 提醒时间
    ///   - title: 标题
    ///   - body: 内容
    func scheduleCustomReminder(at time: Date, title: String, body: String) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        guard let hour = components.hour, let minute = components.minute else { return }
        
        let identifier = "custom_\(Int(Date().timeIntervalSince1970))"
        scheduleDailyReminder(hour: hour, minute: minute, title: title, body: body, identifier: identifier)
    }
    
    // MARK: -  streak 相关通知
    
    /// 设置 streak 中断警告（晚上11点如果今天还没记录）
    func scheduleStreakWarning(streak: Int) {
        guard isAuthorized, streak > 0 else { return }
        
        var dateComponents = DateComponents()
        dateComponents.hour = 23
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = "⚠️ 连续打卡即将中断！"
        content.body = "你已经连续打卡 \(streak) 天，今天还没记录行为。再晚就来不及了！"
        content.sound = .defaultCritical
        
        let request = UNNotificationRequest(identifier: "streak_warning", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// 发送即时通知（用于测试或特殊事件）
    func sendImmediateNotification(title: String, body: String) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "immediate_\(UUID().uuidString)",
            content: content,
            trigger: nil // 立即触发
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - 取消通知
    
    /// 取消特定通知
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// 取消所有通知
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// 获取所有待发送的通知
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
}
