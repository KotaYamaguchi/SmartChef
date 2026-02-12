//
//  SettingsView.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    private let settings = AppSettings.shared
    @Environment(\.modelContext) private var modelContext

    @State private var showClearBarcodeConfirm = false
    @State private var showClearAllDataConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 食事設定
                Section {
                    Stepper(value: Binding(
                        get: { settings.servingsCount },
                        set: { settings.servingsCount = $0 }
                    ), in: 1...8) {
                        HStack {
                            Label("何人前", systemImage: "person.2")
                            Spacer()
                            Text("\(settings.servingsCount)人前")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                } header: {
                    Label("食事設定", systemImage: "fork.knife")
                } footer: {
                    Text("献立提案・レシピの材料量がこの人数に合わせて生成されます。")
                }

                // MARK: - 在庫管理
                Section {
                    HStack {
                        Label("期限警告の日数", systemImage: "bell.badge")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { settings.expiryWarningDays },
                            set: { settings.expiryWarningDays = $0 }
                        )) {
                            ForEach([3, 5, 7, 10, 14], id: \.self) { days in
                                Text("\(days)日前").tag(days)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

                    Toggle(isOn: Binding(
                        get: { settings.showExpiredItems },
                        set: { settings.showExpiredItems = $0 }
                    )) {
                        Label("期限切れアイテムを表示", systemImage: "calendar.badge.exclamationmark")
                    }
                } header: {
                    Label("在庫管理", systemImage: "refrigerator")
                } footer: {
                    Text("ダッシュボードの「今日使うべき食材」は期限警告日数以内の食材を表示します。期限切れアイテムを非表示にすると、在庫一覧から期限切れのものが除外されます。")
                }

                // MARK: - スキャン設定
                Section {
                    Toggle(isOn: Binding(
                        get: { settings.autoDeleteMatchedShoppingItems },
                        set: { settings.autoDeleteMatchedShoppingItems = $0 }
                    )) {
                        Label("買い物リストを自動照合", systemImage: "cart.badge.checkmark")
                    }
                } header: {
                    Label("スキャン設定", systemImage: "barcode.viewfinder")
                } footer: {
                    Text("有効にすると、レシートスキャン時に買い物リストと照合し、購入済みアイテムを自動で削除します。")
                }

                // MARK: - 献立自動生成
                Section {
                    ForEach(MealPlanGenerationMode.allCases, id: \.self) { mode in
                        ModeSelectionRow(
                            mode: mode,
                            isSelected: settings.generationMode == mode
                        ) {
                            settings.generationMode = mode
                            MealPlanScheduler.scheduleNextGeneration()
                        }
                    }
                } header: {
                    Label("献立の自動生成タイミング", systemImage: "clock.arrow.2.circlepath")
                } footer: {
                    Text("選択したタイミングで、冷蔵庫の在庫と食事履歴をもとに自動的に献立を生成します。バックグラウンドで実行されるため、アプリが閉じていても動作します。")
                }

                // MARK: - AI機能
                Section {
                    HStack {
                        Label("Apple Intelligence", systemImage: "apple.intelligence")
                        Spacer()
                        if IntelligenceService.shared.isModelAvailable {
                            Label("利用可能", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        } else {
                            Label("利用不可", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                } header: {
                    Label("AI機能", systemImage: "brain")
                } footer: {
                    if !IntelligenceService.shared.isModelAvailable {
                        Text("設定アプリ → Apple Intelligence と Siri でApple Intelligenceを有効にしてください。")
                            .foregroundColor(.red)
                    }
                }

                // MARK: - データ管理
                Section {
                    Button(role: .destructive) {
                        showClearBarcodeConfirm = true
                    } label: {
                        Label("バーコードキャッシュをリセット", systemImage: "barcode")
                    }

                    Button(role: .destructive) {
                        showClearAllDataConfirm = true
                    } label: {
                        Label("すべてのデータを削除", systemImage: "trash")
                    }
                } header: {
                    Label("データ管理", systemImage: "externaldrive")
                } footer: {
                    Text("バーコードキャッシュをリセットすると、登録済みの商品名が削除されます。「すべてのデータを削除」は在庫・献立・食事履歴・買い物リストを削除します。いずれも取り消せません。")
                }

                // MARK: - このアプリについて
                Section {
                    LabeledContent("バージョン") {
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("ビルド") {
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("このアプリについて", systemImage: "info.circle")
                }

                // MARK: - 開発用ツール
                Section("開発用ツール") {
                    Button(action: {
                        DataMockService.seedMockData(context: modelContext)
                    }) {
                        Label("サンプルデータを投入", systemImage: "tray.and.arrow.down")
                    }
                }
            }
            .navigationTitle("設定")
            .confirmationDialog(
                "バーコードキャッシュをリセットしますか？",
                isPresented: $showClearBarcodeConfirm,
                titleVisibility: .visible
            ) {
                Button("リセット", role: .destructive) {
                    BarcodeCache.shared.reset()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("登録済みの商品名がすべて削除されます。この操作は取り消せません。")
            }
            .confirmationDialog(
                "すべてのデータを削除しますか？",
                isPresented: $showClearAllDataConfirm,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    clearAllData()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("在庫・献立・食事履歴・買い物リストがすべて削除されます。この操作は取り消せません。")
            }
        }
    }

    // MARK: - 全データ削除

    private func clearAllData() {
        try? modelContext.delete(model: StockItem.self)
        try? modelContext.delete(model: MealPlan.self)
        try? modelContext.delete(model: MealHistory.self)
        try? modelContext.delete(model: ShoppingItem.self)
        try? modelContext.save()
    }
}

// MARK: - モード選択行

private struct ModeSelectionRow: View {
    let mode: MealPlanGenerationMode
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: iconName)
                        .foregroundColor(iconColor)
                        .font(.system(size: 18))
                }

                // テキスト
                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.displayName)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.primary)
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // 生成対象の内訳
                    mealsBreakdownView
                        .padding(.top, 2)
                }

                Spacer()

                // 選択チェック
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // 生成対象のバッジ列
    @ViewBuilder
    private var mealsBreakdownView: some View {
        switch mode {
        case .morning:
            HStack(spacing: 4) {
                mealBadge("朝食", color: .orange)
                mealBadge("昼食", color: .green)
                mealBadge("夕食", color: .indigo)
                Text("(今日分)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        case .evening:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    mealBadge("夕食", color: .indigo)
                    Text("(今日)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 4) {
                    mealBadge("朝食", color: .orange)
                    mealBadge("昼食", color: .green)
                    Text("(明日分)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func mealBadge(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption2)
            .bold()
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }

    private var iconName: String {
        switch mode {
        case .morning: return "sunrise.fill"
        case .evening: return "sunset.fill"
        }
    }

    private var iconColor: Color {
        switch mode {
        case .morning: return .orange
        case .evening: return .indigo
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: [StockItem.self, MealPlan.self, MealHistory.self, ShoppingItem.self],
                        inMemory: true)
}
