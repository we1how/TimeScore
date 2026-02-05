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
    @State private var showCreateBehavior = false
    @State private var showEditBehavior = false
    @State private var selectedBehavior: (name: String, desc: String, grade: String, isCustom: Bool)? = nil
    @State private var customBehaviors: [CustomBehavior] = []
    @State private var user: User?

    private let dataManager = CoreDataManager.shared

    // 预设行为数据（硬编码）
    private let presetBehaviors: [String: [(name: String, desc: String)]] = [
        "S": [("深度学习", "深度专注学习"), ("创意突破", "创造性工作"), ("攻克难题", "解决复杂问题"), ("高强度训练", "体能训练"), ("关键对话", "重要沟通")],
        "A": [("项目工作", "项目开发"), ("写作", "内容创作"), ("编程", "代码开发"), ("阅读", "知识阅读"), ("学习新技能", "技能学习"), ("健身", "体育锻炼")],
        "B": [("邮件处理", "邮件沟通"), ("会议", "团队会议"), ("家务", "日常家务"), ("通勤", "交通通勤"), ("日常事务", "日常任务")],
        "C": [("无目的刷手机", "无意识浏览"), ("闲聊", "无目的聊天"), ("拖延", "任务拖延"), ("低效等待", "无效等待")],
        "D": [("熬夜", "熬夜不睡"), ("暴饮暴食", "过量饮食"), ("负面情绪沉溺", "情绪内耗"), ("过度游戏", "游戏沉迷")],
        "R1": [("喝水", "补充水分"), ("伸展", "身体伸展"), ("深呼吸", "呼吸放松"), ("听音乐", "音乐放松")],
        "R2": [("小憩", "短暂休息"), ("冥想", "冥想练习"), ("散步", "轻松散步"), ("轻度运动", "轻度活动")],
        "R3": [("午睡", "午休睡眠"), ("泡澡", "热水泡澡"), ("瑜伽", "瑜伽练习"), ("户外运动", "户外活动"), ("社交聚会", "社交活动")]
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
                            behaviorSection(
                                title: "Grade \(selectedGrade) Behaviors",
                                behaviors: getBehaviors(for: selectedGrade),
                                grade: selectedGrade,
                                isPrimary: true
                            )

                            // 其他等级行为
                            ForEach(["S", "A", "B", "C", "D", "R1", "R2", "R3"].filter { $0 != selectedGrade }, id: \.self) { grade in
                                let behaviors = getBehaviors(for: grade)
                                if !behaviors.isEmpty {
                                    behaviorSection(
                                        title: "Grade \(grade) Behaviors",
                                        behaviors: behaviors,
                                        grade: grade,
                                        isPrimary: false
                                    )
                                }
                            }

                            // 底部空间，为悬浮按钮留出位置
                            Spacer().frame(height: 80)
                        }
                        .padding(.top, 16)
                    }
                }

                // 悬浮添加按钮
                floatingAddButton
                    .padding(.bottom, 20)
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
            .sheet(isPresented: $showCreateBehavior) {
                CreateBehaviorView { name, desc, grade in
                    addCustomBehavior(name: name, description: desc, grade: grade)
                }
            }
            .sheet(isPresented: $showEditBehavior) {
                if let behavior = selectedBehavior {
                    EditBehaviorView(
                        behavior: behavior,
                        onSave: { newName, newDesc in
                            updateCustomBehavior(name: behavior.name, newName: newName, newDesc: newDesc)
                        },
                        onDelete: {
                            deleteCustomBehavior(name: behavior.name, grade: behavior.grade)
                        }
                    )
                }
            }
            .onAppear {
                loadUserAndBehaviors()
            }
        }
    }

    // MARK: - Data Loading

    private func loadUserAndBehaviors() {
        user = dataManager.fetchOrCreateUser()
        if let user = user {
            customBehaviors = dataManager.fetchCustomBehaviors(for: user)
        }
    }

    private func getBehaviors(for grade: String) -> [(name: String, desc: String, isCustom: Bool)] {
        // 获取预设行为
        let presets = presetBehaviors[grade] ?? []
        var result: [(name: String, desc: String, isCustom: Bool)] = presets.map {
            (name: $0.name, desc: $0.desc, isCustom: false)
        }

        // 获取自定义行为（按等级过滤）
        let customs = customBehaviors.filter { $0.grade == grade }
        result += customs.map {
            (name: $0.name, desc: $0.behaviorDescription ?? "", isCustom: true)
        }

        // 搜索过滤
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.desc.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    private func addCustomBehavior(name: String, description: String?, grade: String) {
        guard let user = user else { return }
        let _ = dataManager.addCustomBehavior(to: user, name: name, description: description, grade: grade)
        customBehaviors = dataManager.fetchCustomBehaviors(for: user)
    }

    private func updateCustomBehavior(name: String, newName: String, newDesc: String?) {
        guard let user = user,
              let behavior = customBehaviors.first(where: { $0.name == name }) else { return }
        dataManager.updateCustomBehavior(behavior, name: newName, description: newDesc)
        customBehaviors = dataManager.fetchCustomBehaviors(for: user)
    }

    private func deleteCustomBehavior(name: String, grade: String) {
        guard let user = user,
              let behavior = customBehaviors.first(where: { $0.name == name && $0.grade == grade }) else { return }
        dataManager.deleteCustomBehavior(behavior)
        customBehaviors = dataManager.fetchCustomBehaviors(for: user)
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
        behaviors: [(name: String, desc: String, isCustom: Bool)],
        grade: String,
        isPrimary: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .tracking(1)
                .foregroundColor(.primaryGreen)
                .textCase(.uppercase)
                .padding(.horizontal)

            VStack(spacing: 4) {
                ForEach(behaviors, id: \.name) { behavior in
                    behaviorRow(behavior, grade: grade, isPrimary: isPrimary)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Behavior Row

    private func behaviorRow(
        _ behavior: (name: String, desc: String, isCustom: Bool),
        grade: String,
        isPrimary: Bool
    ) -> some View {
        HStack(spacing: 16) {
            // 点击选择行为
            Button(action: {
                onSelect(behavior.name)
                dismiss()
            }) {
                // 文字
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(behavior.name)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)

                        if behavior.isCustom {
                            Text("Custom")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.primaryGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.primaryGreen.opacity(0.2))
                                )
                        }
                    }

                    Text(behavior.desc)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // Edit 按钮（只有自定义行为可编辑）
            if behavior.isCustom {
                Button(action: {
                    selectedBehavior = (name: behavior.name, desc: behavior.desc, grade: grade, isCustom: true)
                    showEditBehavior = true
                }) {
                    Text("Edit")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0))
        )
        .contentShape(Rectangle())
    }

    // MARK: - Floating Add Button

    private var floatingAddButton: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Button(action: {
                    showCreateBehavior = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("New Behavior")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.primaryGreen)
                    )
                    .shadow(color: Color.primaryGreen.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.trailing, 20)
            }
        }
    }
}

