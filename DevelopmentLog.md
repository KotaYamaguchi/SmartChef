# DevelopmentLog.md

SmartChef の機能追加・変更履歴を時系列で記録します。
初期実装（dailyMealPlanSection / 在庫連動完了報告）は IMPLEMENTATION_LOG.md を参照。

---

## Session 1: AI レシピ生成の基盤整備

### 背景

Foundation Models の @Generable を使った Guided Generation は、料理レシピのような日常的な文字列でもガードレールに引っかかり生成が失敗するケースがあった。

### 対応: @Generable → Codable + JSON 文字列生成方式に切り替え

- `SystemLanguageModel(guardrails: .permissiveContentTransformations)` を使用
- `parseJSON<T: Decodable>` ヘルパーを追加: Markdown コードフェンス除去 → JSON 開始位置検出 → `JSONDecoder`
- `IntelligenceError` enum: `.guardrailViolation`, `.refusal(String?)`, `.parsingFailed`
- `LanguageModelSession.GenerationError.refusal` の explanation は `(try? await refusal.explanation)?.content` で取得（型不一致の修正）

### 追加したモデル・メソッド (IntelligenceService.swift)

| 追加物 | 内容 |
|---|---|
| `DailyMealPlan: Codable` | breakfast / lunch / dinner / reason |
| `RecipeDetail: Codable` | dishName / ingredients / steps / cookingTime |
| `generateDailyMealPlan(stockItems:recentHistory:)` | 在庫・履歴をもとに 1 日分の献立を生成 |
| `generateRecipe(for:)` | 指定料理の 2 人前レシピを生成 |

### RecipeView.swift 新規作成

- `DishRecipeSection` コンポーネント: 生成中はプログレスビュー、完了後に食材・手順を展開表示
- `RecipeView`: 選択日の献立一覧からレシピをリスト表示

---

## Session 2: レシピ生成タイミング変更・インライン表示・バックグラウンド自動生成

### 2-1. レシピのプリフェッチ (IntelligenceService.swift, DashBordView.swift)

**課題:** ユーザーが RecipeView を開いた時点でレシピ生成が始まり、待ち時間が発生していた。

**変更:** 献立生成完了のタイミングでレシピ生成も同時に開始するプリフェッチ方式に変更。

IntelligenceService に追加したキャッシュ状態プロパティ:

```swift
private(set) var cachedRecipes:    [String: RecipeDetail] = [:]
private(set) var generatingDishes: Set<String>            = []
private(set) var recipeErrors:     [String: String]       = [:]
```

`prefetchRecipes(for dishes: [String])`: キャッシュ済み・生成中の料理はスキップし、未生成のものだけ Task で並行生成。
`DashBordView.generateTodayMealPlan()` 末尾で `prefetchDishes(from: s)` を呼び出す。

---

### 2-2. RecipeView を廃止してインライン表示に変更 (DashBordView.swift)

- `MealPlanDetailView` 内の「レシピを確認・生成」NavigationLink を削除
- `dishes` computed property（menuName を「・」で分割）から `ForEach` で `DishRecipeSection` をインライン表示
- `.task` で未キャッシュ・未生成の品目のプリフェッチを起動

---

### 2-3. 毎朝5時の自動生成 (MealPlanScheduler.swift, SmartChefApp.swift)

**MealPlanScheduler.swift 新規作成:**

- `BGTaskScheduler` を使用した `BGAppRefreshTask` の登録・スケジュール管理
- taskIdentifier: `com.kotayamaguchi.SmartChef.dailyMealPlan`
- `scheduleNextGeneration()`: モードの `scheduledHour` 時刻にリクエスト送信
- `handleTask(_:modelContainer:)`: 献立生成 → レシピプリフェッチまで実行

Xcode 設定が必要:
- Signing & Capabilities → "Background Modes" → "Background fetch" にチェック
- Info.plist に `BGTaskSchedulerPermittedIdentifiers` = `com.kotayamaguchi.SmartChef.dailyMealPlan`

**SmartChefApp.swift の変更:**

`.modelContainer(for:)` モディファイアから手動 `ModelContainer` 作成に変更。
`init()` でハンドラ登録とスケジュールを実行するために必要。

---

## Session 3: 献立生成タイミング設定（朝5時モード / 夕5時モード）

### 3-1. 新規モデル・設定クラス

**Models.swift に MealPlanGenerationMode 追加:**

