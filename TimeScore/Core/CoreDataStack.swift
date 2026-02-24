//
//  CoreDataStack.swift
//  TimeScore
//
//  CoreData 堆栈管理 - 程序化模型定义
//  对应 Python 版本的 SQLite 数据库层
//

import CoreData
import Foundation

/// CoreData 堆栈管理器
/// 负责初始化持久化容器、管理上下文
class CoreDataStack {

    // MARK: - Singleton

    static let shared = CoreDataStack()

    // MARK: - Properties

    /// 持久化容器
    let persistentContainer: NSPersistentContainer

    /// 主上下文（UI 线程使用）
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Initialization

    private init() {
        // 程序化创建模型
        let model = CoreDataStack.createModel()

        // 创建持久化容器
        persistentContainer = NSPersistentContainer(name: "TimeScore", managedObjectModel: model)

        // 加载持久化存储
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("无法加载 CoreData 存储: \(error.localizedDescription)")
            }
            print("CoreData 存储加载成功: \(description.url?.absoluteString ?? "unknown")")
        }

        // 配置上下文
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Model Creation

    /// 程序化创建 CoreData 模型
    /// 对应 Python 的 SQLite 表结构
    private static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // MARK: User Entity
        let userEntity = NSEntityDescription()
        userEntity.name = "User"
        userEntity.managedObjectClassName = "User"

        let userId = NSAttributeDescription()
        userId.name = "id"
        userId.attributeType = .integer64AttributeType
        userId.isOptional = false

        let userTotalPoints = NSAttributeDescription()
        userTotalPoints.name = "totalPoints"
        userTotalPoints.attributeType = .doubleAttributeType
        userTotalPoints.defaultValue = 0.0
        userTotalPoints.isOptional = false

        let userCurrentEnergy = NSAttributeDescription()
        userCurrentEnergy.name = "currentEnergy"
        userCurrentEnergy.attributeType = .doubleAttributeType
        userCurrentEnergy.defaultValue = 120.0
        userCurrentEnergy.isOptional = false

        let userLastResetDate = NSAttributeDescription()
        userLastResetDate.name = "lastResetDate"
        userLastResetDate.attributeType = .dateAttributeType
        userLastResetDate.isOptional = true

        userEntity.properties = [userId, userTotalPoints, userCurrentEnergy, userLastResetDate]

        // MARK: Behavior Entity
        let behaviorEntity = NSEntityDescription()
        behaviorEntity.name = "Behavior"
        behaviorEntity.managedObjectClassName = "Behavior"

        let behaviorId = NSAttributeDescription()
        behaviorId.name = "id"
        behaviorId.attributeType = .UUIDAttributeType
        behaviorId.isOptional = false

        let behaviorGrade = NSAttributeDescription()
        behaviorGrade.name = "grade"
        behaviorGrade.attributeType = .stringAttributeType
        behaviorGrade.isOptional = false

        let behaviorDuration = NSAttributeDescription()
        behaviorDuration.name = "duration"
        behaviorDuration.attributeType = .integer32AttributeType
        behaviorDuration.isOptional = false

        let behaviorMood = NSAttributeDescription()
        behaviorMood.name = "mood"
        behaviorMood.attributeType = .integer16AttributeType
        behaviorMood.isOptional = false

        let behaviorTimestamp = NSAttributeDescription()
        behaviorTimestamp.name = "timestamp"
        behaviorTimestamp.attributeType = .dateAttributeType
        behaviorTimestamp.isOptional = false

        let behaviorNotes = NSAttributeDescription()
        behaviorNotes.name = "notes"
        behaviorNotes.attributeType = .stringAttributeType
        behaviorNotes.isOptional = true

        let behaviorScore = NSAttributeDescription()
        behaviorScore.name = "score"
        behaviorScore.attributeType = .doubleAttributeType
        behaviorScore.isOptional = false

        let behaviorEnergyChange = NSAttributeDescription()
        behaviorEnergyChange.name = "energyChange"
        behaviorEnergyChange.attributeType = .doubleAttributeType
        behaviorEnergyChange.isOptional = false

        let behaviorName = NSAttributeDescription()
        behaviorName.name = "name"
        behaviorName.attributeType = .stringAttributeType
        behaviorName.isOptional = true

        behaviorEntity.properties = [behaviorId, behaviorGrade, behaviorDuration, behaviorMood,
                                      behaviorTimestamp, behaviorNotes, behaviorScore,
                                      behaviorEnergyChange, behaviorName]

        // MARK: Wish Entity
        let wishEntity = NSEntityDescription()
        wishEntity.name = "Wish"
        wishEntity.managedObjectClassName = "Wish"

        let wishId = NSAttributeDescription()
        wishId.name = "id"
        wishId.attributeType = .UUIDAttributeType
        wishId.isOptional = false

        let wishName = NSAttributeDescription()
        wishName.name = "name"
        wishName.attributeType = .stringAttributeType
        wishName.isOptional = false

        let wishCost = NSAttributeDescription()
        wishCost.name = "cost"
        wishCost.attributeType = .doubleAttributeType
        wishCost.isOptional = false

        let wishStatus = NSAttributeDescription()
        wishStatus.name = "status"
        wishStatus.attributeType = .stringAttributeType
        wishStatus.defaultValue = "pending"
        wishStatus.isOptional = false

        let wishCreatedAt = NSAttributeDescription()
        wishCreatedAt.name = "createdAt"
        wishCreatedAt.attributeType = .dateAttributeType
        wishCreatedAt.isOptional = false

        let wishRedeemedAt = NSAttributeDescription()
        wishRedeemedAt.name = "redeemedAt"
        wishRedeemedAt.attributeType = .dateAttributeType
        wishRedeemedAt.isOptional = true

        let wishProgress = NSAttributeDescription()
        wishProgress.name = "progress"
        wishProgress.attributeType = .doubleAttributeType
        wishProgress.defaultValue = 0.0
        wishProgress.isOptional = false

        wishEntity.properties = [wishId, wishName, wishCost, wishStatus, wishCreatedAt, wishRedeemedAt, wishProgress]

        // MARK: CustomBehavior Entity (用户自定义行为模板)
        let customBehaviorEntity = NSEntityDescription()
        customBehaviorEntity.name = "CustomBehavior"
        customBehaviorEntity.managedObjectClassName = "CustomBehavior"

        let customBehaviorId = NSAttributeDescription()
        customBehaviorId.name = "id"
        customBehaviorId.attributeType = .UUIDAttributeType
        customBehaviorId.isOptional = false

        let customBehaviorName = NSAttributeDescription()
        customBehaviorName.name = "name"
        customBehaviorName.attributeType = .stringAttributeType
        customBehaviorName.isOptional = false

        let customBehaviorDesc = NSAttributeDescription()
        customBehaviorDesc.name = "behaviorDescription"
        customBehaviorDesc.attributeType = .stringAttributeType
        customBehaviorDesc.isOptional = true

        let customBehaviorGrade = NSAttributeDescription()
        customBehaviorGrade.name = "grade"
        customBehaviorGrade.attributeType = .stringAttributeType
        customBehaviorGrade.isOptional = false

        let customBehaviorCreatedAt = NSAttributeDescription()
        customBehaviorCreatedAt.name = "createdAt"
        customBehaviorCreatedAt.attributeType = .dateAttributeType
        customBehaviorCreatedAt.isOptional = false

        customBehaviorEntity.properties = [customBehaviorId, customBehaviorName, customBehaviorDesc, customBehaviorGrade, customBehaviorCreatedAt]

        // MARK: Relationships

        // User -> Behaviors (To-Many)
        let userToBehaviors = NSRelationshipDescription()
        userToBehaviors.name = "behaviors"
        userToBehaviors.destinationEntity = behaviorEntity
        userToBehaviors.minCount = 0
        userToBehaviors.maxCount = 0 // Unlimited
        userToBehaviors.deleteRule = .cascadeDeleteRule

        // User -> Wishes (To-Many)
        let userToWishes = NSRelationshipDescription()
        userToWishes.name = "wishes"
        userToWishes.destinationEntity = wishEntity
        userToWishes.minCount = 0
        userToWishes.maxCount = 0
        userToWishes.deleteRule = .cascadeDeleteRule

        // User -> CustomBehaviors (To-Many)
        let userToCustomBehaviors = NSRelationshipDescription()
        userToCustomBehaviors.name = "customBehaviors"
        userToCustomBehaviors.destinationEntity = customBehaviorEntity
        userToCustomBehaviors.minCount = 0
        userToCustomBehaviors.maxCount = 0
        userToCustomBehaviors.deleteRule = .cascadeDeleteRule

        // Behavior -> User (To-One)
        let behaviorToUser = NSRelationshipDescription()
        behaviorToUser.name = "user"
        behaviorToUser.destinationEntity = userEntity
        behaviorToUser.minCount = 1
        behaviorToUser.maxCount = 1
        behaviorToUser.deleteRule = .nullifyDeleteRule
        behaviorToUser.inverseRelationship = userToBehaviors

        // Wish -> User (To-One)
        let wishToUser = NSRelationshipDescription()
        wishToUser.name = "user"
        wishToUser.destinationEntity = userEntity
        wishToUser.minCount = 1
        wishToUser.maxCount = 1
        wishToUser.deleteRule = .nullifyDeleteRule
        wishToUser.inverseRelationship = userToWishes

        // CustomBehavior -> User (To-One)
        let customBehaviorToUser = NSRelationshipDescription()
        customBehaviorToUser.name = "user"
        customBehaviorToUser.destinationEntity = userEntity
        customBehaviorToUser.minCount = 1
        customBehaviorToUser.maxCount = 1
        customBehaviorToUser.deleteRule = .nullifyDeleteRule
        customBehaviorToUser.inverseRelationship = userToCustomBehaviors

        // Set inverse relationships
        userToBehaviors.inverseRelationship = behaviorToUser
        userToWishes.inverseRelationship = wishToUser
        userToCustomBehaviors.inverseRelationship = customBehaviorToUser

        // Add relationships to entities
        userEntity.properties += [userToBehaviors, userToWishes, userToCustomBehaviors]
        behaviorEntity.properties += [behaviorToUser]
        wishEntity.properties += [wishToUser]
        customBehaviorEntity.properties += [customBehaviorToUser]

        // Set entities in model
        model.entities = [userEntity, behaviorEntity, wishEntity, customBehaviorEntity]

        return model
    }

    // MARK: - Context Operations

    /// 保存上下文
    /// 对应 Python: db.sqlite3 commit()
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("保存上下文失败: \(error.localizedDescription)")
            }
        }
    }

    /// 在后台执行操作
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { context in
            block(context)
            do {
                try context.save()
            } catch {
                print("后台保存失败: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - NSManagedObject Subclasses

/// 用户实体
/// 对应 Python: User 类 / 用户数据表
@objc(User)
public class User: NSManagedObject {
    @NSManaged public var id: Int64
    @NSManaged public var totalPoints: Double
    @NSManaged public var currentEnergy: Double
    @NSManaged public var lastResetDate: Date?
    @NSManaged public var behaviors: NSSet?
    @NSManaged public var wishes: NSSet?

    /// 便捷访问 behaviors 数组
    public var behaviorsArray: [Behavior] {
        let set = behaviors as? Set<Behavior> ?? []
        return set.sorted { $0.timestamp > $1.timestamp }
    }

    /// 便捷访问 wishes 数组
    public var wishesArray: [Wish] {
        let set = wishes as? Set<Wish> ?? []
        return set.sorted { $0.createdAt > $1.createdAt }
    }

    @NSManaged public var customBehaviors: NSSet?

    /// 便捷访问 customBehaviors 数组
    public var customBehaviorsArray: [CustomBehavior] {
        let set = customBehaviors as? Set<CustomBehavior> ?? []
        return set.sorted { $0.createdAt > $1.createdAt }
    }
}

/// 行为记录实体
/// 对应 Python: Behavior 类 / 行为数据表
@objc(Behavior)
public class Behavior: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var grade: String
    @NSManaged public var duration: Int32
    @NSManaged public var mood: Int16
    @NSManaged public var timestamp: Date
    @NSManaged public var notes: String?
    @NSManaged public var score: Double
    @NSManaged public var energyChange: Double
    @NSManaged public var name: String?
    @NSManaged public var user: User
}

/// 心愿实体
/// 对应 Python: Wish 类 / 兑换系统
@objc(Wish)
public class Wish: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var cost: Double
    @NSManaged public var status: String
    @NSManaged public var createdAt: Date
    @NSManaged public var redeemedAt: Date?
    @NSManaged public var progress: Double
    @NSManaged public var user: User

    /// 是否可兑换
    public var isRedeemable: Bool {
        return status == "pending" && progress >= 1.0
    }
}

/// 自定义行为模板实体
/// 存储用户创建的自定义行为
@objc(CustomBehavior)
public class CustomBehavior: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var behaviorDescription: String?
    @NSManaged public var grade: String
    @NSManaged public var createdAt: Date
    @NSManaged public var user: User
}
