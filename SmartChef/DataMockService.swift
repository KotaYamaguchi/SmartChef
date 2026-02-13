//
//  DataMockService.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/05.
//

import Foundation
import SwiftData

struct DataMockService {

    // MARK: - Public API

    /// 全てのデータを削除してモックデータを再投入する（ランダム生成）
    static func seedMockData(context: ModelContext) {
        // 既存データの全削除
        try? context.delete(model: StockItem.self)
        try? context.delete(model: ShoppingItem.self)
        try? context.delete(model: MealHistory.self)
        try? context.delete(model: MealPlan.self)

        // ランダムモックデータを生成
        let stockMocks = generateRandomStockItems()
        let shoppingMocks = generateRandomShoppingItems()
        let historyMocks = generateRandomMealHistories()
        let mealPlanMocks = generateRandomMealPlans()

        // データベースに保存
        for item in stockMocks { context.insert(item) }
        for item in shoppingMocks { context.insert(item) }
        for item in historyMocks { context.insert(item) }
        for item in mealPlanMocks { context.insert(item) }

        try? context.save()
    }

    // MARK: - ランダム在庫データ生成

    /// ランダムな在庫データを生成（6〜12件）
    static func generateRandomStockItems() -> [StockItem] {
        let count = Int.random(in: 6...12)
        var selected: [StockItem] = []
        var usedNames: Set<String> = []

        while selected.count < count {
            let pool = stockItemPool.randomElement()!
            guard !usedNames.contains(pool.name) else { continue }
            usedNames.insert(pool.name)

            // 70% の確率で期限付き（1〜14日後）、30% は期限なし
            let deadline: Date?
            if Bool.random() || Bool.random() {  // ≈75%
                let daysUntilExpiry = Int.random(in: -1...14)
                deadline = Date().addingTimeInterval(Double(daysUntilExpiry) * 86400)
            } else {
                deadline = nil
            }

            let itemCount = Int.random(in: 1...5)
            selected.append(
                StockItem(
                    name: pool.name, category: pool.category, deadline: deadline, count: itemCount))
        }

        return selected
    }

    // MARK: - ランダム買い物リストデータ生成

    /// ランダムな買い物リストを生成（2〜6件）
    static func generateRandomShoppingItems() -> [ShoppingItem] {
        let count = Int.random(in: 2...6)
        var selected: [ShoppingItem] = []
        var usedNames: Set<String> = []

        while selected.count < count {
            let pool = shoppingItemPool.randomElement()!
            guard !usedNames.contains(pool.name) else { continue }
            usedNames.insert(pool.name)

            let itemCount = Int.random(in: 1...4)
            let isSelected = Int.random(in: 0...4) == 0  // 20% チェック済み
            selected.append(
                ShoppingItem(
                    name: pool.name, category: pool.category, count: itemCount,
                    isSelected: isSelected))
        }

        return selected
    }

    // MARK: - ランダム食事履歴データ生成

    /// ランダムな食事履歴を生成（直近7〜14日分）
    static func generateRandomMealHistories() -> [MealHistory] {
        let daysBack = Int.random(in: 7...14)
        var histories: [MealHistory] = []

        for daysAgo in 0..<daysBack {
            // 朝食（60% の確率で記録あり）
            if Int.random(in: 0...4) < 3 {
                let menu = breakfastMenuPool.randomElement()!
                histories.append(
                    MealHistory(
                        date: date(daysAgo: daysAgo, hour: Int.random(in: 7...9)),
                        menuName: menu,
                        mealType: .breakfast
                    ))
            }

            // 昼食（70% の確率で記録あり）
            if Int.random(in: 0...9) < 7 {
                let menu = lunchMenuPool.randomElement()!
                histories.append(
                    MealHistory(
                        date: date(daysAgo: daysAgo, hour: Int.random(in: 11...13)),
                        menuName: menu,
                        mealType: .lunch
                    ))
            }

            // 夕食（85% の確率で記録あり）
            if Int.random(in: 0...19) < 17 {
                let menu = dinnerMenuPool.randomElement()!
                histories.append(
                    MealHistory(
                        date: date(daysAgo: daysAgo, hour: Int.random(in: 18...20)),
                        menuName: menu,
                        mealType: .dinner
                    ))
            }
        }

        return histories
    }

