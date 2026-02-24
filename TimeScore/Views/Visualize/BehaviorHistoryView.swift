//
//  BehaviorHistoryView.swift
//  TimeScore
//
//  完整行为历史记录页面
//

import SwiftUI

struct BehaviorHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BehaviorHistoryViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.groupedBehaviors, id: \.date) { group in
                    Section(header: dateHeader(group.date)) {
                        ForEach(group.behaviors, id: \.id) { behavior in
                            BehaviorHistoryRow(behavior: behavior)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle(NSLocalizedString("history.title", comment: "History"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("common.done", comment: "Done")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }

    private func dateHeader(_ date: Date) -> some View {
        HStack {
            Text(formattedDate(date))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            if Calendar.current.isDateInToday(date) {
                Text(NSLocalizedString("history.today", comment: "Today"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primaryGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.primaryGreen.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Behavior History Row

struct BehaviorHistoryRow: View {
    let behavior: Behavior

    var body: some View {
        HStack(spacing: 12) {
            // 等级图标
            ZStack {
                Circle()
                    .fill(gradeColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Text(behavior.grade)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(gradeColor)
            }

            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(behavior.name ?? NSLocalizedString("history.unknown", comment: "Unknown"))
                    .font(.system(size: 16, weight: .semibold))

                HStack(spacing: 8) {
                    Text(behavior.timestamp.formattedTime())
                        .font(.system(size: 13))
                        .foregroundColor(.gray)

                    Text("•")
                        .foregroundColor(.gray)

                    Text("\(behavior.duration)\(NSLocalizedString("history.minutes", comment: "min"))")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // 分数
            Text(scoreText)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(scoreColor)
        }
        .padding(.vertical, 4)
    }

    private var gradeColor: Color {
        switch behavior.grade {
        case "S": return .vibrantGreen
        case "A": return .primaryGreen
        case "B": return Color(hex: "#4CAF50")
        case "C": return Color(hex: "#FF9800")
        case "D": return Color(hex: "#F44336")
        case "R1", "R2", "R3": return .recoveryBlue
        default: return .gray
        }
    }

    private var scoreText: String {
        if behavior.score > 0 {
            return "+\(Int(behavior.score))"
        } else {
            return "\(Int(behavior.score))"
        }
    }

    private var scoreColor: Color {
        behavior.score >= 0 ? .primaryGreen : .red
    }
}

// MARK: - ViewModel

class BehaviorHistoryViewModel: ObservableObject {
    @Published var groupedBehaviors: [BehaviorGroup] = []

    func loadData() {
        let user = CoreDataManager.shared.fetchOrCreateUser()
        let behaviors = user.behaviorsArray.sorted { $0.timestamp > $1.timestamp }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: behaviors) { behavior in
            calendar.startOfDay(for: behavior.timestamp)
        }

        groupedBehaviors = grouped
            .sorted { $0.key > $1.key }
            .map { date, behaviors in
                BehaviorGroup(date: date, behaviors: behaviors.sorted { $0.timestamp > $1.timestamp })
            }
    }
}

struct BehaviorGroup {
    let date: Date
    let behaviors: [Behavior]
}

// MARK: - Preview

struct BehaviorHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        BehaviorHistoryView()
    }
}
