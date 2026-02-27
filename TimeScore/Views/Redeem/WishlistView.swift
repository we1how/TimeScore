//
//  WishlistView.swift
//  TimeScore
//
//  心愿增加以及兑换界面
//  对应 UI 原型: 心愿增加以及兑换界面.html
//

import SwiftUI

struct WishlistView: View {

    // MARK: - Properties

    @StateObject private var exchangeVM = ExchangeViewModel()
    @State private var user: User?

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 顶部导航
                topBar

                // 余额展示
                balanceSection

                // 添加新愿望
                addWishSection

                // 活跃愿望列表
                activeWishesSection

                // 兑换历史
                redeemedHistorySection

                // 底部空间
                Spacer().frame(height: 40)
            }
            .padding(.horizontal)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .alert(NSLocalizedString("common.error", comment: "Error"), isPresented: $exchangeVM.showError) {
            Button(NSLocalizedString("common.ok", comment: "OK")) {}
        } message: {
            Text(exchangeVM.errorMessage ?? NSLocalizedString("common.unknown_error", comment: "Unknown error"))
        }
        .fullScreenCover(isPresented: $exchangeVM.showRedeemAnimation) {
            if let wish = exchangeVM.lastRedeemedWish {
                RedeemAnimationView(wish: wish) {
                    exchangeVM.showRedeemAnimation = false
                }
            }
        }
        .onAppear {
            loadUser()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()

            Text(NSLocalizedString("wishlist.title", comment: "Wishlist title"))
                .font(.system(size: 17, weight: .bold))

            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Balance Section

    private var balanceSection: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("wishlist.balance.title", comment: "Current balance"))
                .font(.system(size: 12, weight: .semibold))
                .tracking(2)
                .foregroundColor(.secondaryText)
                .textCase(.uppercase)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(exchangeVM.currentPoints.pointsDisplay)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.primary)

                Text(NSLocalizedString("wishlist.points", comment: "Points"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primaryGreen)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Add Wish Section

    private var addWishSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("wishlist.add_title", comment: "Add new wish"))
                .font(.system(size: 18, weight: .bold))

            VStack(spacing: 16) {
                // 愿望名称
                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString("wishlist.name_label", comment: "Wish name label"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)

                    TextField(NSLocalizedString("wishlist.name_placeholder", comment: "Wish name placeholder"), text: $exchangeVM.newWishName)
                        .font(.system(size: 16))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(height: 44)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                }

                // 积分成本和添加按钮
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString("wishlist.cost_label", comment: "Point cost label"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)

                        TextField("1000", text: $exchangeVM.newWishCost)
                            .keyboardType(.numberPad)
                            .font(.system(size: 16))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(height: 44)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.borderColor, lineWidth: 1)
                            )
                    }

                    VStack {
                        Spacer()

                        Button(action: { exchangeVM.addWish() }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 56, height: 56)
                                .background(Color.primaryGreen)
                                .cornerRadius(12)
                        }
                        .disabled(!exchangeVM.isNewWishValid)
                        .opacity(exchangeVM.isNewWishValid ? 1.0 : 0.5)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }

    // MARK: - Active Wishes Section

    private var activeWishesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(NSLocalizedString("wishlist.active_title", comment: "Active wishes"))
                    .font(.system(size: 20, weight: .black))

                Spacer()

                Text("\(exchangeVM.activeWishes.count) \(NSLocalizedString("wishlist.progressing", comment: "Progressing"))")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primaryGreen.opacity(0.1))
                    .cornerRadius(8)
            }

            ForEach(exchangeVM.activeWishes.prefix(3), id: \.id) { wish in
                wishCard(wish)
            }
        }
    }

    private func wishCard(_ wish: Wish) -> some View {
        let isRedeemable = wish.isRedeemable
        let progress = wish.progress

        return VStack(alignment: .leading, spacing: 12) {
            // 标题和状态
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(wish.name)
                        .font(.system(size: 18, weight: .bold))

                    Text("\((user?.totalPoints ?? 0).pointsDisplay) / \(wish.cost.pointsDisplay) \(NSLocalizedString("wishlist.points", comment: "Points"))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondaryText)
                }

                Spacer()

                if isRedeemable {
                    Text(NSLocalizedString("wishlist.goal_met", comment: "Goal met"))
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.5)
                        .foregroundColor(.primaryGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primaryGreen.opacity(0.2))
                        .cornerRadius(4)
                } else {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondaryText)
                }
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.borderColor)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primaryGreen)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 6)
                        .shadow(color: Color.primaryGreen.opacity(0.4), radius: 4, x: 0, y: 0)
                }
            }
            .frame(height: 6)

            // 操作按钮
            Button(action: {
                if isRedeemable {
                    exchangeVM.redeemWish(wish)
                }
            }) {
                HStack(spacing: 6) {
                    if isRedeemable {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 16))
                    }

                    Text(isRedeemable ? NSLocalizedString("wishlist.redeem", comment: "Redeem now") : NSLocalizedString("wishlist.insufficient", comment: "Insufficient points"))
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(isRedeemable ? .black : .secondaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isRedeemable ? Color.primaryGreen : Color.borderColor)
                .cornerRadius(26)
            }
            .disabled(!isRedeemable)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }

    // MARK: - Redeemed History Section

    private var redeemedHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("wishlist.history_title", comment: "Redeemed history"))
                .font(.system(size: 12, weight: .bold))
                .tracking(2)
                .foregroundColor(.gray)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                ForEach(exchangeVM.completedWishes.prefix(2), id: \.id) { wish in
                    redeemedRow(wish)

                    if wish != exchangeVM.completedWishes.prefix(2).last {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .opacity(0.6)
        }
    }

    private func redeemedRow(_ wish: Wish) -> some View {
        HStack(spacing: 12) {
            // 完成图标
            ZStack {
                Circle()
                    .fill(Color.borderColor)
                    .frame(width: 36, height: 36)

                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondaryText)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(wish.name)
                    .font(.system(size: 16, weight: .medium))
                    .strikethrough()

                if let redeemedAt = wish.redeemedAt {
                    Text("\(NSLocalizedString("wishlist.redeemed_at", comment: "Redeemed at")) \(redeemedAt.formattedDate())")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .italic()
                }
            }

            Spacer()

            Text("\(wish.cost.pointsDisplay) \(NSLocalizedString("wishlist.points", comment: "Points"))")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func loadUser() {
        user = CoreDataManager.shared.fetchOrCreateUser()
        if let user = user {
            exchangeVM.setup(for: user)
        }
    }
}

// MARK: - Redeem Animation View

struct RedeemAnimationView: View {
    let wish: Wish
    let onComplete: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // 纯黑背景，确保完全覆盖
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // 庆祝动画
                ZStack {
                    // 光环
                    Circle()
                        .stroke(Color.primaryGreen.opacity(0.3), lineWidth: 2)
                        .frame(width: 200, height: 200)
                        .scaleEffect(scale)

                    // 礼物图标
                    Image(systemName: "gift.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.primaryGreen)
                        .rotationEffect(.degrees(rotation))
                }

                // 文字
                VStack(spacing: 8) {
                    Text(NSLocalizedString("wishlist.redeem_success", comment: "Redeemed success"))
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(.white)

                    Text(wish.name)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    Text("-\(wish.cost.pointsDisplay) \(NSLocalizedString("wishlist.points", comment: "Points"))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primaryGreen)
                        .padding(.top, 8)
                }

                Spacer()

                // 完成按钮
                Button(action: onComplete) {
                    Text(NSLocalizedString("wishlist.awesome", comment: "Awesome"))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primaryGreen)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
                rotation = 360
            }
        }
    }
}

// MARK: - Preview

struct WishlistView_Previews: PreviewProvider {
    static var previews: some View {
        WishlistView()
    }
}