    // MARK: - ランダム食事計画データ生成

    /// ランダムな食事計画を生成（今日〜2日後、各3食）
    static func generateRandomMealPlans() -> [MealPlan] {
        var plans: [MealPlan] = []

        for daysFromNow in 0...2 {
            // 朝食
            plans.append(
                MealPlan(
                    date: planDate(daysFromNow: daysFromNow, hour: 8),
                    mealType: .breakfast,
                    menuName: breakfastPlanPool.randomElement()!
                ))

            // 昼食
            plans.append(
                MealPlan(
                    date: planDate(daysFromNow: daysFromNow, hour: 12),
                    mealType: .lunch,
                    menuName: lunchPlanPool.randomElement()!
                ))

            // 夕食
            plans.append(
                MealPlan(
                    date: planDate(daysFromNow: daysFromNow, hour: 19),
                    mealType: .dinner,
                    menuName: dinnerPlanPool.randomElement()!
                ))
        }

        return plans
    }

    // MARK: - Helpers

    static func date(daysAgo: Int, hour: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = Int.random(in: 0...59)
        let base = Calendar.current.date(from: components) ?? Date()
        return base.addingTimeInterval(Double(-daysAgo) * 86400)
    }

    static func planDate(daysFromNow: Int, hour: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0
        let base = Calendar.current.date(from: components) ?? Date()
        return base.addingTimeInterval(Double(daysFromNow) * 86400)
    }

    // MARK: - データプール

    /// 在庫食材プール（名前とカテゴリのペア）
    private static let stockItemPool: [(name: String, category: FoodCategory)] = [
        // 野菜
        ("キャベツ", .vegetables), ("ほうれん草", .vegetables), ("にんじん", .vegetables),
        ("大根", .vegetables), ("ブロッコリー", .vegetables), ("トマト", .vegetables),
        ("きゅうり", .vegetables), ("ピーマン", .vegetables), ("もやし", .vegetables),
        ("白菜", .vegetables), ("長ねぎ", .vegetables), ("小松菜", .vegetables),
        ("なす", .vegetables), ("玉ねぎ", .vegetables), ("じゃがいも", .vegetables),
        ("レタス", .vegetables), ("アスパラガス", .vegetables), ("かぼちゃ", .vegetables),
        // 肉類
        ("鶏もも肉", .meat), ("鶏むね肉", .meat), ("豚バラ肉", .meat),
        ("豚ロース", .meat), ("牛切り落とし", .meat), ("ひき肉（合挽き）", .meat),
        ("鶏ささみ", .meat), ("ベーコン", .meat), ("ソーセージ", .meat),
        // 魚介類
        ("鮭切り身", .seafood), ("サバ", .seafood), ("エビ", .seafood),
        ("イカ", .seafood), ("ツナ缶", .seafood), ("しらす", .seafood),
        // 乳製品
        ("牛乳", .dairy), ("ヨーグルト", .dairy), ("チーズ", .dairy),
        ("バター", .dairy), ("生クリーム", .dairy),
        // 卵
        ("卵", .egg), ("豆腐", .egg), ("納豆", .egg), ("油揚げ", .egg),
        // 果物
        ("バナナ", .fruits), ("りんご", .fruits), ("みかん", .fruits),
        ("キウイ", .fruits), ("いちご", .fruits),
        // 調味料
        ("醤油", .seasoning), ("味噌", .seasoning), ("みりん", .seasoning),
        ("酢", .seasoning), ("塩", .seasoning), ("砂糖", .seasoning),
        ("マヨネーズ", .seasoning), ("ケチャップ", .seasoning),
        // 穀物
        ("米", .grain), ("パスタ", .grain), ("うどん（乾麺）", .grain),
        ("食パン", .grain), ("そうめん", .grain),
        // 飲料
        ("お茶", .drink), ("オレンジジュース", .drink), ("炭酸水", .drink),
        // その他
        ("こんにゃく", .other), ("わかめ", .other), ("もち", .other),
    ]