```swift
enum MealPlanGenerationMode: String, CaseIterable {
    case morning = "morning"  // scheduledHour: 5  → 今日の朝食・昼食・夕食
    case evening = "evening"  // scheduledHour: 17 → 今夜の夕食 + 明日の朝食・昼食
}
```

**AppSettings.swift 新規作成:**

`@Observable final class AppSettings` のシングルトン。
`generationMode` を stored property + `didSet` で実装。

理由: computed property では `@Observable` の `_$observationRegistrar` にストアドプロパティとして登録されないため、SwiftUI が変更を検知できない。

```swift
var generationMode: MealPlanGenerationMode {
    didSet { UserDefaults.standard.set(generationMode.rawValue, forKey: "generationMode") }
}
```

### 3-2. 夕方モードの献立生成 (IntelligenceService.swift)

`generateEveningMealPlan(stockItems:recentHistory:)` を追加。
返り値の `DailyMealPlan` は breakfast/lunch が明日分、dinner が今夜分。

### 3-3. 設定 UI (SettingsView.swift, ContentView.swift)

- `SettingsView.swift` 新規作成: モード選択 UI（ModeSelectionRow コンポーネント）
- `ContentView.swift`: タブ 6 として「設定」を追加

### 3-4. ダッシュボードのモード対応 (DashBordView.swift)

| 追加・変更 | 内容 |
|---|---|
| `private let settings = AppSettings.shared` | @Observable 監視のためストアドプロパティで保持 |
| `eveningBatchPlans()` | 今夜の夕食 + 明日の朝食・昼食を返すフィルタ関数 |
| `dailyMealPlanSection` | mode に応じてセクションタイトル・フッターを切り替え |
| `generateTodayMealPlan()` | switch mode で .morning / .evening を分岐 |
| `.task` フォールバック | `hour >= mode.scheduledHour` かつ対象計画が空のとき自動生成 |

---

## Session 4: レシピから買い物リストへの自動補充

### 4-1. データモデル拡張 (Models.swift)

`ShoppingItem` に以下を追加:

```swift
var sourceMenuName: String?  // 例: "鶏の照り焼き（夕食）"
var recipeAmount: String?    // 例: "300g"
```

### 4-2. AI 食材マージ (IntelligenceService.swift)

`MergedShoppingIngredient: Codable` 構造体をクラス外に追加（name, combinedAmount, sources, category）。

`mergeShoppingIngredients(_ ingredients:)` メソッドを追加:
- 複数料理の食材リストを AI に送り、類似食材を統合（例: 和牛 + 牛肉 → 牛肉）
- 分量は同単位なら合計、単位が異なれば併記
- category は Category.rawValue の文字列で返す

### 4-3. 自動補充サービス (ShoppingAutoFillService.swift 新規作成)

`fillShoppingList(recipes:mealPlans:stockItems:existingShoppingItems:context:)` の処理フロー:

1. mealPlans から `dishName → mealType.rawValue` のマッピングを構築
2. 全レシピから生の食材リストを収集
3. `mergeShoppingIngredients` で AI マージ
4. 在庫名・既存買い物リスト名（lowercase）と照合し、なければ ShoppingItem を insert
5. sourceMenuName を「鶏の照り焼き（夕食）」形式で付与

`clearAutoAddedItems(from:context:)`: `sourceMenuName != nil` のアイテムを全削除。

### 4-4. 自動補充トリガー (DashBordView.swift)

追加した State:
```swift
@Query private var shoppingItems: [ShoppingItem]
@State private var pendingShoppingDishes: Set<String> = []
@State private var isFillingShoppingList = false
```

`.onChange(of: IntelligenceService.shared.generatingDishes)` で完了を検知:

```swift
// 全品目が「キャッシュ済み OR エラー済み」になったら発火
let allSettled = pendingShoppingDishes.allSatisfy { dish in
    intelligence.cachedRecipes[dish] != nil || intelligence.recipeErrors[dish] != nil
}
```

バグ修正: 旧実装は `allSatisfy({ cachedRecipes[$0] != nil })` のみだったため、1件でもレシピ生成に失敗すると補充が永遠にトリガーされなかった。recipeErrors の確認を追加して解決。

### 4-5. 買い物リスト UI 全面刷新 (ShoppingListView.swift)

