//
//  ExchangeViewModel.swift
//  TimeScore
//
//  积分兑换系统
//  对应 Python: src/redeem/exchange.py
//

import Foundation
import Combine

/// 积分兑换 ViewModel
/// 管理心愿的添加、进度追踪和兑换
class ExchangeViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 心愿列表
    @Published var wishes: [Wish] = []

    /// 新愿望名称
    @Published var newWishName: String = ""

    /// 新愿望成本
    @Published var newWishCost: String = ""

    /// 错误信息
    @Published var errorMessage: String?

    /// 显示错误
    @Published var showError: Bool = false

    /// 兑换成功动画
    @Published var showRedeemAnimation: Bool = false

    /// 最近兑换的愿望
    @Published var lastRedeemedWish: Wish?

    // MARK: - Dependencies

    private let dataManager: CoreDataManager
    private var user: User?

    // MARK: - Constants

    /// 最低积分成本
    static let minimumCost: Double = 100.0

    /// 每日最大兑换次数
    static let maxDailyRedemptions: Int = 3

    // MARK: - Initialization

    init(dataManager: CoreDataManager = CoreDataManager.shared) {
        self.dataManager = dataManager
    }

    // MARK: - User Setup

    /// 设置当前用户并加载心愿列表
    func setup(for user: User) {
        self.user = user
        loadWishes()
    }

    // MARK: - Wish Operations

    /// 添加新愿望
    /// 对应 Python: add_wish()
    func addWish() {
        guard let user = user else {
            showError(NSLocalizedString("wishlist.error.user_not_initialized", comment: "User not initialized"))
            return
        }

        // 验证名称
        guard !newWishName.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError(NSLocalizedString("wishlist.error.empty_name", comment: "Empty name"))
            return
        }

        // 验证成本
        guard let cost = Double(newWishCost), cost >= ExchangeViewModel.minimumCost else {
            showError(String(format: NSLocalizedString("wishlist.error.min_cost", comment: "Min cost"), Int(ExchangeViewModel.minimumCost)))
            return
        }

        // 创建愿望
        let wish = dataManager.addWish(to: user, name: newWishName.trimmingCharacters(in: .whitespaces), cost: cost)

        // 更新列表
        wishes.insert(wish, at: 0)

        // 重置表单
        newWishName = ""
        newWishCost = ""
    }

    /// 兑换愿望
    /// 对应 Python: redeem_wish()
    func redeemWish(_ wish: Wish) {
        guard let user = user else {
            showError(NSLocalizedString("wishlist.error.user_not_initialized", comment: "User not initialized"))
            return
        }

        // 检查是否已满足
        guard wish.isRedeemable else {
            showError(NSLocalizedString("wishlist.error.insufficient_points", comment: "Insufficient points"))
            return
        }

        // 检查每日限制
        if hasReachedDailyLimit() {
            showError(NSLocalizedString("wishlist.error.daily_limit", comment: "Daily limit"))
            return
        }

        // 执行兑换
        if dataManager.redeemWish(wish, for: user) {
            lastRedeemedWish = wish
            showRedeemAnimation = true
            loadWishes() // 刷新列表
        } else {
            showError(NSLocalizedString("wishlist.error.redeem_failed", comment: "Redeem failed"))
        }
    }

    /// 删除愿望
    func deleteWish(_ wish: Wish) {
        dataManager.deleteWish(wish)
        loadWishes()
    }

    /// 刷新心愿列表
    func loadWishes() {
        guard let user = user else { return }
        wishes = dataManager.fetchWishes(for: user)
    }

    // MARK: - Progress

    /// 更新所有心愿进度
    func updateProgress() {
        guard let user = user else { return }
        dataManager.updateAllWishesProgress(for: user)
        loadWishes()
    }

    /// 获取特定愿望的进度
    func progress(for wish: Wish) -> Double {
        guard let user = user else { return 0.0 }
        return min(1.0, user.totalPoints / wish.cost)
    }

    /// 获取特定愿望的进度百分比文本
    func progressText(for wish: Wish) -> String {
        let percentage = Int(progress(for: wish) * 100)
        return "\(percentage)%"
    }

    // MARK: - Validation

    /// 新愿望表单是否有效
    var isNewWishValid: Bool {
        !newWishName.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(newWishCost) ?? 0) >= ExchangeViewModel.minimumCost
    }

    // MARK: - Computed Properties

    /// 当前积分余额
    var currentPoints: Double {
        user?.totalPoints ?? 0.0
    }

    /// 进行中的愿望
    var activeWishes: [Wish] {
        wishes.filter { $0.status == "pending" }
    }

    /// 已完成的愿望
    var completedWishes: [Wish] {
        wishes.filter { $0.status == "redeemed" }
    }

    /// 可兑换的愿望
    var redeemableWishes: [Wish] {
        activeWishes.filter { $0.isRedeemable }
    }

    /// 今日已兑换数量
    var todayRedeemedCount: Int {
        guard let user = user else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return completedWishes.filter { wish in
            guard let redeemedAt = wish.redeemedAt else { return false }
            return calendar.isDate(redeemedAt, inSameDayAs: today)
        }.count
    }

    // MARK: - Private Methods

    private func hasReachedDailyLimit() -> Bool {
        todayRedeemedCount >= ExchangeViewModel.maxDailyRedemptions
    }

    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Wish Extensions

extension Wish {
    /// 进度百分比
    var progressPercentage: Int {
        return Int(progress * 100)
    }

    /// 状态显示文本
    var statusDisplay: String {
        switch status {
        case "pending":
            return isRedeemable ? NSLocalizedString("wish.status.redeemable", comment: "Redeemable") : NSLocalizedString("wish.status.pending", comment: "Pending")
        case "redeemed":
            return NSLocalizedString("wish.status.completed", comment: "Completed")
        default:
            return status
        }
    }

    /// 状态颜色
    var statusColor: String {
        switch status {
        case "pending":
            return isRedeemable ? "#00E600" : "#FF9800"
        case "redeemed":
            return "#9E9E9E"
        default:
            return "#999999"
        }
    }
}
