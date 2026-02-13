//
//  ShoppingListView.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/05.
//

import SwiftData
import SwiftUI

// MARK: - 買い物リスト画面

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShoppingItem.name) private var shoppingList: [ShoppingItem]

    @State private var showAddSheet = false

    // カテゴリ別にグループ化
    private var grouped: [(FoodCategory, [ShoppingItem])] {
        let order = FoodCategory.allCases
        return order.compactMap { cat in
            let items = shoppingList.filter { $0.category == cat }
            return items.isEmpty ? nil : (cat, items)
        }
    }

    private var checkedCount: Int {
        shoppingList.filter { $0.isSelected }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if shoppingList.isEmpty {
                    ContentUnavailableView(
                        "買い物リストは空です",
                        systemImage: "cart",
                        description: Text(
                            "「+」ボタンから追加できます\n買い物後は冷蔵庫タブのカメラボタンでレシートをスキャンして在庫を追加してください")
                    )
                } else {
                    List {
                        // 購入済みヒント
                        if checkedCount > 0 {
                            Section {
                                HStack(alignment:.top,spacing: 10) {
                                    Image(systemName: "lightbulb.circle.fill")
                                        .foregroundStyle(.yellow)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(checkedCount)品購入済み")
                                            .font(.subheadline.weight(.medium))
                                        Text("冷蔵庫タブのカメラボタンでレシートをスキャンすると在庫に自動追加されます")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .listRowBackground(Color.yellow.opacity(0.06))
                            }
                        }

                        ForEach(grouped, id: \.0) { category, items in
                            Section(
                                header: Label {
                                    Text(category.rawValue)
                                } icon: {
                                    if let iconName = category.iconName {
                                        Image(iconName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                    } else {
                                        Image(systemName: "circle.fill")
                                            .foregroundStyle(category.color)
                                            .font(.caption2)
                                    }
                                }
                            ) {
                                ForEach(items) { item in
                                    ShoppingItemRow(item: item)
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        let itemToDelete = items[index]
                                        modelContext.delete(itemToDelete)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("買い物リスト")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                if checkedCount > 0 {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(role: .destructive) {
                            clearCheckedItems()
                        } label: {
                            Label("チェック済みを削除", systemImage: "trash")
                                .labelStyle(.titleAndIcon)
                                .font(.subheadline)
                        }
                    }
                }
            }
            // 手動追加シート
            .sheet(isPresented: $showAddSheet) {
                AddShoppingItemSheet { name, category, count in
                    let newItem = ShoppingItem(name: name, category: category, count: count)
                    modelContext.insert(newItem)
                    try? modelContext.save()
                }
                .presentationDetents([.large])
            }
        }
    }

    // MARK: - チェック済み削除

    private func clearCheckedItems() {
        for item in shoppingList where item.isSelected {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}

// MARK: - 買い物アイテム行

private struct ShoppingItemRow: View {
    @Bindable var item: ShoppingItem

    var body: some View {
        Button {
            item.isSelected.toggle()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isSelected ? .blue : .secondary)
                    .imageScale(.large)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .strikethrough(item.isSelected)
                        .foregroundStyle(item.isSelected ? .secondary : .primary)

                    // 自動追加アイテム: 使用する献立名を表示
                    if let source = item.sourceMenuName {
                        Text(source)
                            .font(.caption)
                            .foregroundStyle(.blue.opacity(0.8))
                    }
                }

                Spacer()

                // 自動追加: レシピ分量を表示 / 手動追加: 個数を表示
                if let amount = item.recipeAmount, !amount.isEmpty {
                    Text(amount)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("\(item.count)個")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 手動追加シート

private struct AddShoppingItemSheet: View {
    let onAdd: (String, FoodCategory, Int) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: FoodCategory = .vegetables
    @State private var count: Int = 1

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("品名", text: $name)
                        .autocorrectionDisabled()
                }
                Section("カテゴリー") {
                    CategoryGridPicker(selection: $category)
                }
                Section("数量") {
                    Stepper("\(count)個", value: $count, in: 1...100)
                }
            }
            .navigationTitle("買い物を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        onAdd(trimmed, category, count)
                        dismiss()
                    }
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