| 構造体 | 役割 |
|---|---|
| `ShoppingListView` | カテゴリ別グループ表示（Category.allCases 順） |
| `ShoppingItemRow` | 食材名 + sourceMenuName（青文字） + recipeAmount or 個数 |
| `ShoppingCompletionSheet` | 購入完了時の賞味期限設定シート（アイテムごとにトグル + DatePicker） |
| `AddShoppingItemSheet` | 手動追加フォームを独立した struct に抽出 |

ShoppingCompletionSheet の動作:
1. 選択済みアイテムを一覧表示
2. 各アイテムにトグルで賞味期限を有効化（デフォルト +7 日）
3. 「追加する」で onConfirm([(ShoppingItem, Date?)]) を呼び出し
4. `applyStockAddition` で StockItem 生成・ShoppingItem 削除・保存

---

## デバッグログの追加（一時的）

フロー全体の動作確認のため以下に print を追加:

| ファイル | 追加箇所 |
|---|---|
| `DashBordView.swift` | prefetchDishes, .onChange, autoFillShoppingList |
| `IntelligenceService.swift` | prefetchRecipes（開始・成功・失敗・generatingDishes の変化） |
| `ShoppingAutoFillService.swift` | fillShoppingList の各ステップ |

DebugLog.txt による実機確認結果:
- 全フロー（プリフェッチ → onChange → autoFill → fillShoppingList → context.save）が正常に動作することを確認
- 15 件の ShoppingItem が正常に insert・保存されることを確認

---

## 現在のファイル構成（追加・変更分）

| ファイル | 状態 | 主な変更 |
|---|---|---|
| `Models.swift` | 変更 | MealPlanGenerationMode 追加、ShoppingItem に sourceMenuName/recipeAmount 追加 |
| `IntelligenceService.swift` | 変更 | recipe キャッシュ、prefetchRecipes、generateEveningMealPlan、mergeShoppingIngredients、MergedShoppingIngredient 追加 |
| `AppSettings.swift` | 新規 | @Observable 設定シングルトン（generationMode） |
| `SettingsView.swift` | 新規 | モード選択 UI |
| `MealPlanScheduler.swift` | 新規 | BGTaskScheduler による自動生成スケジューラ |
| `ShoppingAutoFillService.swift` | 新規 | レシピ → 買い物リスト自動補充サービス |
| `SmartChefApp.swift` | 変更 | 手動 ModelContainer、init() で BGTask 登録 |
| `ContentView.swift` | 変更 | 設定タブ追加（6 タブ構成に） |
| `DashBordView.swift` | 変更 | モード対応、インラインレシピ、買い物リスト自動補充トリガー |
| `ShoppingListView.swift` | 変更 | カテゴリ別グループ、sourceMenuName 表示、ShoppingCompletionSheet |
| `RecipeView.swift` | 変更 | IntelligenceService.shared キャッシュを使用するように変更 |

---

## 既知の TODO

| 項目 | 詳細 |
|---|---|
| デバッグログの削除 | リリース前に [ShoppingFill] print 文を全削除する |
| Xcode BGTask 設定 | Background Modes capability と Info.plist の BGTaskSchedulerPermittedIdentifiers が手動設定必要 |
| editMenuName の買い物リスト再補充 | 献立名を変更したとき、買い物リストも更新されない（現在はレシピプリフェッチのみ） |
| 調味料スキップの精度 | mergeShoppingIngredients のプロンプトで「調味料は省略しても良い」としているが、AI の判断に依存するため実際には追加されることがある |

---

## Session 5: 在庫自動入力機能（レシートスキャン・バーコードスキャン）

### 背景

買い物後に食材を 1 件ずつ手動で登録する手間をなくすため、「撮るだけ・かざすだけ」で在庫を一括登録できるスキャン機能を実装した。同時に、既存の手動追加フロー（冷蔵庫タブの＋ボタン）と「購入完了」フロー（買い物リストからの在庫移動）を廃止し、スキャン中心の新 UX に刷新した。

### 5-1. データモデルの追加 (Models.swift)

**`ScannedItem` (struct, 非永続):**
スキャン結果の確認・編集画面（`ScanResultView`）でのステージング用一時モデル。SwiftData には保存されない。

```swift
struct ScannedItem: Identifiable {
    var id = UUID()
    var name: String
    var category: Category
    var count: Int
    var deadline: Date?
    var hasDeadline: Bool
}
```

**`BarcodeCache` / `BarcodeCacheEntry`:**
バーコード文字列と商品名・カテゴリのペアを UserDefaults に JSON で永続化するローカルキャッシュ。次回同じバーコードをスキャンしたとき自動で商品名を補完する。

