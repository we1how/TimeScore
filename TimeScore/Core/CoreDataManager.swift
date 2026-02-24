//
//  CoreDataManager.swift
//  TimeScore
//
//  CoreData 数据访问层
//  对应 Python: db/sqlite.py 的数据操作
//

import CoreData
import Foundation

/// CoreData 管理器
/// 封装所有数据访问操作，提供高级业务方法
class CoreDataManager: ObservableObject {

    // MARK: - Properties

    static let shared = CoreDataManager()

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    // MARK: - User Operations

    /// 获取或创建默认用户
    /// 对应 Python: get_or_create_user()
    func fetchOrCreateUser(id: Int64 = 1) -> User {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)

        do {
            if let user = try context.fetch(request).first {
                return user
            }
        } catch {
            print("获取用户失败: \(error)")
        }

        // 创建新用户
        let user = User(context: context)
        user.id = id
        user.totalPoints = 0.0
        user.currentEnergy = 120.0
        user.lastResetDate = Date()
        saveContext()

        return user
    }

    /// 更新用户积分
    func updateUserPoints(user: User, delta: Double) {
        user.totalPoints += delta
        saveContext()
    }

    /// 更新用户精力
    func updateUserEnergy(user: User, energy: Double) {
        user.currentEnergy = min(120.0, max(0.0, energy)) // 上限120，下限0
        saveContext()
    }

    // MARK: - Behavior Operations

    /// 添加行为记录
    /// 对应 Python: add_behavior()
    /// - Parameters:
    ///   - user: 关联用户
    ///   - grade: 行为等级 (S/A/B/C/D/R1/R2/R3)
    ///   - name: 行为名称
    ///   - duration: 时长（分钟）
    ///   - mood: 心情 (1-5)
    ///   - notes: 备注（可选）
    ///   - score: 计算得分
    ///   - energyChange: 精力变化
    /// - Returns: 创建的行为记录
    @discardableResult
    func addBehavior(
        to user: User,
        grade: String,
        name: String? = nil,
        duration: Int32,
        mood: Int16,
        notes: String? = nil,
        score: Double,
        energyChange: Double,
        timestamp: Date? = nil
    ) -> Behavior {
        let behavior = Behavior(context: context)
        behavior.id = UUID()
        behavior.grade = grade
        behavior.name = name
        behavior.duration = duration
        behavior.mood = mood
        behavior.timestamp = timestamp ?? Date()
        behavior.notes = notes
        behavior.score = score
        behavior.energyChange = energyChange
        behavior.user = user

        // 更新用户数据
        user.totalPoints += score
        user.currentEnergy = min(120.0, max(0.0, user.currentEnergy + energyChange))

        saveContext()
        return behavior
    }

    /// 获取用户行为记录
    /// 对应 Python: fetch_behaviors()
    func fetchBehaviors(
        for user: User,
        from startDate: Date? = nil,
        to endDate: Date? = nil
    ) -> [Behavior] {
        let request: NSFetchRequest<Behavior> = Behavior.fetchRequest()

        var predicates: [NSPredicate] = [
            NSPredicate(format: "user == %@", user)
        ]

        if let startDate = startDate {
            predicates.append(NSPredicate(format: "timestamp >= %@", startDate as NSDate))
        }

        if let endDate = endDate {
            predicates.append(NSPredicate(format: "timestamp <= %@", endDate as NSDate))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("获取行为记录失败: \(error)")
            return []
        }
    }

    /// 获取今日行为记录
    func fetchTodayBehaviors(for user: User) -> [Behavior] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return fetchBehaviors(for: user, from: startOfDay, to: endOfDay)
    }

    /// 删除行为记录
    func deleteBehavior(_ behavior: Behavior) {
        // 回滚积分和精力
        if let user = behavior.user as? User {
            user.totalPoints -= behavior.score
            user.currentEnergy -= behavior.energyChange
        }

        context.delete(behavior)
        saveContext()
    }

    // MARK: - Custom Behavior Operations

    /// 添加自定义行为模板
    @discardableResult
    func addCustomBehavior(to user: User, name: String, description: String?, grade: String) -> CustomBehavior {
        let customBehavior = CustomBehavior(context: context)
        customBehavior.id = UUID()
        customBehavior.name = name
        customBehavior.behaviorDescription = description
        customBehavior.grade = grade
        customBehavior.createdAt = Date()
        customBehavior.user = user

        saveContext()
        return customBehavior
    }

    /// 获取用户的所有自定义行为
    func fetchCustomBehaviors(for user: User) -> [CustomBehavior] {
        let request: NSFetchRequest<CustomBehavior> = CustomBehavior.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("获取自定义行为失败: \(error)")
            return []
        }
    }

    /// 按等级获取自定义行为
    func fetchCustomBehaviors(for user: User, grade: String) -> [CustomBehavior] {
        let request: NSFetchRequest<CustomBehavior> = CustomBehavior.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND grade == %@", user, grade)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("获取自定义行为失败: \(error)")
            return []
        }
    }

    /// 更新自定义行为
    func updateCustomBehavior(_ customBehavior: CustomBehavior, name: String? = nil, description: String? = nil, grade: String? = nil) {
        if let name = name {
            customBehavior.name = name
        }
        if let description = description {
            customBehavior.behaviorDescription = description
        }
        if let grade = grade {
            customBehavior.grade = grade
        }
        saveContext()
    }

    /// 删除自定义行为
    func deleteCustomBehavior(_ customBehavior: CustomBehavior) {
        context.delete(customBehavior)
        saveContext()
    }

    // MARK: - Wish Operations

    /// 添加心愿
    /// 对应 Python: add_wish()
    @discardableResult
    func addWish(to user: User, name: String, cost: Double) -> Wish {
        let wish = Wish(context: context)
        wish.id = UUID()
        wish.name = name
        wish.cost = cost
        wish.status = "pending"
        wish.createdAt = Date()
        wish.progress = min(1.0, user.totalPoints / cost)
        wish.user = user

        saveContext()
        return wish
    }

    /// 获取用户心愿列表
    func fetchWishes(for user: User, status: String? = nil) -> [Wish] {
        let request: NSFetchRequest<Wish> = Wish.fetchRequest()

        var predicates: [NSPredicate] = [
            NSPredicate(format: "user == %@", user)
        ]

        if let status = status {
            predicates.append(NSPredicate(format: "status == %@", status))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("获取心愿列表失败: \(error)")
            return []
        }
    }

    /// 兑换心愿
    /// 对应 Python: redeem_wish()
    func redeemWish(_ wish: Wish, for user: User) -> Bool {
        guard wish.status == "pending" && user.totalPoints >= wish.cost else {
            return false
        }

        user.totalPoints -= wish.cost
        wish.status = "redeemed"
        wish.redeemedAt = Date()
        wish.progress = 1.0

        saveContext()
        return true
    }

    /// 更新所有心愿进度
    func updateAllWishesProgress(for user: User) {
        let wishes = fetchWishes(for: user, status: "pending")

        for wish in wishes {
            wish.progress = min(1.0, user.totalPoints / wish.cost)
        }

        saveContext()
    }

    /// 删除心愿
    func deleteWish(_ wish: Wish) {
        context.delete(wish)
        saveContext()
    }

    // MARK: - Statistics

    /// 获取统计数据
    func getStatistics(for user: User) -> Statistics {
        let behaviors = fetchBehaviors(for: user)

        print("[DEBUG] getStatistics - behaviors count: \(behaviors.count)")
        for behavior in behaviors {
            print("[DEBUG] behavior grade: \(behavior.grade)")
        }

        // 计算连续天数
        let streak = calculateStreak(from: behaviors)

        // 计算平均心情
        let avgMood = behaviors.isEmpty ? 0.0 : Double(behaviors.map { $0.mood }.reduce(0, +)) / Double(behaviors.count)

        // 计算效率（正面行为占比）
        let positiveBehaviors = behaviors.filter { ["S", "A", "B"].contains($0.grade) }
        let efficiency = behaviors.isEmpty ? 0.0 : Double(positiveBehaviors.count) / Double(behaviors.count) * 100
        print("[DEBUG] positiveBehaviors: \(positiveBehaviors.count), total: \(behaviors.count), efficiency: \(efficiency)")

        return Statistics(
            totalPoints: user.totalPoints,
            currentEnergy: user.currentEnergy,
            streak: streak,
            averageMood: avgMood,
            efficiency: efficiency,
            totalBehaviors: behaviors.count
        )
    }

    // MARK: - Private Helpers

    private func calculateStreak(from behaviors: [Behavior]) -> Int {
        guard !behaviors.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        // 按日期分组的行为
        let grouped = Dictionary(grouping: behaviors) { behavior in
            calendar.startOfDay(for: behavior.timestamp)
        }

        // 从今天往前检查连续天数
        while grouped[currentDate] != nil {
            streak += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDate
        }

        return streak
    }

    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("保存失败: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Statistics Model

/// 统计数据模型
struct Statistics {
    let totalPoints: Double
    let currentEnergy: Double
    let streak: Int
    let averageMood: Double
    let efficiency: Double
    let totalBehaviors: Int
}

// MARK: - NSManagedObject Extensions

extension User {
    static func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }
}

extension Behavior {
    static func fetchRequest() -> NSFetchRequest<Behavior> {
        return NSFetchRequest<Behavior>(entityName: "Behavior")
    }
}

extension Wish {
    static func fetchRequest() -> NSFetchRequest<Wish> {
        return NSFetchRequest<Wish>(entityName: "Wish")
    }
}

extension CustomBehavior {
    static func fetchRequest() -> NSFetchRequest<CustomBehavior> {
        return NSFetchRequest<CustomBehavior>(entityName: "CustomBehavior")
    }
}
