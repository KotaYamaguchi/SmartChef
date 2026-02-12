//
//  ScanResultView.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import SwiftUI
import SwiftData

// MARK: - スキャン結果確認・一括登録画面

struct ScanResultView: View {
    @State var items: [ScannedItem]
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShoppingItem.name) private var shoppingList: [ShoppingItem]

    @State private var showManualAddSheet = false
    @State private var showSavedConfirmation = false

    // 買い物リストのアイテムのうちレシートに合致するもの
    private var matchedShoppingItems: [ShoppingItem] {
        shoppingList.filter { shopping in
            items.contains { scanned in
                let sName = scanned.name.lowercased()
                let shName = shopping.name.lowercased()
                return sName.contains(shName) || shName.contains(sName) || sName == shName
            }
        }
    }

    var body: some View {
        List {
            // 認識件数ヘッダー
            Section {
                HStack(spacing: 10) {
                    Image(systemName: items.isEmpty ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(items.isEmpty ? .orange : .green)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(items.isEmpty ? "食材が認識されませんでした" : "\(items.count)品目を認識しました")
                            .font(.subheadline.weight(.semibold))
                        Text(items.isEmpty ? "「手動で追加」から食材を入力してください" : "内容を確認・編集してから冷蔵庫に追加してください")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(items.isEmpty ? Color.orange.opacity(0.08) : Color.green.opacity(0.08))
                )
            }

            // 食材一覧（編集可能）
            Section {
                ForEach($items) { $item in
                    ScannedItemEditRow(item: $item)
                }
                .onDelete { indexSet in
                    items.remove(atOffsets: indexSet)
                }

                // 手動追加ボタン
                Button {
                    showManualAddSheet = true
                } label: {
                    Label("手動で追加", systemImage: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
            } header: {
                Text("認識した食材")
            } footer: {
                if !items.isEmpty {
                    Text("左スワイプで削除、タップで編集できます")
                }
            }

            // 買い物リストとの照合
            if !matchedShoppingItems.isEmpty {
                Section {
                    ForEach(matchedShoppingItems, id: \.id) { item in
                        HStack(spacing: 10) {
                            Image(systemName: "cart.badge.checkmark")
                                .foregroundStyle(.green)
                                .imageScale(.medium)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline)
                                if let source = item.sourceMenuName {
                                    Text(source)
                                        .font(.caption)
                                        .foregroundStyle(.blue.opacity(0.8))
                                }
                            }
                            Spacer()
                            Text("チェック済みに")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("買い物リストと照合")
                } footer: {
                    Text("これらのアイテムは買い物リストから自動的に削除されます")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("スキャン結果")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    saveAllItems()
                } label: {
                    Text("冷蔵庫に追加")
                        .bold()
                }
                .disabled(items.isEmpty)
            }
        }
        .sheet(isPresented: $showManualAddSheet) {
            ManualScanItemSheet { newItem in
                items.append(newItem)
            }
        }
        .overlay {
            if showSavedConfirmation {
                savedOverlay
            }
        }
    }

    // MARK: - 保存確認オーバーレイ

    private var savedOverlay: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green)
            Text("\(items.count)品目を追加しました")
                .font(.title3.weight(.semibold))
            if !matchedShoppingItems.isEmpty && AppSettings.shared.autoDeleteMatchedShoppingItems {
                Text("買い物リストから\(matchedShoppingItems.count)件を削除しました")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - 一括保存処理

    private func saveAllItems() {
        // 在庫に追加
        for item in items {
            let stock = StockItem(
                name: item.name,
                category: item.category,
                deadline: item.hasDeadline ? item.deadline : nil,
                count: item.count
            )
            modelContext.insert(stock)
        }

        // 買い物リストの合致アイテムを削除（設定が有効な場合のみ）
        if AppSettings.shared.autoDeleteMatchedShoppingItems {
            for shoppingItem in matchedShoppingItems {
                modelContext.delete(shoppingItem)
            }
        }

        try? modelContext.save()

        // 完了アニメーション → 画面を閉じる
        withAnimation(.spring(duration: 0.4)) {
            showSavedConfirmation = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            onComplete()
        }
    }
}

// MARK: - 個別食材編集行

struct ScannedItemEditRow: View {
    @Binding var item: ScannedItem
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 折りたたみヘッダー行
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    // カテゴリカラードット
                    Circle()
                        .fill(item.category.color)
                        .frame(width: 10, height: 10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name.isEmpty ? "（名前未設定）" : item.name)
                            .font(.body)
                            .foregroundStyle(item.name.isEmpty ? .secondary : .primary)
                        HStack(spacing: 6) {
                            Text(item.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("×\(item.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if item.hasDeadline, let deadline = item.deadline {
                                Text(deadline, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            // 展開時の編集フォーム
            if isExpanded {
                Divider().padding(.vertical, 4)

                VStack(spacing: 10) {
                    // 食材名
                    HStack {
                        Text("食材名")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 56, alignment: .leading)
                        TextField("食材名を入力", text: $item.name)
                            .textFieldStyle(.roundedBorder)
                    }

                    // カテゴリ
                    HStack {
                        Text("カテゴリ")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 56, alignment: .leading)
                        Picker("", selection: $item.category) {
                            ForEach(Category.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    // 個数
                    HStack {
                        Text("個数")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 56, alignment: .leading)
                        Stepper("\(item.count)個", value: $item.count, in: 1...99)
                            .fixedSize()
                    }

                    // 賞味期限
                    HStack {
                        Text("期限")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 56, alignment: .leading)
                        Toggle("", isOn: $item.hasDeadline)
                            .labelsHidden()
                        if item.hasDeadline {
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { item.deadline ?? Date() },
                                    set: { item.deadline = $0 }
                                ),
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        } else {
                            Text("設定なし")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - カテゴリカラー拡張

extension Category {
    var color: Color {
        switch self {
        case .vegetables:  return .green
        case .meat:        return .red
        case .seafood:     return .blue
        case .dairy:       return .yellow
        case .egg:         return .orange
        case .fruits:      return .pink
        case .seasoning:   return .brown
        case .grain:       return .indigo
        case .drink:       return .cyan
        case .other:       return .gray
        }
    }
}

// MARK: - 手動追加シート（スキャン結果と親和性のあるUI）

struct ManualScanItemSheet: View {
    let onAdd: (ScannedItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category: Category = .other
    @State private var count = 1
    @State private var hasDeadline = false
    @State private var deadline = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now

    var body: some View {
        NavigationStack {
            Form {
                Section("食材情報") {
                    TextField("食材名", text: $name)
                        .autocorrectionDisabled()
                    Picker("カテゴリー", selection: $category) {
                        ForEach(Category.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    Stepper("個数: \(count)個", value: $count, in: 1...100)
                }
                Section("賞味期限") {
                    Toggle("期限を設定", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("賞味期限", selection: $deadline, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("手動で追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("リストに追加") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        let item = ScannedItem(
                            name: trimmed,
                            category: category,
                            count: count,
                            deadline: hasDeadline ? deadline : nil,
                            hasDeadline: hasDeadline
                        )
                        onAdd(item)
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