### 5-2. AI レシート解析メソッドの追加 (IntelligenceService.swift)

`analyzeReceiptItems(_ ocrText: String) async throws -> [ScannedItem]` を追加。

処理フロー:
1. Vision OCR で取得したテキストを Apple Intelligence に渡す
2. `[{name, count, category, estimatedDaysUntilExpiry}]` 形式の JSON を生成させる
3. 食品以外（税・合計・店名等）は除外、食材名を一般名称に正規化
4. `estimatedDaysUntilExpiry >= 90` のものは `hasDeadline = false`（調味料等の長期保存品）
5. `parseJSON()` でデコード → `ScannedItem` 配列に変換

**内部モデル:** `ReceiptItemRaw` (private struct, Codable) — AI 出力の中間型。

### 5-3. 新規ファイル作成 — `ScannerView.swift`

`ScanMode` (`.receipt` / `.barcode`) を Segmented Picker で切り替えるカメラ画面。

**`CameraController` (NSObject):**
- `AVCaptureSession` + `AVCapturePhotoOutput` + `AVCaptureMetadataOutput` を一元管理
- `AVCapturePhotoCaptureDelegate`: `nonisolated` + `Task { @MainActor in ... }` パターン（`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` 対応）
- `AVCaptureMetadataOutputObjectsDelegate`: 2.5 秒クールダウンで重複検出を防止
- `setup()` / `stop()` は `Task.detached { }` でバックグラウンド実行

**`CameraPreviewView` (UIViewRepresentable):**
`UIView.layerClass` を `AVCaptureVideoPreviewLayer.self` にオーバーライドして AVFoundation と SwiftUI をブリッジ。

**レシートスキャンフロー:**
撮影 → `VNRecognizeTextRequest`（ja-JP / en-US） → `analyzeReceiptItems()` → `ScanResultView` へプッシュ

**バーコードスキャンフロー:**
検出 → `BarcodeCache.shared.get(barcode)` → ヒット時即時追加＋トースト / ミス時 `BarcodeNameInputSheet` で入力 → キャッシュ保存

### 5-4. 新規ファイル作成 — `ScanResultView.swift`

スキャン結果の確認・編集・一括登録画面。`ScannerView` から `NavigationStack` でプッシュされる。

**`ScannedItemEditRow`:** 折りたたみ式編集行（食材名 / カテゴリ / 個数 / 賞味期限）

**`saveAllItems()`:**
1. `ScannedItem` → `StockItem` を一括 insert
2. 買い物リストと名前の部分一致照合 → 合致アイテムを delete
3. 完了アニメーション（1.2 秒）→ `onComplete()` で全画面を閉じる

**`ManualScanItemSheet`:** スキャン結果と統一された UX でリストに手動追加できるシート。

**`Category.color` 拡張:** カテゴリカラードット表示用の `Color` 拡張。

### 5-5. 既存ファイルの変更

**`StockItemView.swift`:**
- ~~手動追加シート（＋ボタン）~~ を廃止
- ツールバーを `camera.badge.plus` ボタン → `.fullScreenCover { ScannerView() }` に変更

**`ShoppingListView.swift`:**
- ~~「購入完了」ボタン・`ShoppingCompletionSheet`~~ を廃止
- チェック済みが存在する場合のスキャン誘導バナーを追加
- 「チェック済みを削除」ボタンを追加

**`Info.plist`:**
`NSCameraUsageDescription` を追加。

### 設計上の注意点

- `CameraController` のホルダは `@State private var` で保持（`let` だと View 再生成のたびに新インスタンスが作られる）
- `ScanResultView` にはカスタム戻るボタン不要。NavigationStack のネイティブ戻るボタンでカメラに戻れる
- `analyzeReceiptItems()` はクラス内（`parseJSON()` の直前）に配置すること。クラス外に置くとコンパイルエラー

---

## Session 6: 設定画面の拡充（AppSettings + SettingsView 全面改修）

### 背景

既存の設定画面は「献立自動生成タイミング選択」と「AI 機能表示」のみだった。アプリの挙動に影響するパラメータ（何人前・期限警告日数・期限切れ表示・スキャン自動照合）をユーザーが変更できるようにするため、設定画面を全面的に拡充した。

### 6-1. AppSettings.swift — 設定プロパティの追加

既存の `generationMode` に加え 4 プロパティを追加:

| プロパティ | 型 | デフォルト | 用途 |
|---|---|---|---|
| `servingsCount` | `Int` | `2` | 献立・レシピの生成人数（1〜8人） |
| `expiryWarningDays` | `Int` | `7` | ダッシュボードの期限警告閾値日数 |
| `showExpiredItems` | `Bool` | `true` | 在庫一覧への期限切れアイテム表示 |
| `autoDeleteMatchedShoppingItems` | `Bool` | `true` | スキャン保存時の買い物リスト自動削除 |

全プロパティが stored property + `didSet` → `UserDefaults` 保存パターン。

### 6-2. Models.swift — BarcodeCache.reset() の追加

設定画面の「バーコードキャッシュをリセット」に対応:

```swift
func reset() {
    UserDefaults.standard.removeObject(forKey: userDefaultsKey)
}
```

### 6-3. SettingsView.swift — 全面再構成

8 セクション構成のフォームに全面改訂:

| セクション | 内容 |
|---|---|
| 食事設定 | `servingsCount` Stepper (1〜8) |
| 在庫管理 | `expiryWarningDays` Picker (3/5/7/10/14日) + `showExpiredItems` Toggle |
| スキャン設定 | `autoDeleteMatchedShoppingItems` Toggle |
| 献立の自動生成タイミング | 既存 `ModeSelectionRow` を流用 |
| AI機能 | 既存の Apple Intelligence 利用可否表示を流用 |
| データ管理 | バーコードキャッシュリセット + 全データ削除（`confirmationDialog` 付き） |
| このアプリについて | `Bundle.main.infoDictionary` からバージョン・ビルド番号を取得 |
| 開発用ツール | 既存のサンプルデータ投入ボタンを流用 |

`AppSettings` は `@Observable` だが SwiftUI コントロールは `Binding` を要求するため、`Binding(get:set:)` でブリッジ。

### 6-4. DashBordView.swift — ハードコード除去

```swift
// 変更前
let sevenDaysLater = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

// 変更後
let threshold = Calendar.current.date(
    byAdding: .day,
    value: settings.expiryWarningDays,
    to: Date()
) ?? Date()
```

### 6-5. StockItemView.swift — 期限切れフィルタ

`filteredItems` computed property を追加し、`showExpiredItems = false` のとき期限切れアイテムをリストから除外。`groupedItems`・`categories`・空状態判定すべてを `filteredItems` ベースに変更。

### 6-6. ScanResultView.swift — 自動削除の条件分岐

`saveAllItems()` 内の買い物リスト削除処理を `AppSettings.shared.autoDeleteMatchedShoppingItems` で条件分岐。完了オーバーレイの「削除しました」メッセージも同様。

---

## 現在のファイル構成（追加・変更分）

| ファイル | 状態 | 主な変更 |
|---|---|---|
| `Models.swift` | 変更 | ScannedItem / BarcodeCache / BarcodeCacheEntry 追加、BarcodeCache.reset() 追加 |
| `IntelligenceService.swift` | 変更 | analyzeReceiptItems() 追加 |
| `AppSettings.swift` | 変更 | servingsCount / expiryWarningDays / showExpiredItems / autoDeleteMatchedShoppingItems 追加 |
| `SettingsView.swift` | 変更（全面再構成） | 8 セクション構成の設定フォームに刷新 |
| `ScannerView.swift` | 新規 | CameraController / CameraPreviewView / ScannerView / BarcodeNameInputSheet |
| `ScanResultView.swift` | 新規 | ScanResultView / ScannedItemEditRow / ManualScanItemSheet / Category.color 拡張 |
| `StockItemView.swift` | 変更 | 手動追加シート廃止、カメラボタン追加、showExpiredItems フィルタ追加 |
| `ShoppingListView.swift` | 変更 | 購入完了フロー廃止、スキャン誘導バナー追加 |
| `DashBordView.swift` | 変更 | urgentItems() の日数ハードコード → AppSettings.expiryWarningDays に変更 |
| `ScanResultView.swift` | 変更 | autoDeleteMatchedShoppingItems による条件分岐 |
| `Info.plist` | 変更 | NSCameraUsageDescription 追加 |

---

## Session 7: 献立・買い物リスト生成完了時のローカル通知

### 背景

献立生成 → レシピ生成 → 買い物リスト自動補充の一連の処理にはAI生成を含むため数十秒〜数分かかる。ユーザーがアプリを操作せずに待っていたり、バックグラウンドで自動生成された場合に、完了タイミングを知る手段がなかった。