    /// 買い物リスト用の食材プール
    private static let shoppingItemPool: [(name: String, category: FoodCategory)] = [
        ("玉ねぎ", .vegetables), ("にんじん", .vegetables), ("じゃがいも", .vegetables),
        ("トマト", .vegetables), ("ほうれん草", .vegetables), ("キャベツ", .vegetables),
        ("豚バラ肉", .meat), ("鶏もも肉", .meat), ("ひき肉", .meat),
        ("牛乳", .dairy), ("卵", .egg), ("豆腐", .egg),
        ("納豆", .other), ("パン", .grain), ("バナナ", .fruits),
        ("ヨーグルト", .dairy), ("チーズ", .dairy), ("ベーコン", .meat),
        ("しめじ", .vegetables), ("エリンギ", .vegetables), ("まいたけ", .vegetables),
        ("鮭切り身", .seafood), ("エビ", .seafood), ("ツナ缶", .seafood),
        ("醤油", .seasoning), ("味噌", .seasoning), ("みりん", .seasoning),
    ]

    // MARK: - 料理名プール

    /// 朝食メニュープール
    private static let breakfastMenuPool: [String] = [
        "トースト・目玉焼き", "おにぎり", "食パン・バター", "シリアル・牛乳",
        "バナナ", "ヨーグルト・グラノーラ", "卵かけご飯", "味噌汁・ご飯",
        "パンケーキ", "フレンチトースト", "納豆ご飯", "雑炊",
        "サンドイッチ", "スムージー", "おかゆ", "ベーコンエッグ",
    ]

    /// 昼食メニュープール
    private static let lunchMenuPool: [String] = [
        "カップ麺", "ラーメン", "牛丼", "コンビニサンドイッチ",
        "チャーハン", "うどん", "パスタ", "カレーライス",
        "そば", "焼きそば", "親子丼", "天丼",
        "オムライス", "ハンバーガー", "ピザ", "タコライス",
        "冷やし中華", "つけ麺", "丸亀うどん", "回転寿司",
    ]

    /// 夕食メニュープール
    private static let dinnerMenuPool: [String] = [
        "カレーライス", "鶏もも肉の照り焼き・白米", "唐揚げ・白米・味噌汁",
        "豚の生姜焼き・白米・キャベツ千切り", "ハンバーグ・ポテトフライ",
        "焼き肉・白米", "鶏むね肉のソテー・ブロッコリー", "肉じゃが・味噌汁",
        "麻婆豆腐・白米", "回鍋肉・白米", "酢豚・白米",
        "鮭의 塩焼き・味噌汁・ご飯", "刺身定食", "煮魚定食",
        "鍋料理", "おでん", "すき焼き", "グラタン",
        "クリームシチュー", "ビーフシチュー", "豚汁・ご飯",
        "チキン南蛮・白米", "とんかつ定食", "エビフライ定食",
    ]

    /// 朝食の計画用メニュー
    private static let breakfastPlanPool: [String] = [
        "トースト・スクランブルエッグ", "ヨーグルト・バナナ", "おにぎり・牛乳",
        "卵かけご飯・味噌汁", "フレンチトースト・サラダ", "パンケーキ",
        "グラノーラ・ヨーグルト", "ベーコンエッグ・トースト", "おかゆ・漬物",
        "納豆ご飯・味噌汁", "サンドイッチ・スープ", "シリアル・フルーツ",
    ]

    /// 昼食の計画用メニュー
    private static let lunchPlanPool: [String] = [
        "鶏もも肉の照り焼き定食", "卵チャーハン", "うどん",
        "パスタ・サラダ", "親子丼", "焼きそば・スープ",
        "オムライス", "野菜炒め定食", "そば・天ぷら",
        "タコライス", "ビビンバ", "冷やし中華",
    ]

    /// 夕食の計画用メニュー
    private static let dinnerPlanPool: [String] = [
        "豆腐とほうれん草の味噌汁・白米", "鶏もも肉のソテー・サラダ", "カレーライス",
        "麻婆豆腐・白米", "肉じゃが・味噌汁", "鮭の塩焼き定食",
        "ハンバーグ・ポテトサラダ", "クリームシチュー・パン", "豚しゃぶサラダ",
        "チキン南蛮・野菜スープ", "すき焼き", "おでん・ご飯",
    ]
}
