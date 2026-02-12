//
//  AppSettings.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import Foundation

// MARK: - アプリ設定

@Observable
final class AppSettings {
    static let shared = AppSettings()

    // MARK: - 献立自動生成

    /// 献立の自動生成タイミング（朝5時 / 夕5時）
    // NOTE: ストアドプロパティにすることで @Observable が変更を追跡できる。
    // computed property + UserDefaults の直接 get/set では
    // _$observationRegistrar に通知が届かず SwiftUI が再描画されない。
    var generationMode: MealPlanGenerationMode {
        didSet { UserDefaults.standard.set(generationMode.rawValue, forKey: Keys.generationMode) }
    }

    // MARK: - 食事・レシピ設定

    /// 何人前で献立・レシピを生成するか（1〜8人、デフォルト 2）
    var servingsCount: Int {
        didSet { UserDefaults.standard.set(servingsCount, forKey: Keys.servingsCount) }
    }

    // MARK: - 在庫管理設定

    /// ダッシュボードに「期限が近い食材」として表示する残日数の閾値（デフォルト 7日）
    var expiryWarningDays: Int {
        didSet { UserDefaults.standard.set(expiryWarningDays, forKey: Keys.expiryWarningDays) }
    }

    /// 在庫一覧に期限切れのアイテムも表示するか（デフォルト: true）
    var showExpiredItems: Bool {
        didSet { UserDefaults.standard.set(showExpiredItems, forKey: Keys.showExpiredItems) }
    }

    // MARK: - スキャン設定

    /// レシートスキャン保存時、買い物リストの照合アイテムを自動削除するか（デフォルト: true）
    var autoDeleteMatchedShoppingItems: Bool {
        didSet { UserDefaults.standard.set(autoDeleteMatchedShoppingItems, forKey: Keys.autoDeleteMatchedShoppingItems) }
    }

    // MARK: - 初期化

    private init() {
        let ud = UserDefaults.standard

        generationMode = MealPlanGenerationMode(
            rawValue: ud.string(forKey: Keys.generationMode) ?? ""
        ) ?? .morning

        servingsCount = {
            let v = ud.integer(forKey: Keys.servingsCount)
            return v > 0 ? v : 2
        }()

        expiryWarningDays = {
            let v = ud.integer(forKey: Keys.expiryWarningDays)
            return v > 0 ? v : 7
        }()

        showExpiredItems = ud.object(forKey: Keys.showExpiredItems) as? Bool ?? true

        autoDeleteMatchedShoppingItems = ud.object(forKey: Keys.autoDeleteMatchedShoppingItems) as? Bool ?? true
    }

    // MARK: - UserDefaults キー

    private enum Keys {
        static let generationMode                 = "generationMode"
        static let servingsCount                  = "servingsCount"
        static let expiryWarningDays              = "expiryWarningDays"
        static let showExpiredItems               = "showExpiredItems"
        static let autoDeleteMatchedShoppingItems = "autoDeleteMatchedShoppingItems"
    }
}