### 7-1. NotificationService.swift 新規作成

`UNUserNotificationCenter` を使ったローカル通知サービス。

| メソッド | 内容 |
|---|---|
| `requestAuthorization()` | アプリ起動時に通知許可をリクエスト（.alert, .sound, .badge） |
| `sendMealPlanReadyNotification(dishCount:shoppingItemCount:)` | フォアグラウンドでの献立・レシピ・買い物リスト生成完了時の通知。品目数・買い物リスト追加件数をメッセージに含む |
| `sendBackgroundMealPlanNotification(mode:)` | バックグラウンドタスクでの自動生成完了時の通知。モードに応じたメッセージを表示 |

### 7-2. ShoppingAutoFillService.swift — 戻り値の変更

`fillShoppingList()` の戻り値を `Void` → `Int` に変更。買い物リストに追加した食材の件数を返すようにし、通知メッセージで使用する。

### 7-3. DashBordView.swift — 通知送信の追加

`autoFillShoppingList(for:)` 内の `fillShoppingList()` 完了後に `NotificationService.sendMealPlanReadyNotification()` を呼び出し。

```swift
let addedCount = try await ShoppingAutoFillService.fillShoppingList(...)
NotificationService.sendMealPlanReadyNotification(
    dishCount: dishes.count,
    shoppingItemCount: addedCount
)
```

### 7-4. MealPlanScheduler.swift — バックグラウンド通知の追加

`handleTask(_:modelContainer:)` の `task.setTaskCompleted(success: true)` 直前に `NotificationService.sendBackgroundMealPlanNotification(mode:)` を呼び出し。バックグラウンドで献立が自動生成された場合にもユーザーに通知する。

### 7-5. SmartChefApp.swift — 通知許可リクエストの追加

`init()` に `NotificationService.requestAuthorization()` を追加。初回起動時にシステムの通知許可ダイアログが表示される。

### 通知の内容

| シナリオ | タイトル | 本文例 |
|---|---|---|
| フォアグラウンド（買い物リスト追加あり） | 🍽️ 今日の献立が準備できました | 6品の献立とレシピを生成し、15件の食材を買い物リストに追加しました。 |
| フォアグラウンド（追加なし） | 🍽️ 今日の献立が準備できました | 6品の献立とレシピを生成しました。買い物リストに追加する食材はありませんでした。 |
| バックグラウンド（朝モード） | 🍽️ 献立を自動生成しました | 今日の朝食・昼食・夕食の献立が準備できました。アプリを開いて確認してください。 |
| バックグラウンド（夕モード） | 🍽️ 献立を自動生成しました | 今夜の夕食と明日の朝食・昼食の献立が準備できました。アプリを開いて確認してください。 |

---

## 現在のファイル構成（追加・変更分）

| ファイル | 状態 | 主な変更 |
|---|---|---|
| `NotificationService.swift` | 新規 | ローカル通知サービス（許可リクエスト・通知送信） |
| `ShoppingAutoFillService.swift` | 変更 | fillShoppingList() の戻り値を Int に変更 |
| `DashBordView.swift` | 変更 | autoFillShoppingList 完了時に通知送信を追加 |
| `MealPlanScheduler.swift` | 変更 | バックグラウンドタスク完了時に通知送信を追加 |
| `SmartChefApp.swift` | 変更 | init() に NotificationService.requestAuthorization() を追加 |

---

## Session 8: 開発支援機能の強化（モックデータランダム化 + テストコード拡充）

### 背景

開発用モックデータは固定データのみだったため、テストや動作確認で毎回同じ画面状態しか再現できなかった。また、テストコードは `ModelTests`、`DashBordLogicTests`、`DataMockServiceTests` の 3 ファイルのみで、アプリの主要機能に対するテストカバレッジが不足していた。

### 8-1. モックデータのランダム化 (DataMockService.swift)

`seedMockData()` を全面改修。固定データの代わりに、豊富なデータプールからランダムに選択・生成する仕組みに変更。

**ランダム化されたパラメータ:**

