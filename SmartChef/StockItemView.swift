import SwiftData
//
//  ItemStockView.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/05.
//
import SwiftUI

struct ItemStockView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [StockItem]

    @State private var showScanner = false

    private let settings = AppSettings.shared

    /// 設定に応じて期限切れアイテムを除外したリスト
    private var filteredItems: [StockItem] {
        guard !settings.showExpiredItems else { return items }
        let today = Calendar.current.startOfDay(for: Date())
        return items.filter { item in
            guard let deadline = item.deadline else { return true }
            return Calendar.current.startOfDay(for: deadline) >= today
        }
    }

    private var groupedItems: [FoodCategory: [StockItem]] {
        Dictionary(grouping: filteredItems, by: { $0.category })
    }

    private var categories: [FoodCategory] {
        FoodCategory.allCases.filter { groupedItems[$0] != nil }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(categories, id: \.self) { category in
                            Section(header: categoryHeader(category)) {
                                ForEach(groupedItems[category] ?? []) { item in
                                    StockItemRow(item: item)
                                }
                                .onDelete { indexSet in
                                    deleteItem(at: indexSet, in: category)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("冷蔵庫")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showScanner = true
                    } label: {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $showScanner) {
                ScannerView()
            }
        }
    }

    // MARK: - サブビュー

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "refrigerator")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("冷蔵庫は空です")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("右上のカメラボタンから\nレシートをスキャンして食材を追加しましょう")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    private func categoryHeader(_ category: FoodCategory) -> some View {
        HStack(spacing: 6) {
            if let iconName = category.iconName {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            } else {
                Circle()
                    .fill(category.color)
                    .frame(width: 8, height: 8)
            }
            Text(category.rawValue)
        }
    }

    // MARK: - 削除処理

    private func deleteItem(at offsets: IndexSet, in category: FoodCategory) {
        let itemsInSection = groupedItems[category] ?? []
        for index in offsets {
            modelContext.delete(itemsInSection[index])
        }
    }
}

// MARK: - 在庫アイテム行

private struct StockItemRow: View {
    let item: StockItem

    private var daysUntilExpiry: Int? {
        guard let deadline = item.deadline else { return nil }
        return Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: deadline)
        ).day
    }

    private var expiryColor: Color {
        guard let days = daysUntilExpiry else { return .secondary }
        if days < 0 { return .red }
        if days <= 1 { return .red }
        if days <= 3 { return .orange }
        if days <= 7 { return .yellow }
        return .secondary
    }

    private var expiryText: String? {
        guard let days = daysUntilExpiry else { return nil }
        if days < 0 { return "期限切れ" }
        if days == 0 { return "今日まで" }
        if days == 1 { return "あと1日" }
        return "あと\(days)日"
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.body)
                if let text = expiryText {
                    Text(text)
                        .font(.caption)
                        .foregroundStyle(expiryColor)
                } else if item.deadline != nil {
                    Text(item.deadline!, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("\(item.count)個")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}