// MARK: - Create Behavior View

struct CreateBehaviorView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, String?, String) -> Void

    @State private var behaviorName: String = ""
    @State private var behaviorDesc: String = ""
    @State private var selectedGrade: String = "A"

    private let grades = ["S", "A", "B", "C", "D", "R1", "R2", "R3"]

    private func gradeDescription(for grade: String) -> String {
        if grade.hasPrefix("S") { return "深度工作 · 高价值产出" }
        if grade.hasPrefix("A") { return "高效产出 · 专注执行" }
        if grade.hasPrefix("B") { return "日常事务 · 维持运转" }
        if grade.hasPrefix("C") { return "低效行为 · 时间浪费" }
        if grade.hasPrefix("D") { return "消极行为 · 损害成长" }
        if grade.hasPrefix("R") { return "恢复精力 · 充电休息" }
        return ""
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#102211")
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // 行为名称
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Behavior Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        TextField("Enter behavior name", text: $behaviorName)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }

                    // 行为描述
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        TextField("Enter description", text: $behaviorDesc)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }

                    // 等级选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Grade")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        FlowLayout(spacing: 12) {
                            ForEach(grades, id: \.self) { grade in
                                Button(action: {
                                    selectedGrade = grade
                                }) {
                                    Text(grade)
                                        .font(.system(size: 16, weight: selectedGrade == grade ? .bold : .medium))
                                        .foregroundColor(selectedGrade == grade ? .black : .white)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(selectedGrade == grade ? Color.primaryGreen : Color.white.opacity(0.1))
                                        )
                                }
                            }
                        }

                        // 等级描述
                        Text(gradeDescription(for: selectedGrade))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                            .animation(.easeInOut(duration: 0.2), value: selectedGrade)
                    }

                    Spacer()

                    // 保存按钮
                    Button(action: {
                        let desc = behaviorDesc.isEmpty ? nil : behaviorDesc
                        onSave(behaviorName, desc, selectedGrade)
                        dismiss()
                    }) {
                        Text("Save Behavior")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.primaryGreen)
                            .cornerRadius(16)
                    }
                    .disabled(behaviorName.isEmpty)
                    .opacity(behaviorName.isEmpty ? 0.5 : 1.0)
                }
                .padding()
            }
            .navigationTitle("New Behavior")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
    }
}

// MARK: - Edit Behavior View

struct EditBehaviorView: View {
    @Environment(\.dismiss) private var dismiss

    let behavior: (name: String, desc: String, grade: String, isCustom: Bool)
    let onSave: (String, String?) -> Void
    let onDelete: () -> Void

    @State private var behaviorName: String
    @State private var behaviorDesc: String
    @State private var showDeleteConfirm = false

    init(behavior: (name: String, desc: String, grade: String, isCustom: Bool),
         onSave: @escaping (String, String?) -> Void,
         onDelete: @escaping () -> Void) {
        self.behavior = behavior
        self.onSave = onSave
        self.onDelete = onDelete
        _behaviorName = State(initialValue: behavior.name)
        _behaviorDesc = State(initialValue: behavior.desc)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#102211")
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // 行为名称
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Behavior Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        TextField("Enter behavior name", text: $behaviorName)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }

                    // 行为描述
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        TextField("Enter description", text: $behaviorDesc)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }

                    // 等级显示（不可编辑）
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grade")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        HStack {
                            Text(behavior.grade)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                )

                            Spacer()
                        }
                    }

                    Spacer()

                    // 删除按钮
                    Button(action: {
                        showDeleteConfirm = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                            Text("Delete Behavior")
                        }
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.red.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }

                    // 保存按钮
                    Button(action: {
                        let desc = behaviorDesc.isEmpty ? nil : behaviorDesc
                        onSave(behaviorName, desc)
                        dismiss()
                    }) {
                        Text("Save Changes")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.primaryGreen)
                            .cornerRadius(16)
                    }
                    .disabled(behaviorName.isEmpty)
                    .opacity(behaviorName.isEmpty ? 0.5 : 1.0)
                }
                .padding()
            }
            .navigationTitle("Edit Behavior")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
            .alert("Delete Behavior?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
}

// MARK: - Flow Layout (Helper)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview

struct BehaviorPickerView_Previews: PreviewProvider {
    static var previews: some View {
        BehaviorPickerView(selectedGrade: "A") { _ in }
    }
}
