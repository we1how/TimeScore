//
//  RecentBehaviorManager.swift
//  TimeScore
//
//  最近行为管理器
//  P0功能: 显示最近使用的3个行为，一键开始计时
//

import Foundation
import CoreData

/// 最近行为管理器
class RecentBehaviorManager: ObservableObject {
    static let shared = RecentBehaviorManager()
    
    @Published var recentBehaviors: [(name: String, grade: String, timestamp: Date)] = []
    
    private let maxRecentCount = 3
    private let userDefaults = UserDefaults.standard
    private let recentKey = "recent_behaviors"
    
    init() {
        loadRecentBehaviors()
    }
    
    // MARK: - 最近行为管理
    
    /// 添加行为到最近使用列表
    func addRecentBehavior(name: String, grade: String) {
        // 移除已存在的相同行为
        recentBehaviors.removeAll { $0.name == name && $0.grade == grade }
        
        // 添加到开头
        recentBehaviors.insert((name: name, grade: grade, timestamp: Date()), at: 0)
        
        // 只保留前3个
        if recentBehaviors.count > maxRecentCount {
            recentBehaviors = Array(recentBehaviors.prefix(maxRecentCount))
        }
        
        // 保存
        saveRecentBehaviors()
    }
    
    /// 获取最近行为
    func getRecentBehaviors() -> [(name: String, grade: String)] {
        return recentBehaviors.map { (name: $0.name, grade: $0.grade) }
    }
    
    /// 清空最近行为
    func clearRecentBehaviors() {
        recentBehaviors.removeAll()
        userDefaults.removeObject(forKey: recentKey)
    }
    
    // MARK: - 持久化
    
    private func saveRecentBehaviors() {
        let data = recentBehaviors.map { [
            "name": $0.name,
            "grade": $0.grade,
            "timestamp": $0.timestamp.timeIntervalSince1970
        ] }
        userDefaults.set(data, forKey: recentKey)
    }
    
    private func loadRecentBehaviors() {
        guard let data = userDefaults.array(forKey: recentKey) as? [[String: Any]] else { return }
        
        recentBehaviors = data.compactMap { item in
            guard let name = item["name"] as? String,
                  let grade = item["grade"] as? String,
                  let timestamp = item["timestamp"] as? TimeInterval else {
                return nil
            }
            return (name: name, grade: grade, timestamp: Date(timeIntervalSince1970: timestamp))
        }
    }
}