| データ種別 | ランダムレンジ | ランダム要素 |
|---|---|---|
| 在庫（StockItem） | 6〜12件 | 食材名・カテゴリ、期限の有無（75%/25%）、期限日数（-1〜14日）、数量（1〜5個） |
| 買い物リスト（ShoppingItem） | 2〜6件 | 食材名・カテゴリ、数量（1〜4個）、チェック状態（20%チェック済み） |
| 食事履歴（MealHistory） | 7〜14日分 | 料理名（食事種類別プール）、記録率（朝60%/昼70%/夕85%）、時間帯のばらつき |
| 食事計画（MealPlan） | 3日×3食=9件 | 料理名（食事種類別計画用プール） |

**データプール:** 在庫65種類以上、買い物リスト27種類、朝食/昼食/夕食メニューそれぞれ12〜24種類の料理名を用意。

**メソッドの公開:** 個々の生成メソッド（`generateRandomStockItems()` 等）を `static` で公開し、テストコードからも直接呼べるようにした。

### 8-2. テストコードの拡充

既存 3 ファイルの更新 + 新規 5 ファイルの追加で、合計 **8 テストファイル** に拡大。

#### 更新ファイル

| ファイル | 変更内容 |
|---|---|
| `DataMockServiceTests.swift` | ランダム化対応（レンジチェック、重複チェック、多様性検証、期限混在テスト、日付範囲テスト） |

#### 新規テストファイル

| ファイル | テスト対象 | テスト内容 |
|---|---|---|
| `AppSettingsTests.swift` | `AppSettings`, `MealPlanGenerationMode` | シングルトン性、デフォルト値、rawValue、displayName、scheduledHour |
| `MealPlanTests.swift` | `MealPlan`, `MealPlanStatus` | 初期化、ステータス変更、Codable、SwiftData CRUD、フィルタ取得 |
| `BarcodeCacheTests.swift` | `BarcodeCache`, `BarcodeCacheEntry` | シングルトン性、CRUD操作、リセット、Codable、全カテゴリ対応 |
| `ScannedItemTests.swift` | `ScannedItem` | デフォルト初期化、全プロパティ初期化、UUID一意性、Identifiable |
| `ShoppingItemTests.swift` | `ShoppingItem`, `ShoppingAutoFillService` | オプショナルプロパティ、SwiftData CRUD、自動追加フィルタ、`clearAutoAddedItems` |
| `StockItemSwiftDataTests.swift` | `StockItem`, `MealHistory` | SwiftData CRUD、カテゴリフィルタ、期限切れフィルタ、一括削除 |
| `IntegrationTests.swift` | アプリ統合テスト | 完了報告→在庫減算→履歴記録、献立変更、買い物リスト→在庫変換、ダッシュボードフィルタ |

### 現在のファイル構成（追加・変更分）

| ファイル | 状態 | 主な変更 |
|---|---|---|
| `DataMockService.swift` | 変更（全面改修） | ランダムデータ生成、データプール追加、メソッドの公開化 |
| `DataMockServiceTests.swift` | 変更 | ランダム化対応テストに更新 |
| `AppSettingsTests.swift` | 新規 | AppSettings・MealPlanGenerationMode テスト |
| `MealPlanTests.swift` | 新規 | MealPlan モデル・SwiftData テスト |
| `BarcodeCacheTests.swift` | 新規 | バーコードキャッシュ CRUD テスト |
| `ScannedItemTests.swift` | 新規 | ScannedItem モデルテスト |
| `ShoppingItemTests.swift` | 新規 | ShoppingItem・ShoppingAutoFillService テスト |
| `StockItemSwiftDataTests.swift` | 新規 | StockItem・MealHistory SwiftData テスト |
| `IntegrationTests.swift` | 新規 | アプリ統合テスト |

---

## Session 9: バグ修正 — 買い物リストの分量欄にレシピ本文が表示される

### 背景

買い物リスト画面の各行右端に表示される分量（`recipeAmount`）に、「500g」などの正常な分量ではなくレシピ本文や説明文がそのまま表示されるケースがあった。

### 原因

`IntelligenceService.mergeShoppingIngredients()` が返す `combinedAmount` フィールドに、AI が分量ではなくレシピの説明文等を返すことがある。`ShoppingAutoFillService` はこの値を無検証で `recipeAmount` に保存していたため、UI にそのまま表示されていた。

### 修正内容

**`ShoppingAutoFillService.swift` — 保存時の入力バリデーション追加:**

正常な分量（"500g"、"大さじ2 + 小さじ1" 等）は20文字以内に収まる。これを超える場合はレシピ本文等の誤った値とみなして `nil` に落とし、表示を `count + 個` フォールバックに戻す。

