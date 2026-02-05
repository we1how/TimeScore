//
//  BehaviorPickerView.swift
//  TimeScore
//
//  搜索行为界面
//  对应 UI 原型: 搜索行为界面.html
//

import SwiftUI

struct BehaviorPickerView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    let selectedGrade: String
    let onSelect: (String) -> Void

    @State private var searchText: String = ""

    // 预设行为数据
    private let behaviorsByGrade: [String: [(name: String, desc: String, icon: String)]] = [
        "S": [
            ("深度学习", "High focus, high output", "brain.head.profile"),
            ("创意突破", "Deep creative flow", "lightbulb.fill"),
            ("攻克难题", "Breakthrough challenges", "checkmark.seal.fill"),
            ("高强度训练", "Peak performance", "figure.run"),
            ("关键对话", "Important communication", "bubble.left.fill")
        ],
        "A": [
            ("项目工作", "Productive development", "briefcase.fill"),
            ("写作", "Content creation", "pencil"),
            ("编程", "Code development", "terminal.fill"),
            ("学习新技能", "Skill acquisition", "graduationcap.fill"),
            ("健身", "Physical exercise", "dumbbell.fill")
        ],
        "B": [
            ("邮件处理", "Communication batching", "envelope.fill"),
            ("会议", "Team collaboration", "person.3.fill"),
            ("家务", "Maintenance tasks", "house.fill"),
            ("日常事务", "Routine work", "list.bullet")
        ],
        "C": [
            ("无目的刷手机", "Mindless browsing", "iphone"),
            ("闲聊", "Casual chatting", "bubble.right.fill"),
            ("拖延", "Procrastination", "clock.arrow.circlepath")
        ],
        "D": [
            ("熬夜", "Sleep deprivation", "moon.fill"),
            ("负面情绪沉溺", "Negative emotions", "cloud.rain.fill"),
            ("过度游戏", "Excessive gaming", "gamecontroller.fill")
        ],
        "R1": [
            ("喝水", "Hydration", "drop.fill"),
            ("伸展", "Stretching", "figure.stand"),
            ("深呼吸", "Breathing", "wind")
        ],
        "R2": [
            ("小憩", "Power nap", "bed.double.fill"),
            ("冥想", "Meditation", "sparkles"),
            ("散步", "Walking", "figure.walk")
        ],
        "R3": [
            ("午睡", "Deep rest", "moon.zzz.fill"),
            ("泡澡", "Relaxation", "bathtub.fill"),
            ("户外运动", "Outdoor activity", "figure.hiking")
        ]
    ]

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // 深色背景
                Color(hex: "#102211")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 搜索栏
                    searchBar

                    // 行为列表
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // 高优先级行为（与选中等级匹配）
                            if let behaviors = behaviorsByGrade[selectedGrade] {
                                behaviorSection(
                                    title: "Grade \(selectedGrade) Behaviors",
                                    behaviors: filteredBehaviors(behaviors),
                                    isPrimary: true
                                )
                            }

                            // 其他等级行为
                            ForEach(["S", "A", "B", "R2", "R3"].filter { $0 != selectedGrade }, id: \.self) { grade in
                                if let behaviors = behaviorsByGrade[grade] {
                                    let filtered = filteredBehaviors(behaviors)
                                    if !filtered.isEmpty {
                                        behaviorSection(
                                            title: "Grade \(grade) Behaviors",
                                            behaviors: filtered,
                                            isPrimary: false
                                        )
                                    }
                                }
                            }

                            // 创建新行为提示
                            createNewHint
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Select Behavior")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryGreen)
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundColor(.gray)

            TextField("Search behaviors...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.white)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Behavior Section

    private func behaviorSection(
        title: String,
        behaviors: [(name: String, desc: String, icon: String)],
        isPrimary: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .padding(.horizontal)

            VStack(spacing: 4) {
                ForEach(behaviors, id: \.name) { behavior in
                    behaviorRow(behavior, isPrimary: isPrimary)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Behavior Row

    private func behaviorRow(
        _ behavior: (name: String, desc: String, icon: String),
        isPrimary: Bool
    ) -> some View {
        Button(action: {
            onSelect(behavior.name)
            dismiss()
        }) {
            HStack(spacing: 16) {
                // 图标
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isPrimary ? Color.primaryGreen.opacity(0.1) : Color.white.opacity(0.05))
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isPrimary ? Color.primaryGreen.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                        )

                    Image(systemName: behavior.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isPrimary ? .primaryGreen : .gray)
                }

                // 文字
                VStack(alignment: .leading, spacing: 2) {
                    Text(behavior.name)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)

                    Text(behavior.desc)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Create New Hint

    private var createNewHint: some View {
        VStack(spacing: 12) {
            Text("Don't see what you're looking for?")
                .font(.system(size: 14))
                .foregroundColor(.gray)

            Button(action: {
                // 创建新行为逻辑
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Create New Behavior")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.primaryGreen)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    // MARK: - Helpers

    private func filteredBehaviors(
        _ behaviors: [(name: String, desc: String, icon: String)]
    ) -> [(name: String, desc: String, icon: String)] {
        if searchText.isEmpty {
            return behaviors
        }
        return behaviors.filter { behavior in
            behavior.name.localizedCaseInsensitiveContains(searchText) ||
            behavior.desc.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Preview

struct BehaviorPickerView_Previews: PreviewProvider {
    static var previews: some View {
        BehaviorPickerView(selectedGrade: "A") { _ in }
    }
}
