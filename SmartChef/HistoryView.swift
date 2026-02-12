//
//  HistoryView.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/10.
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealHistory.date, order: .reverse) private var history: [MealHistory]

    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty {
                    ContentUnavailableView(
                        "履歴がありません",
                        systemImage: "fork.knife",
                        description: Text("「+」ボタンから食事を記録できます")
                    )
                } else {
                    List {
                        ForEach(groupedHistory, id: \.0) { dateKey, items in
                            Section(header: Text(dateKey)) {
                                ForEach(items) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.menuName)
                                                .font(.headline)
                                            Text(item.date, style: .time)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text(item.mealType.rawValue)
                                            .font(.subheadline)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(mealTypeColor(item.mealType).opacity(0.15))
                                            .foregroundColor(mealTypeColor(item.mealType))
                                            .cornerRadius(8)
                                    }
                                    .padding(.vertical, 2)
                                }
                                .onDelete { offsets in
                                    deleteItems(offsets: offsets, in: items)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("食事履歴")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddMealHistoryView()
            }
        }
    }

    // 日付ごとにグループ化した履歴を返す
    private var groupedHistory: [(String, [MealHistory])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日 (E)"

        var groups: [(String, [MealHistory])] = []
        var seen: [String: Int] = [:]

        for item in history {
            let key = formatter.string(from: item.date)
            if let idx = seen[key] {
                groups[idx].1.append(item)
            } else {
                seen[key] = groups.count
                groups.append((key, [item]))
            }
        }
        return groups
    }

    private func deleteItems(offsets: IndexSet, in items: [MealHistory]) {
        for index in offsets {
            modelContext.delete(items[index])
        }
    }

    private func mealTypeColor(_ type: MealType) -> Color {
        switch type {
        case .breakfast: return .orange
        case .lunch: return .green
        case .dinner: return .blue
        }
    }
}

// MARK: - 手動追加シート

struct AddMealHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var menuName = ""
    @State private var mealType: MealType = .dinner
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("メニュー名") {
                    TextField("例：親子丼", text: $menuName)
                }

                Section("食事の種類") {
                    Picker("食事の種類", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("日時") {
                    DatePicker("日時", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
            }
            .navigationTitle("食事を記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveHistory()
                    }
                    .disabled(menuName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .bold()
                }
            }
        }
    }

    private func saveHistory() {
        let trimmed = menuName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let newEntry = MealHistory(date: date, menuName: trimmed, mealType: mealType)
        modelContext.insert(newEntry)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: StockItem.self, ShoppingItem.self, MealHistory.self,
        configurations: config)
    DataMockService.seedMockData(context: container.mainContext)
    return HistoryView()
        .modelContainer(container)
}