```swift
let validAmount: String? = {
    let s = item.combinedAmount.trimmingCharacters(in: .whitespaces)
    return (!s.isEmpty && s.count <= 20) ? s : nil
}()
```

**`ShoppingListView.swift` — 表示側の安全策 `.lineLimit(1)` 追加:**

バリデーションをすり抜けた長い文字列がレイアウトを崩さないよう、分量テキストに `.lineLimit(1)` を追加。

---

## Session 10: アプリ内レシピ生成完了通知 + ダッシュボードのレシピ生成状態表示

### 背景

Session 7 で実装したローカル通知はバックグラウンド・フォアグラウンド両対応だが、アプリを開いている最中にレシピ生成が完了したことをユーザーが気付けるアプリ内のビジュアル通知がなかった。また、ダッシュボードの献立セクションにはレシピの生成進捗が表示されておらず、レシピが生成中なのか完了済みなのかが分からなかった。

### ユーザーリクエスト

> 「AIによる献立のレシピ生成が終了したらアプリ内で通知してください．通知の方法は問いません．また，レシピが生成中の場合はダッシュボードの献立のセクションにそれを明記してください．」

### 10-1. DashBordView.swift — アプリ内トースト通知バナーの追加

**新規 State プロパティ:**

```swift
@State private var showRecipeReadyBanner = false
@State private var wasGeneratingRecipes = false
```

**`onChange(of: generatingDishes)` 内の遷移検知:**

`wasGeneratingRecipes`（前回 `generatingDishes` が非空だったか）を追跡し、`generatingDishes` が非空→空に遷移したタイミングでバナーを表示:

```swift
if wasGeneratingRecipes && generating.isEmpty {
    withAnimation(.spring(duration: 0.4)) {
        showRecipeReadyBanner = true
    }
    Task {
        try? await Task.sleep(for: .seconds(3.0))
        withAnimation(.easeOut(duration: 0.3)) {
            showRecipeReadyBanner = false
        }
    }
}
wasGeneratingRecipes = !generating.isEmpty
```

**バナー UI (`recipeReadyBanner`):**

- 緑のグラデーション背景 + 角丸 + ドロップシャドウ
- `checkmark.circle.fill` アイコン + 「レシピの生成が完了しました」テキスト
- 右端に `xmark.circle.fill` で手動非表示ボタン
- 3 秒後に自動フェードアウト
- `.overlay(alignment: .top)` でダッシュボードの上部に表示

### 10-2. DashBordView.swift — dailyMealPlanSection のセクション内インジケーター

献立が存在する場合（`plans` が非空）に、`IntelligenceService.shared.generatingDishes` が空でなければセクション先頭にレシピ生成中のインジケーターを表示:

```swift
if !IntelligenceService.shared.generatingDishes.isEmpty {
    HStack(spacing: 10) {
        ProgressView()
            .controlSize(.small)
        let generatingCount = IntelligenceService.shared.generatingDishes.count
        Text("\(generatingCount)品のレシピを生成中...")
            .font(.caption)
            .foregroundColor(.orange)
    }
    .padding(.vertical, 4)
}
```

### 10-3. MealPlanCard — 個別カードのレシピ生成状態表示

`MealPlanCard` に以下の computed property を追加:

```swift
private var dishes: [String]  // 献立名を「・」で分割したリスト
private var isAnyDishGenerating: Bool  // いずれかの料理が生成中か
private var allDishesHaveRecipe: Bool  // すべての料理のレシピがキャッシュ済みか
```

カードの献立名の下に状態を表示:

| 状態 | 表示 |
|---|---|
| いずれかの料理が生成中 | `ProgressView(.mini)` + 「レシピ生成中」（オレンジ色） |
| 全料理のレシピ生成完了 | `checkmark.circle.fill` + 「レシピ準備完了」（緑色） |
| どちらでもない（未生成かつ未開始） | 表示なし |

### 変更ファイル一覧

| ファイル | 状態 | 主な変更 |
|---|---|---|
| `DashBordView.swift` | 変更 | トースト通知バナー、セクション内生成インジケーター、MealPlanCard にレシピ状態表示を追加 |
| `DevelopmentLog.md` | 更新 | Session 10 を追記 |
| `CODEBASE_GUIDE.md` | 更新 | MealPlanCard の説明にレシピ生成状態表示を追記 |
| `IMPLEMENTATION_LOG.md` | 更新 | Task N+4 を追記 |
