//
//  IntelligenceService.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/05.
//

import Foundation
import FoundationModels
import SwiftData

// MARK: - 1日の献立提案モデル
// NOTE: @Generable (Guided Generation) はガードレールを回避できないため Codable に変更。
//       permissiveContentTransformations モデルで String 生成し JSON パースする。

struct DailyMealPlan: Codable {
    var breakfast: String
    var lunch: String
    var dinner: String
    var reason: String
}

// MARK: - 栄養分析モデル

struct NutritionAnalysis: Codable {
    var summary: String
    var missingNutrients: [String]
    var recommendedFoods: [String]
    var advice: String
}

// MARK: - IntelligenceService

@Observable
final class IntelligenceService {
    static let shared = IntelligenceService()

    /// permissiveContentTransformations: String 生成時はガードレールチェックをスキップする
    private let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)

    var isModelAvailable: Bool {
        if case .available = model.availability {
            return true
        }
        return false
    }

    // MARK: - レシピ生成状態管理

    // NOTE: キャッシュは廃止し、SwiftData (PersistentRecipe) に保存する方針に変更。
    // UIのローディング表示用に生成中の料理名セットのみ管理する。
    private(set) var generatingDishes: Set<String> = []
    private(set) var recipeErrors: [String: String] = [:]

    private init() {}

    // MARK: - レシピ生成と永続化

    /// 指定された料理のレシピを生成し、MealPlan に紐付けて永続化する
    /// - Parameters:
    ///   - dish: 料理名
    ///   - plan: 紐付ける MealPlan
    ///   - context: SwiftData コンテキスト
    @MainActor
    func generateAndPersistRecipe(for dish: String, plan: MealPlan, context: ModelContext) async {
        guard !generatingDishes.contains(dish) else { return }

        // 既に永続化されているか確認
        if let existingRecipes = plan.recipes,
            existingRecipes.contains(where: { $0.dishName == dish })
        {
            return
        }

        generatingDishes.insert(dish)
        recipeErrors.removeValue(forKey: dish)
        print("[Intelligence] 生成開始: \(dish)")

        do {
            // レシピ生成 (generateRecipe は下部で定義)
            let detail = try await generateRecipe(for: dish)

            // PersistentRecipe に変換して保存
            let ingredients = detail.ingredients.map {
                PersistentIngredient(name: $0.name, amount: $0.amount)
            }
            let persistentRecipe = PersistentRecipe(
                dishName: detail.dishName,
                steps: detail.steps,
                cookingTime: detail.cookingTime,
                ingredients: ingredients
            )

            plan.recipes?.append(persistentRecipe)
            try context.save()

            print("[Intelligence] ✅ 生成・保存完了: \(dish)")
        } catch {
            print("[Intelligence] ❌ 生成失敗: \(dish) error=\(error)")
            recipeErrors[dish] = error.localizedDescription
        }

        generatingDishes.remove(dish)
    }

    // MARK: - レシピ生成 (内部用)

    /// 指定された料理の材料・分量・調理手順を生成する
    /// - Parameter dishName: 料理名
    /// - Returns: 2人前のレシピ詳細
    func generateRecipe(for dishName: String) async throws -> RecipeDetail {
        guard isModelAvailable else {
            throw IntelligenceError.modelUnavailable
        }

        let instructions = """
            あなたはプロの料理人です。指定された料理のレシピを2人前の分量で作成してください。
            以下の点を意識してください：
            1. 材料は主材料・調味料・仕上げの材料をすべて漏れなく列挙する
            2. 分量は具体的な数値で示す（例: 300g、大さじ2、1個）。曖昧な表現は避ける
            3. 調理手順は1ステップ1文で、初心者でも再現できるよう火加減・時間・目安などを具体的に記述する
            4. 手順は実際の調理順序通りに並べる（下ごしらえ → 加熱 → 盛り付けの流れ）
            必ず指定のJSON形式のみで回答してください。前後に説明文を付けないこと。
            """

        let session = LanguageModelSession(model: model, instructions: instructions)

        let prompt = """
            次の料理のレシピを2人前の分量で作成してください。
            料理名: \(dishName)

            以下のJSON形式のみで回答してください。他のテキストは一切不要です。
            {
              "dishName": "料理名（入力と同じ名前）",
              "ingredients": [
                {"name": "材料名", "amount": "分量"},
                {"name": "調味料名", "amount": "分量"}
              ],
              "steps": [
                "手順1（具体的に）",
                "手順2（具体的に）"
              ],
              "cookingTime": "約X分"
            }
            """

        do {
            let response = try await session.respond(to: prompt)
            return try parseJSON(response.content, as: RecipeDetail.self)
        } catch let error as IntelligenceError {
            throw error
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            throw IntelligenceError.guardrailViolation
        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            let explanation = await Self.extractRefusalExplanation(refusal)
            throw IntelligenceError.refusal(explanation)
        } catch {
            print("Recipe Generation Error: \(error)")
            throw error
        }
    }

    // MARK: - 献立生成

    /// 冷蔵庫の在庫と食事履歴をもとに今日の献立を生成する
    /// - Parameters:
    ///   - stockItems: 冷蔵庫の在庫（賞味期限でソート済み推奨）
    ///   - recentHistory: 直近の食事履歴（新着順）
    /// - Returns: 1日分の献立提案
    func generateDailyMealPlan(
        stockItems: [StockItem],
        recentHistory: [MealHistory]
    ) async throws -> DailyMealPlan {
        guard isModelAvailable else {
            throw IntelligenceError.modelUnavailable
        }

        let instructions = """
            あなたは家庭料理の専門家です。冷蔵庫の在庫と最近の食事履歴をもとに、今日1日の献立（朝食・昼食・夕食）を提案してください。

            【献立名の絶対ルール】
            - 「定食」「セット」のようなアバウトな表現は絶対に使用しない
            - 必ず具体的な料理名を返す（例: 「鶏もも肉の照り焼き・ほうれん草の胡麻和え・豆腐の味噌汁・白米」）
            - このルールはいかなる場合も例外なく守ること

            【食事別のルール】
            - 朝食: 手軽に短時間で作れるものにする。一汁三菜に拘らない
            - 昼食: 朝から短時間で準備できる料理にする。一汁三菜に拘らない
            - 夕食: 一汁三菜（主食・主菜・副菜・汁物）を意識して栄養バランスを整える
            - 健康上の観点から上記ルールを無視すべき場合はその限りではない

            【在庫・履歴の活用ルール】
            1. 賞味期限が近い食材を優先的に使う
            2. 直近の食事と重複しないようにバランスよく提案する
            3. 在庫の食材を効率よく活用する

            必ず指定のJSON形式のみで回答してください。前後に説明文を付けないこと。
            """

        let session = LanguageModelSession(model: model, instructions: instructions)

        // 在庫情報をテキスト化（賞味期限情報を含む）
        let stockText: String
        if stockItems.isEmpty {
            stockText = "（在庫なし）"
        } else {
            stockText = stockItems.map { item in
                var line = "・\(item.name)（\(item.category.rawValue)）× \(item.count)個"
                if let deadline = item.deadline {
                    let days =
                        Calendar.current.dateComponents(
                            [.day],
                            from: Calendar.current.startOfDay(for: Date()),
                            to: Calendar.current.startOfDay(for: deadline)
                        ).day ?? 0
                    switch days {
                    case ..<0: line += " ※期限切れ"
                    case 0: line += " ※今日まで"
                    case 1: line += " ※あと1日"
                    default: line += " ※あと\(days)日"
                    }
                }
                return line
            }.joined(separator: "\n")
        }

        // 食事履歴（直近7日分・最大21件）をテキスト化
        let recentMeals = Array(recentHistory.prefix(21))
        let historyText: String
        if recentMeals.isEmpty {
            historyText = "（記録なし）"
        } else {
            historyText = recentMeals.map { item in
                "\(item.date.formatted(date: .abbreviated, time: .omitted)) [\(item.mealType.rawValue)] \(item.menuName)"
            }.joined(separator: "\n")
        }

        let prompt = """
            # 冷蔵庫の在庫
            \(stockText)

            # 直近の食事履歴
            \(historyText)

            # タスク
            上記の在庫と食事履歴をもとに、今日1日の献立（朝食・昼食・夕食）を提案してください。
            賞味期限が近い食材を優先的に活用し、直近の食事と重複しないよう考慮してください。

            以下のJSON形式のみで回答してください。他のテキストは一切不要です。
            {
              "breakfast": "朝食の具体的な料理名（手軽なもの）",
              "lunch": "昼食の具体的な料理名（短時間で作れるもの）",
              "dinner": "夕食の具体的な料理名（一汁三菜を意識。例: 鮭の塩焼き・キャベツの浅漬け・わかめの味噌汁・白米）",
              "reason": "この献立を選んだ理由（在庫活用・栄養バランスなど1〜2文）"
            }
            """

        do {
            let response = try await session.respond(to: prompt)
            return try parseJSON(response.content, as: DailyMealPlan.self)
        } catch let error as IntelligenceError {
            throw error
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            throw IntelligenceError.guardrailViolation
        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            let explanation = await Self.extractRefusalExplanation(refusal)
            throw IntelligenceError.refusal(explanation)
        } catch {
            print("Meal Plan Generation Error: \(error)")
            throw error
        }
    }

    // MARK: - 夕方モード献立生成

    /// 今夜の夕食と明日の朝食・昼食を生成する（夕5時モード用）
    /// - Parameters:
    ///   - stockItems: 冷蔵庫の在庫（賞味期限でソート済み推奨）
    ///   - recentHistory: 直近の食事履歴（新着順）
    /// - Returns: DailyMealPlan（breakfast/lunch=明日分、dinner=今夜分）
    func generateEveningMealPlan(
        stockItems: [StockItem],
        recentHistory: [MealHistory]
    ) async throws -> DailyMealPlan {
        guard isModelAvailable else {
            throw IntelligenceError.modelUnavailable
        }

        let instructions = """
            あなたは家庭料理の専門家です。冷蔵庫の在庫と最近の食事履歴をもとに、今夜の夕食と明日の朝食・昼食を提案してください。

            【献立名の絶対ルール】
            - 「定食」「セット」のようなアバウトな表現は絶対に使用しない
            - 必ず具体的な料理名を返す（例: 「鶏もも肉の照り焼き・ほうれん草の胡麻和え・豆腐の味噌汁・白米」）
            - このルールはいかなる場合も例外なく守ること

            【食事別のルール】
            - 今夜の夕食: 一汁三菜（主食・主菜・副菜・汁物）を意識して栄養バランスを整える
            - 明日の朝食: 手軽に短時間で作れるものにする。一汁三菜に拘らない
            - 明日の昼食: 朝から短時間で準備できる料理にする。一汁三菜に拘らない
            - 健康上の観点から上記ルールを無視すべき場合はその限りではない

            【在庫・履歴の活用ルール】
            1. 賞味期限が近い食材を優先的に使う
            2. 直近の食事と重複しないようにバランスよく提案する
            3. 在庫の食材を効率よく活用する

            必ず指定のJSON形式のみで回答してください。前後に説明文を付けないこと。
            """

        let session = LanguageModelSession(model: model, instructions: instructions)

        // 在庫情報をテキスト化（賞味期限情報を含む）
        let stockText: String
        if stockItems.isEmpty {
            stockText = "（在庫なし）"
        } else {
            stockText = stockItems.map { item in
                var line = "・\(item.name)（\(item.category.rawValue)）× \(item.count)個"
                if let deadline = item.deadline {
                    let days =
                        Calendar.current.dateComponents(
                            [.day],
                            from: Calendar.current.startOfDay(for: Date()),
                            to: Calendar.current.startOfDay(for: deadline)
                        ).day ?? 0
                    switch days {
                    case ..<0: line += " ※期限切れ"
                    case 0: line += " ※今日まで"
                    case 1: line += " ※あと1日"
                    default: line += " ※あと\(days)日"
                    }
                }
                return line
            }.joined(separator: "\n")
        }

        // 食事履歴（直近7日分・最大21件）をテキスト化
        let recentMeals = Array(recentHistory.prefix(21))
        let historyText: String
        if recentMeals.isEmpty {
            historyText = "（記録なし）"
        } else {
            historyText = recentMeals.map { item in
                "\(item.date.formatted(date: .abbreviated, time: .omitted)) [\(item.mealType.rawValue)] \(item.menuName)"
            }.joined(separator: "\n")
        }

        let prompt = """
            # 冷蔵庫の在庫
            \(stockText)

            # 直近の食事履歴
            \(historyText)

            # タスク
            上記の在庫と食事履歴をもとに、今夜の夕食と明日の朝食・昼食を提案してください。
            賞味期限が近い食材を優先的に活用し、直近の食事と重複しないよう考慮してください。

            以下のJSON形式のみで回答してください。他のテキストは一切不要です。
            {
              "breakfast": "明日の朝食の具体的な料理名（手軽なもの）",
              "lunch": "明日の昼食の具体的な料理名（短時間で作れるもの）",
              "dinner": "今夜の夕食の具体的な料理名（一汁三菜を意識。例: 鮭の塩焼き・キャベツの浅漬け・わかめの味噌汁・白米）",
              "reason": "この献立を選んだ理由（在庫活用・栄養バランスなど1〜2文）"
            }
            """

        do {
            let response = try await session.respond(to: prompt)
            return try parseJSON(response.content, as: DailyMealPlan.self)
        } catch let error as IntelligenceError {
            throw error
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            throw IntelligenceError.guardrailViolation
        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            let explanation = await Self.extractRefusalExplanation(refusal)
            throw IntelligenceError.refusal(explanation)
        } catch {
            print("Evening Meal Plan Generation Error: \(error)")
            throw error
        }
    }

    // MARK: - 栄養分析

    /// 直近の食事履歴を分析して栄養バランスを評価する
    /// - Parameter history: 分析対象の食事履歴（新着順）
    /// - Returns: 栄養分析結果
    func analyzeMealHistory(_ history: [MealHistory]) async throws -> NutritionAnalysis {
        guard isModelAvailable else {
            throw IntelligenceError.modelUnavailable
        }

        let instructions = """
            あなたは管理栄養士です。ユーザーの食事記録を分析し、栄養バランスの評価と改善アドバイスを提供してください。
            食事名から食材・調理法を推測し、不足している栄養素とおすすめ食材を特定してください。
            必ず指定のJSON形式のみで回答してください。前後に説明文を付けないこと。
            """

        let session = LanguageModelSession(model: model, instructions: instructions)

        // 食事履歴をテキスト化（直近14日分・最大42件）
        let recentHistory = Array(history.prefix(42))
        let historyText =
            recentHistory.isEmpty
            ? "（記録なし）"
            : recentHistory.map { item in
                "\(item.date.formatted(date: .abbreviated, time: .omitted)) [\(item.mealType.rawValue)] \(item.menuName)"
            }.joined(separator: "\n")

        let prompt = """
            # 直近の食事記録
            \(historyText)

            # タスク
            上記の食事記録を分析し、栄養バランスの評価・不足している栄養素・おすすめ食材・改善アドバイスを提供してください。
            食事記録が少ない場合は、一般的な栄養バランスの観点からアドバイスしてください。

            以下のJSON形式のみで回答してください。他のテキストは一切不要です。
            {
              "summary": "栄養バランスの総評（1〜2文）",
              "missingNutrients": ["不足栄養素1", "不足栄養素2"],
              "recommendedFoods": ["おすすめ食材1", "おすすめ食材2"],
              "advice": "改善アドバイス（2〜3文）"
            }
            """

        do {
            let response = try await session.respond(to: prompt)
            return try parseJSON(response.content, as: NutritionAnalysis.self)
        } catch let error as IntelligenceError {
            throw error
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            throw IntelligenceError.guardrailViolation
        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            let explanation = await Self.extractRefusalExplanation(refusal)
            throw IntelligenceError.refusal(explanation)
        } catch {
            print("AI Analysis Error: \(error)")
            throw error
        }
    }

    // MARK: - 食材マージ

    /// 複数料理の食材リストを受け取り、類似食材を統合して買い物リスト向けにまとめる
    /// - Parameter ingredients: (name, amount, dish) のタプル配列
    /// - Returns: 統合済み食材リスト
    func mergeShoppingIngredients(
        _ ingredients: [(name: String, amount: String, dish: String)]
    ) async throws -> [MergedShoppingIngredient] {
        guard isModelAvailable else { throw IntelligenceError.modelUnavailable }
        guard !ingredients.isEmpty else { return [] }

        let instructions = """
            あなたは料理の食材管理アシスタントです。
            複数の料理で使う食材リストを分析し、同じ・似た食材をまとめて買い物リストを作成してください。

            【統合ルール】
            - 全く同じ食材名は必ず統合し、分量を合計する
            - 意味が同一または買い物で同じ商品で代替できる食材は統合する（例: 和牛と牛肉、長ねぎとネギ、にんじんと人参）
            - 統合後の名前は一般的で認識しやすい名前にする
            - 分量は数値単位が同じなら合計（例: 300g + 200g = 500g）。単位が異なる場合は「300g + 大さじ2」のように並べる
            - 調味料（塩・こしょうなど極少量のもの）は省略しても良い
            - 各食材が「どの料理に使うか」を sources フィールドに列挙する
            - category は以下から最も適切なものを選ぶ: 野菜, 肉類, 魚介類, 乳製品, 卵・日配品, 果物, 調味料, 米・麺類, 飲料, その他

            必ず指定のJSON形式のみで回答してください。
            """

        let session = LanguageModelSession(model: model, instructions: instructions)

        let ingredientLines = ingredients.map { "・\($0.name)（\($0.amount)）← \($0.dish)" }.joined(
            separator: "\n")

        let prompt = """
            # 食材リスト
            \(ingredientLines)

            # タスク
            上記の食材リストを統合し、買い物リスト用にまとめてください。

            以下のJSON配列のみで回答してください。他のテキストは不要です。
            [
              {
                "name": "統合後の食材名",
                "combinedAmount": "合計分量",
                "sources": ["使用料理名1", "使用料理名2"],
                "category": "カテゴリ名（野菜/肉類/魚介類/乳製品/卵・日配品/果物/調味料/米・麺類/飲料/その他）"
              }
            ]
            """

        do {
            let response = try await session.respond(to: prompt)
            return try parseJSON(response.content, as: [MergedShoppingIngredient].self)
        } catch let error as IntelligenceError {
            throw error
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            throw IntelligenceError.guardrailViolation
        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            let explanation = await Self.extractRefusalExplanation(refusal)
            throw IntelligenceError.refusal(explanation)
        } catch {
            print("Ingredient Merge Error: \(error)")
            throw error
        }
    }

    /// 食材リストをマージせずに、カテゴリだけ判定して返す
    /// - Parameter ingredients: (name, amount, dish) のタプル配列
    /// - Returns: カテゴリ付与済みの食材リスト（マージなし）
    func categorizeShoppingIngredients(
        _ ingredients: [(name: String, amount: String, dish: String)]
    ) async throws -> [MergedShoppingIngredient] {
        guard isModelAvailable else { throw IntelligenceError.modelUnavailable }
        guard !ingredients.isEmpty else { return [] }

        // マージ不要なので、単純に LLM にカテゴリ判定だけさせる
        // ただし、入力数が多すぎるとトークン溢れのリスクがあるため、適宜分割するか、
        // 単純なプロンプトで処理する。
        // ここでは mergeShoppingIngredients と同じフォーマットで返すが、
        // name は統合せず、combinedAmount は元の amount、sources は [dish] とする。

        let instructions = """
            あなたは料理の食材管理アシスタントです。
            食材リストを受け取り、それぞれの適切なカテゴリを判定してください。
            食材名や分量は変更せず、そのまま出力してください。

            【カテゴリ一覧】
            野菜, 肉類, 魚介類, 乳製品, 卵・日配品, 果物, 調味料, 米・麺類, 飲料, その他

            必ず指定のJSON形式のみで回答してください。
            """

        let session = LanguageModelSession(model: model, instructions: instructions)

        let ingredientLines = ingredients.map { "・\($0.name)（\($0.amount)）← \($0.dish)" }.joined(
            separator: "\n")

        let prompt = """
            # 食材リスト
            \(ingredientLines)

            # タスク
            上記の食材リストの各アイテムについて、適切なカテゴリを判定してください。
            食材名と分量は元のまま使用してください。

            以下のJSON配列のみで回答してください。
            [
              {
                "name": "食材名（元のまま）",
                "combinedAmount": "分量（元のまま）",
                "sources": ["使用料理名（元のまま）"],
                "category": "カテゴリ名"
              }
            ]
            """

        do {
            let response = try await session.respond(to: prompt)
            return try parseJSON(response.content, as: [MergedShoppingIngredient].self)
        } catch let error as IntelligenceError {
            throw error
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            throw IntelligenceError.guardrailViolation
        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            let explanation = await Self.extractRefusalExplanation(refusal)
            throw IntelligenceError.refusal(explanation)
        } catch {
            print("Ingredient Categorization Error: \(error)")
            throw error
        }
    }

    // MARK: - レシートOCRテキスト解析

    /// レシートのOCRテキストを解析し、食材リスト（ScannedItem）を返す
    /// - Parameter ocrText: VisionフレームワークのOCR抽出テキスト
    /// - Returns: カテゴリ・推定賞味期限付きの ScannedItem 配列
    func analyzeReceiptItems(_ ocrText: String) async throws -> [ScannedItem] {
        guard isModelAvailable else {
            throw IntelligenceError.modelUnavailable
        }

        let instructions = """
            あなたは食材の専門家です。レシートのOCRテキストから食材・食品を抽出し、カテゴリと推定賞味期限（購入日からの日数）を判定してください。
            食品以外の情報（税、合計金額、店名、日付、ポイント、割引など）は除外してください。
            食材名は一般的でわかりやすい名前に正規化してください（例:「コクリッチ牛乳1000ml」→「牛乳」、「国産鶏むね肉2枚」→「鶏むね肉」）。

            推定賞味期限の目安（購入日からの日数）：
            - 鶏肉・豚肉・牛肉などの生肉: 3日
            - ひき肉: 2日
            - 魚・刺身・刺身用魚: 2日
            - 豆腐・厚揚げ・油揚げ: 4日
            - 納豆: 7日
            - 卵: 14日
            - 牛乳: 10日
            - ヨーグルト: 14日
            - 葉物野菜（ほうれん草・小松菜・レタス等）: 4日
            - 根菜・芋類（にんじん・玉ねぎ・じゃがいも等）: 14日
            - きのこ類: 5日
            - 果物: 7日
            - パン・菓子パン: 5日
            - 調味料・乾物・缶詰: 90日
            必ず指定のJSON形式のみで回答してください。前後に説明文を付けないこと。
            """

        let session = LanguageModelSession(model: model, instructions: instructions)

        let prompt = """
            # レシートのOCRテキスト
            \(ocrText)

            # タスク
            上記のテキストから食材・食品と思われる品目を抽出し、JSON配列で返してください。
            食品以外（税、合計、店名、日付、ポイント等）は除外してください。
            食材名は簡潔でわかりやすい日本語の一般名称にしてください。

            以下のJSON配列のみで回答してください。他のテキストは一切不要です。
            [
              {
                "name": "食材名（一般名称）",
                "count": 個数（整数。不明なら1）,
                "category": "カテゴリ（野菜/肉類/魚介類/乳製品/卵・日配品/果物/調味料/米・麺類/飲料/その他）",
                "estimatedDaysUntilExpiry": 推定賞味期限日数（整数。調味料など長期保存品は90以上）
              }
            ]
            """

        do {
            let response = try await session.respond(to: prompt)
            let rawItems = try parseJSON(response.content, as: [ReceiptItemRaw].self)
            let today = Date()
            return rawItems.map { item in
                let category =
                    FoodCategory.allCases.first { $0.rawValue == item.category } ?? .other
                let daysUntilExpiry = max(1, item.estimatedDaysUntilExpiry)
                let deadline = Calendar.current.date(
                    byAdding: .day, value: daysUntilExpiry, to: today)
                return ScannedItem(
                    name: item.name,
                    category: category,
                    count: max(1, item.count),
                    deadline: deadline,
                    hasDeadline: item.estimatedDaysUntilExpiry < 90
                )
            }
        } catch let error as IntelligenceError {
            throw error
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            throw IntelligenceError.guardrailViolation
        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            let explanation = await Self.extractRefusalExplanation(refusal)
            throw IntelligenceError.refusal(explanation)
        } catch {
            print("Receipt Analysis Error: \(error)")
            throw error
        }
    }

    // MARK: - JSON パーサー

    /// モデルの String 応答から JSON を抽出して Decodable 型にパースする
    private func parseJSON<T: Decodable>(_ response: String, as type: T.Type) throws -> T {
        var text = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // マークダウンコードフェンス（```json ... ``` / ``` ... ```）を除去
        if let fenceOpen = text.range(of: "```"),
            let fenceClose = text.range(of: "```", range: fenceOpen.upperBound..<text.endIndex)
        {
            var inner = String(text[fenceOpen.upperBound..<fenceClose.lowerBound])
            // 先頭の "json" タグを除去
            if inner.lowercased().hasPrefix("json") { inner = String(inner.dropFirst(4)) }
            text = inner.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // JSON オブジェクト/配列の開始位置まで先頭のテキストを除去
        if let jsonStart = text.firstIndex(where: { $0 == "{" || $0 == "[" }) {
            text = String(text[jsonStart...])
        }

        guard let data = text.data(using: .utf8) else {
            throw IntelligenceError.parsingFailed
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("JSON Parse Error: \(error)\nRaw response: \(response)")
            throw IntelligenceError.parsingFailed
        }
    }

    // MARK: - Refusal Explanation ヘルパー

    /// `refusal.explanation` の Non-Sendable な Response<String> を安全に String? へ変換する
    private static func extractRefusalExplanation(
        _ refusal: LanguageModelSession.GenerationError.Refusal
    ) async -> String? {
        let text: String? = await { @Sendable in
            (try? await refusal.explanation)?.content
        }()
        return text
    }
}

// MARK: - レシート解析内部モデル

private struct ReceiptItemRaw: Codable {
    var name: String
    var count: Int
    var category: String
    var estimatedDaysUntilExpiry: Int
}

// MARK: - 食材マージ結果モデル

struct MergedShoppingIngredient: Codable {
    /// 統合後の食材名
    var name: String
    /// 合計分量（例: "500g"、"大さじ2 + 小さじ1"）
    var combinedAmount: String
    /// 使用する料理名リスト
    var sources: [String]
    /// FoodCategory の rawValue（例: "肉類"、"野菜"）
    var category: String
}

// MARK: - エラー定義

enum IntelligenceError: LocalizedError {
    case modelUnavailable
    case guardrailViolation
    case refusal(String?)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "AI機能が現在利用できません。設定でApple Intelligenceが有効になっているか確認してください。"
        case .guardrailViolation:
            return "コンテンツポリシーにより生成がブロックされました。"
        case .refusal(let message):
            return message ?? "モデルがリクエストを拒否しました。"
        case .parsingFailed:
            return "AIの応答を解析できませんでした。再度お試しください。"
        }
    }
}
