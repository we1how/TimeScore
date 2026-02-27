//
//  DetailRecordView.swift
//  TimeScore
//
//  详细记录行为界面
//  对应 UI 原型: 详细记录行为界面.html
//

import SwiftUI

struct DetailRecordView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @StateObject private var behaviorVM = BehaviorViewModel()

    @State private var user: User?
    @State private var showBehaviorPicker = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Bug Fix 3: 使用系统背景色支持暗黑模式
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 统计卡片区域
                        statsSection

                        // 标题
                        HStack {
                            Text(NSLocalizedString("detail.record_behavior", comment: "Record Behavior"))
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                        }
                        .padding(.horizontal)

                        // 表单卡片
                        formCard

                        // 底部空间
                        Spacer().frame(height: 100)
                    }
                    .padding(.top)
                }

                // 底部固定按钮
                bottomButton
            }
            // Bug Fix: 点击空白处收起键盘
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle("TimeScore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showBehaviorPicker) {
            BehaviorPickerView(
                selectedGrade: behaviorVM.grade,
                onSelect: { name in
                    behaviorVM.selectBehavior(name)
                }
            )
        }
        .overlay {
            if behaviorVM.showSuccessOverlay,
               let result = behaviorVM.lastRecordResult {
                SuccessOverlayView(result: result) {
                    behaviorVM.showSuccessOverlay = false
                    dismiss()
                }
            }
        }
        .onAppear {
            loadUser()
        }
        // Bug Fix: 为数字键盘添加 Done 按钮
        .withNumberPadDoneButton()
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 16) {
            // 积分卡片
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("detail.total_points", comment: "Total Points"))
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.secondaryText)
                    .textCase(.uppercase)

                Text("\(Int(user?.totalPoints ?? 0))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )

            // 能量环形图
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: (user?.currentEnergy ?? 100) / 120)
                    .stroke(Color.primaryGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(user?.currentEnergy ?? 100))%")
                        .font(.system(size: 14, weight: .bold))
                    Text(NSLocalizedString("detail.energy", comment: "Energy"))
                        .font(.system(size: 8))
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(spacing: 24) {
            // 效率等级选择
            formSection(title: NSLocalizedString("detail.grade_label", comment: "Efficiency Grade")) {
                gradeSelector
            }

            // 具体行为
            formSection(title: NSLocalizedString("detail.behavior_label", comment: "Specific Behavior")) {
                Button(action: { showBehaviorPicker = true }) {
                    HStack {
                        Text(behaviorVM.behaviorName.isEmpty ? NSLocalizedString("detail.behavior_placeholder", comment: "Select behavior") : behaviorVM.behaviorName)
                            .foregroundColor(behaviorVM.behaviorName.isEmpty ? .gray.opacity(0.5) : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondaryText)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.borderColor, lineWidth: 1)
                    )
                }
            }

            // 时间和时长
            formSection(title: NSLocalizedString("detail.time_duration", comment: "Time & Duration")) {
                HStack(spacing: 12) {
                    // 时长步进器
                    HStack(spacing: 0) {
                        Button(action: { behaviorVM.updateDuration(delta: -5) }) {
                            Image(systemName: "minus")
                                .frame(width: 36, height: 36)
                                .background(Color.bgLight)
                                .clipShape(Circle())
                        }

                        Button(action: { behaviorVM.updateDuration(delta: 5) }) {
                            Image(systemName: "plus")
                                .frame(width: 36, height: 36)
                                .background(Color.bgLight)
                                .clipShape(Circle())
                        }

                        Spacer()

                        // Bug Fix 5: 直接输入分钟数
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            TextField("30", value: $behaviorVM.duration, format: .number)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 50)
                                .onChange(of: behaviorVM.duration) { newValue in
                                    // 限制范围在 5-480 分钟
                                    if newValue < 5 {
                                        behaviorVM.duration = 5
                                    } else if newValue > 480 {
                                        behaviorVM.duration = 480
                                    }
                                }
                            Text("min")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondaryText)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.borderColor, lineWidth: 1)
                    )

                    // 时间选择器 - 使用WheelPicker样式
                    DatePicker(
                        "",
                        selection: $behaviorVM.recordTime,
                        in: ...Date().addingTimeInterval(5 * 60), // 最大为当前时间后5分钟
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .frame(height: 44)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.borderColor, lineWidth: 1)
                    )
                }
            }

            // 心情评分
            formSection(title: NSLocalizedString("detail.mood", comment: "Mood")) {
                HStack(spacing: 20) {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: { behaviorVM.mood = star }) {
                            Image(systemName: star <= behaviorVM.mood ? "star.fill" : "star")
                                .font(.system(size: 22))
                                .foregroundColor(star <= behaviorVM.mood ? .primaryGreen : .gray.opacity(0.3))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
            }

            // 备注
            formSection(title: NSLocalizedString("detail.notes", comment: "Notes")) {
                ZStack(alignment: .topLeading) {
                    if behaviorVM.notes.isEmpty {
                        Text(NSLocalizedString("detail.notes_placeholder", comment: "What did you accomplish?"))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    TextEditor(text: $behaviorVM.notes)
                        .font(.system(size: 16))
                        .frame(minHeight: 80)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    // MARK: - Grade Selector

    private var gradeSelector: some View {
        HStack(spacing: 4) {
            ForEach(["S", "A", "B", "C", "D", "R"], id: \.self) { grade in
                let isSelected = behaviorVM.grade.hasPrefix(grade)

                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        if grade == "R" {
                            behaviorVM.grade = "R2"
                        } else {
                            behaviorVM.grade = grade
                        }
                        // Bug Fix: 验证并清除不匹配当前等级的行为
                        behaviorVM.validateBehaviorForCurrentGrade()
                    }
                }) {
                    Text(grade)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isSelected ? .primary : .secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(isSelected ? Color.primaryGreen : Color.clear)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(4)
        .background(Color(.systemBackground))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }

    // MARK: - Form Section Helper

    private func formSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundColor(.secondaryText)
                .textCase(.uppercase)

            content()
        }
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        VStack {
            Spacer()

            LinearGradient(
                colors: [Color.primaryGreen, Color(hex: "#16cc1c")],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 56)
            .cornerRadius(28)
            .overlay(
                Button(action: {
                    if let user = user {
                        behaviorVM.recordBehavior(for: user)
                    }
                }) {
                    Text(NSLocalizedString("detail.record_button", comment: "Record Behavior"))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            )
            .shadow(color: Color.primaryGreen.opacity(0.3), radius: 12, x: 0, y: 6)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Helpers

    private func loadUser() {
        user = CoreDataManager.shared.fetchOrCreateUser()
    }
}

// MARK: - Preview

struct DetailRecordView_Previews: PreviewProvider {
    static var previews: some View {
        DetailRecordView()
    }
}
