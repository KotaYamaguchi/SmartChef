# Codebase Guide: SmartChef

## アプリ概要

SmartChef は、冷蔵庫の在庫・食事履歴・食事計画を一元管理する iOS アプリケーションです。
Apple の **Foundation Models**（オンデバイス LLM）を活用した栄養分析機能を備え、毎日の食生活をサポートします。

| 項目 | 内容 |
|---|---|
| 開発環境 | Xcode 16+ |
| 言語 | Swift 6.0 |
| UI フレームワーク | SwiftUI |
| データ永続化 | SwiftData |
| AI/ML | FoundationModels（Apple Intelligence） |

---

## ディレクトリ構成

```
SmartChef/                          ← プロジェクトルート
├── CODEBASE_GUIDE.md               ← 本ファイル（コードベース解説）
├── IMPLEMENTATION_LOG.md           ← 実装記録ログ
├── DevelopPlan.md                  ← 開発計画書
├── ProjectSummary.md               ← プロジェクト概要
│
├── SmartChef/                      ← アプリのソースコード
│   ├── SmartChefApp.swift          ← アプリエントリポイント・ModelContainer 定義
│   ├── ContentView.swift           ← ルートビュー（TabView）
│   │
│   ├── Models.swift                ← SwiftData モデル・列挙型の定義
│   ├── AppSettings.swift           ← アプリ設定管理（UserDefaults 永続化）
│   ├── DataMockService.swift       ← 開発用モックデータ投入サービス
│   ├── IntelligenceService.swift   ← AI 栄養分析サービス（Foundation Models）
│   ├── MealPlanScheduler.swift     ← BGTaskScheduler による自動献立生成スケジューラ
│   ├── ShoppingAutoFillService.swift ← レシピ→買い物リスト自動補充サービス
│   ├── NotificationService.swift   ← ローカル通知サービス（献立・買い物リスト生成完了通知）
│   │
│   ├── DashBordView.swift          ← ダッシュボード画面（タブ 1）
│   ├── StockItemView.swift         ← 冷蔵庫・在庫管理画面（タブ 2）
│   ├── ShoppingListView.swift      ← 買い物リスト画面（タブ 3）
│   ├── HistoryView.swift           ← 食事履歴画面（タブ 4）
│   ├── NutritionView.swift         ← AI 栄養分析画面（タブ 5）
│   ├── SettingsView.swift          ← アプリ設定画面（タブ 6）
│   ├── ScannerView.swift           ← カメラスキャン画面
│   ├── ScanResultView.swift        ← スキャン結果確認画面
│   │
│   └── Assets.xcassets/            ← アイコン・カラー等のアセット
│
├── SmartChef.xcodeproj/            ← Xcode プロジェクト設定
│
└── SmartChefTests/                 ← ユニットテスト
    ├── ModelTests.swift
    ├── DashBordLogicTests.swift
    ├── DataMockServiceTests.swift
    ├── AppSettingsTests.swift
    ├── MealPlanTests.swift
    ├── BarcodeCacheTests.swift
    ├── ScannedItemTests.swift
    ├── ShoppingItemTests.swift
    ├── StockItemSwiftDataTests.swift
    └── IntegrationTests.swift
```

---

## ファイル解説

### `SmartChefApp.swift`

アプリのエントリポイント（`@main`）。`ModelContainer` を手動生成し、`BGTaskScheduler` へのハンドラ登録・スケジュール登録・通知許可リクエストを `init()` で実行する。

**管理しているモデル:**

```swift
let schema = Schema([StockItem.self, ShoppingItem.self, MealHistory.self, MealPlan.self])
```

**init() で実行される処理:**

| 処理 | 説明 |
|---|---|
| `MealPlanScheduler.registerHandler(modelContainer:)` | バックグラウンドタスクのハンドラを登録 |
| `MealPlanScheduler.scheduleNextGeneration()` | 次回の自動献立生成をスケジュール |
| `NotificationService.requestAuthorization()` | ローカル通知の許可をリクエスト |

---

### `ContentView.swift`

ルートビュー。`TabView` で 5 つのタブを管理する。

| タブ番号 | View | ラベル | アイコン |
|---|---|---|---|
| 1 | `DashBordView` | ダッシュボード | `chart.bar.fill` |
| 2 | `ItemStockView` | 冷蔵庫 | `refrigerator` |
| 3 | `ShoppingListView` | 買い物リスト | `cart.fill` |
| 4 | `HistoryView` | 食事履歴 | `fork.knife` |
| 5 | `NutritionView` | 栄養分析 | `heart.text.clipboard` |

---

### `Models.swift`

アプリで使用するすべてのデータモデルと列挙型を定義する。

#### 列挙型

| 型名 | 用途 | ケース数 |
|---|---|---|
| `Category` | 食材のカテゴリ | 10種類（野菜・肉類・魚介類 など） |
| `MealType` | 食事の種類 | 3種類（朝食・昼食・夕食） |
| `MealPlanStatus` | 食事計画のステータス | 3種類（予定・完了・変更済） |

#### SwiftData モデル（@Model）

| クラス名 | 主なプロパティ | 用途 |
|---|---|---|
| `StockItem` | `name`, `category`, `deadline?`, `count` | 冷蔵庫の在庫食材 |
| `ShoppingItem` | `name`, `category`, `count`, `isSelected` | 買い物リストのアイテム |
| `MealHistory` | `date`, `menuName`, `mealType` | 過去の食事記録 |
| `MealPlan` | `date`, `mealType`, `menuName`, `status` | 今後の食事計画 |

#### 非永続モデル（struct / class）

| 型名 | 種別 | 用途 |
|---|---|---|
| `ScannedItem` | `struct` | スキャン結果の確認画面用ステージングモデル。SwiftData には保存されない |
| `BarcodeCache` | `final class`（シングルトン） | バーコード → 商品名・カテゴリのマッピングを `UserDefaults` に永続化するローカルキャッシュ |
| `BarcodeCacheEntry` | `struct` (Codable) | `BarcodeCache` の値型。`name` と `category` を保持 |

---

### `AppSettings.swift`

アプリ全体の設定を `UserDefaults` に永続化する `@Observable` シングルトン。SwiftUI の `@Observable` macro により、プロパティ変更時に参照しているビューが自動的に再描画される。

**設定プロパティ一覧:**

| プロパティ | 型 | デフォルト | 用途 |
|---|---|---|---|
| `generationMode` | `MealPlanGenerationMode` | `.morning` | 献立の自動生成タイミング（朝5時 / 夕5時） |
| `servingsCount` | `Int` | `2` | 献立・レシピの生成人数（1〜8人） |
| `expiryWarningDays` | `Int` | `7` | 期限警告表示の閾値日数（ダッシュボード「今日使うべき食材」） |
| `showExpiredItems` | `Bool` | `true` | 在庫一覧に期限切れアイテムを表示するか |
| `autoDeleteMatchedShoppingItems` | `Bool` | `true` | レシートスキャン保存時に買い物リスト照合アイテムを自動削除するか |

**実装上の注意:**
- `computed property + UserDefaults 直接 get/set` では `@Observable` に変更通知が届かず SwiftUI が再描画されない
- ストアドプロパティ + `didSet` で UserDefaults に保存するパターンを採用
- `SettingsView` では `Binding(get:set:)` でラップして `@Observable` 非対応の SwiftUI コントロールに渡す

---

### `DataMockService.swift`

開発・プレビュー用のモックデータを SwiftData に一括投入する静的サービス。
ダッシュボードの「サンプルデータを投入」ボタンから呼び出される。
**ランダム化対応:** 豊富なデータプールからランダムに選択・生成し、毎回異なるデータセットが投入される。

**`seedMockData(context:)` が投入するデータ:**

| 種類 | 件数 | ランダム要素 |
|---|---|---|
| `StockItem` | 6〜12 件 | 食材名・カテゴリ、期限有無（75%/25%）、期限日数（-1〜14日）、数量（1〜5） |
| `ShoppingItem` | 2〜6 件 | 食材名・カテゴリ、数量（1〜4）、チェック状態（20%チェック済み） |
| `MealHistory` | 7〜14 日分 | 料理名（食事種類別プール）、記録率（朝60%/昼70%/夕85%）、時間帯のばらつき |
| `MealPlan` | 9 件 | 料理名（食事種類別計画用プール） |

**公開メソッド:**

| 関数名 | 用途 |
|---|---|
| `generateRandomStockItems()` | ランダムな在庫データを生成（6〜12件） |
| `generateRandomShoppingItems()` | ランダムな買い物リストを生成（2〜6件） |
| `generateRandomMealHistories()` | ランダムな食事履歴を生成（7〜14日分） |
| `generateRandomMealPlans()` | ランダムな食事計画を生成（3日×3食） |
| `date(daysAgo:hour:)` | N 日前の指定時刻の `Date` を生成（履歴用） |
| `planDate(daysFromNow:hour:)` | N 日後の指定時刻の `Date` を生成（計画用） |

---

### `IntelligenceService.swift`

Apple Intelligence（Foundation Models）を使用して栄養分析・献立生成・レシピ生成・食材マージを行うサービス。

**主要コンポーネント:**

| 要素 | 説明 |
|---|---|
| `NutritionAnalysis` (@Generable) | AI の出力を受け取る構造化出力型。`summary`, `missingNutrients`, `recommendedFoods`, `advice` を持つ。 |
| `IntelligenceService` (@Observable) | `LanguageModelSession` を使って非同期分析を実行するシングルトン。 |
| `isModelAvailable` | `SystemLanguageModel.default.availability` が `.available` かどうかを確認する。 |
| `analyzeMealHistory(_:)` | 直近 42 食分の履歴をテキスト化してプロンプトに渡し、`NutritionAnalysis` を返す。 |
| `generateDailyMealPlan(stockItems:recentHistory:)` | 在庫・履歴をもとに 1 日分の献立を生成 |
| `generateEveningMealPlan(stockItems:recentHistory:)` | 夕方モード用の献立（今夜+明日分）を生成 |
| `generateRecipe(for:)` | 指定料理のレシピを生成 |
| `prefetchRecipes(for:)` | 複数料理のレシピを並行プリフェッチ |
| `mergeShoppingIngredients(_:)` | 複数料理の食材リストを AI で統合・重複排除 |
| `analyzeReceiptItems(_:)` | Vision OCR テキストから食材リストを AI 解析 |

**レシピキャッシュ状態:**

| プロパティ | 型 | 説明 |
|---|---|
| `cachedRecipes` | `[String: RecipeDetail]` | 生成済みレシピのキャッシュ |
| `generatingDishes` | `Set<String>` | 現在生成中の料理名 |
| `recipeErrors` | `[String: String]` | 生成失敗した料理のエラー情報 |

---

### `MealPlanScheduler.swift`

`BGTaskScheduler` を使った自動献立生成スケジューラ。設定モード（朝5時/夕5時）に合わせて `BGAppRefreshTask` をスケジュールし、バックグラウンドで献立を自動生成する。

**主要メソッド:**

| メソッド | 説明 |
|---|---|
| `registerHandler(modelContainer:)` | アプリ起動時に `BGTaskScheduler` にハンドラを登録 |
| `scheduleNextGeneration()` | 現在のモードに合わせて次回スケジュールを登録 |
| `handleTask(_:modelContainer:)` | バックグラウンドタスク実行: 献立生成 → レシピプリフェッチ → 通知送信 |

**Xcode 設定要件:**
- Signing & Capabilities → "Background Modes" → "Background fetch" にチェック
- Info.plist に `BGTaskSchedulerPermittedIdentifiers` = `com.kotayamaguchi.SmartChef.dailyMealPlan`

---

### `ShoppingAutoFillService.swift`

レシピの食材リストから買い物リストを自動補充するサービス。

**`fillShoppingList()` の処理フロー:**
1. MealPlan から料理名 → 食事タイプのマッピングを構築
2. 全レシピから食材リストを収集
3. `IntelligenceService.mergeShoppingIngredients()` で AI マージ
4. 在庫名・既存買い物リスト名と照合し、不足分だけ `ShoppingItem` として insert
5. 追加件数（`Int`）を返す（通知メッセージに使用）

**`clearAutoAddedItems(from:context:)`:** `sourceMenuName != nil` のアイテムを全削除（再生成時のクリア用）

---

### `NotificationService.swift`

`UNUserNotificationCenter` を使ったローカル通知サービス。献立・レシピ・買い物リストの自動生成完了時にユーザーに通知を送信する。

**主要メソッド:**

| メソッド | 説明 |
|---|---|
| `requestAuthorization()` | アプリ起動時に通知許可をリクエスト（.alert, .sound, .badge） |
| `sendMealPlanReadyNotification(dishCount:shoppingItemCount:)` | フォアグラウンドでの生成完了通知。品目数・追加件数をメッセージに含む |
| `sendBackgroundMealPlanNotification(mode:)` | バックグラウンドタスクでの自動生成完了通知 |

**通知シナリオ:**

| シナリオ | タイトル | 本文例 |
|---|---|---|
| フォアグラウンド（追加あり） | 🍽️ 今日の献立が準備できました | 6品の献立とレシピを生成し、15件の食材を買い物リストに追加しました。 |
| フォアグラウンド（追加なし） | 🍽️ 今日の献立が準備できました | 6品の献立とレシピを生成しました。買い物リストに追加する食材はありませんでした。 |
| バックグラウンド（朝モード） | 🍽️ 献立を自動生成しました | 今日の朝食・昼食・夕食の献立が準備できました。アプリを開いて確認してください。 |
| バックグラウンド（夕モード） | 🍽️ 献立を自動生成しました | 今夜の夕食と明日の朝食・昼食の献立が準備できました。アプリを開いて確認してください。 |

---

### `DashBordView.swift`

アプリの中心となるダッシュボード画面。`NavigationStack` + `List` 構成で 4 つのセクションを持つ。

**セクション構成:**

| セクション | 変数名 | 内容 |
|---|---|---|
| 今日の献立 | `dailyMealPlanSection` | 当日の食事計画を朝・昼・晩の順に表示 |
| 今日使うべき食材 | `expirySection` | `AppSettings.shared.expiryWarningDays` 日以内に期限が切れる食材を警告表示 |
| 最近の食事 | `recentMealsSection` | 食事履歴の直近 5 件を表示 |

**ファイル内で定義されているビューコンポーネント:**

| 構造体名 | 役割 |
|---|---|
| `DashBordView` | メインダッシュボード |
| `MealPlanCard` | 食事計画 1 件のカード表示 |
| `MealPlanStatusBadge` | 予定/完了/変更済 のカプセル型バッジ |
| `MealPlanDetailView` | 食事計画の詳細・操作画面（NavigationLink 遷移先） |
| `StockUpdateSheet` | 完了報告時の在庫連動シート |
| `StockUsageRow` | 在庫 1 件の使用個数コントロール行 |
| `ChangeMenuSheet` | 内容変更報告シート |
| `EditMenuSheet` | 献立編集シート |
| `ExpiryItemRow` | 期限が迫った食材の表示行 |
| `MealTypeBadge` | 朝食/昼食/夕食 のカプセル型バッジ |

---

### `StockItemView.swift`

冷蔵庫の在庫管理画面（`struct ItemStockView`）。
注意: ファイル名は `StockItemView.swift`、構造体名は `ItemStockView`。

**主な機能:**
- 在庫一覧のカテゴリ別グループ表示（カラードット付き）
- スワイプで削除
- 右上の `camera.badge.plus` ボタンから `ScannerView` をフルスクリーンで起動
- 空状態表示（「冷蔵庫は空です」 + スキャン誘導テキスト）
- `AppSettings.shared.showExpiredItems = false` のとき、期限切れアイテムをリストから除外（`filteredItems` computed property）

**削除された機能（旧）:**
- ~~「＋」ボタンからの手動追加シート（名前・カテゴリ・個数・賞味期限を入力）~~
  → `ScanResultView` 内の `ManualScanItemSheet` に移行

**追加されたサブビュー:**
- `StockItemRow`: 名前・賞味期限（残日数テキスト付き）・個数表示行

---

### `ShoppingListView.swift`

買い物リストの管理画面。

**主な機能:**
- リスト表示・チェックボックスで購入済みマーク
- 「＋」ボタンから品目追加
- チェック済みアイテムが存在する場合に「チェック済みを削除」ボタンとスキャン誘導バナーを表示

**削除された機能（旧）:**
- ~~「購入完了」ボタン: チェック済みアイテムを `StockItem` に変換して冷蔵庫に移動~~
  → `ScannerView` のレシートスキャンフローに移行。`ScanResultView` 保存時に買い物リストとの照合・自動削除が行われる

---

### `ScannerView.swift` (**新規**)

カメラを使った食材スキャン画面。2 つのモードを `Picker` で切り替える。

**`ScanMode` 列挙型:**

| ケース | rawValue | 動作 |
|---|---|---|
| `.receipt` | `"レシート"` | 撮影ボタンで写真を撮り Vision OCR → AI 解析 |
| `.barcode` | `"バーコード"` | リアルタイムバーコード検出 → 即時在庫追加 |

**レシートモードの流れ:**
1. カメラプレビュー表示（`CameraPreviewView`）
2. 撮影ボタンタップ → `CameraController.capturePhoto()` 呼び出し
3. `VNRecognizeTextRequest` で日本語 OCR（`recognitionLanguages: ["ja-JP", "en-US"]`）
4. `IntelligenceService.analyzeReceiptItems()` で AI 解析（Apple Intelligence 必須）
5. 結果を `[ScannedItem]` に変換 → `ScanResultView` へ NavigationStack でプッシュ
6. Apple Intelligence 非対応時はエラーアラート → 空の `ScanResultView` で手動追加を促す

**バーコードモードの流れ:**
1. `AVCaptureMetadataOutput` でリアルタイムバーコード検出（EAN-8/13, UPC-E, Code128 等）
2. `BarcodeCache.shared.get(barcode)` でローカルキャッシュを検索
   - **キャッシュヒット**: `StockItem` に即時追加 → 「追加済み」トースト表示
   - **キャッシュミス**: `BarcodeNameInputSheet` で商品名・カテゴリを入力 → キャッシュに保存 → 追加
3. 同一バーコードのクールダウン: 2.5 秒間は重複検出を無視
4. 「完了」ボタンでスキャナーを閉じる

**主要コンポーネント:**

| 構造体/クラス | 説明 |
|---|---|
| `CameraController` | `NSObject` サブクラス。`AVCaptureSession` を管理し Photo・Metadata 両出力を持つ |
| `CameraPreviewView` | `UIViewRepresentable` ラッパー。`AVCaptureVideoPreviewLayer` を `UIView.layerClass` で利用 |
| `BarcodeNameInputSheet` | バーコード初回スキャン時の商品名・カテゴリ入力シート |

---

### `ScanResultView.swift` (**新規**)

スキャン結果の確認・編集・一括登録画面。

**表示内容:**
1. **認識件数ヘッダー**: 認識品目数または「認識されなかった」警告
2. **食材一覧（編集可能）**: `ScannedItemEditRow` で各アイテムを折りたたみ編集
3. **手動追加ボタン**: `ManualScanItemSheet` を開き `ScannedItem` をリストに追加
4. **買い物リストとの照合セクション**: 名前が部分一致する `ShoppingItem` を表示（保存時に自動削除）

**`ScannedItemEditRow`:**
- 折りたたみ式（タップで展開）
- 展開時: 食材名 TextField / カテゴリ Picker / 個数 Stepper / 賞味期限 Toggle + DatePicker

**保存処理（`saveAllItems()`）:**
1. 各 `ScannedItem` → `StockItem` を生成して `modelContext.insert()`
2. `AppSettings.shared.autoDeleteMatchedShoppingItems` が `true` のとき、照合済みの `ShoppingItem` を `modelContext.delete()` で削除
3. 完了アニメーション（`checkmark.circle.fill` オーバーレイ）を 1.2 秒表示後に画面を閉じる

**`ManualScanItemSheet`:**
- 食材名 / カテゴリ / 個数 / 賞味期限（任意）を入力
- 「リストに追加」で `ScannedItem` を生成してコールバック経由でリストに追加

---

### `SettingsView.swift`

アプリ設定画面。`AppSettings.shared` の各プロパティを編集するフォーム。

**セクション構成:**

| セクション | 設定内容 |
|---|---|
| 食事設定 | `servingsCount` — Stepper (1〜8) で何人前かを設定 |
| 在庫管理 | `expiryWarningDays` — Picker (3/5/7/10/14日) / `showExpiredItems` — Toggle |
| スキャン設定 | `autoDeleteMatchedShoppingItems` — Toggle |
| 献立の自動生成タイミング | `generationMode` — `ModeSelectionRow` による選択（既存機能） |
| AI機能 | `Apple Intelligence` 利用可否表示（既存機能） |
| データ管理 | バーコードキャッシュリセット（`BarcodeCache.shared.reset()`） / 全データ削除 |
| このアプリについて | バージョン・ビルド番号（`Bundle.main.infoDictionary` から取得） |
| 開発用ツール | サンプルデータ投入（既存機能） |

**`@Observable` との連携:**
`AppSettings` は `@Observable` だが、SwiftUI の `Stepper` / `Toggle` / `Picker` は `Binding` を要求するため、
`Binding(get:set:)` でラップして各コントロールに渡す。

**データ管理の実装:**
- バーコードキャッシュリセット: `BarcodeCache.shared.reset()` → UserDefaults のキーを削除
- 全データ削除: `modelContext.delete(model:)` で SwiftData の全エンティティを削除

---

### `HistoryView.swift`

食事履歴の一覧・追加画面。

**主な機能:**
- 日付ごとにグループ化した履歴リスト（新着順）
- スワイプで削除
- 「＋」ボタンから手動追加（`AddMealHistoryView` シート）
- 食事タイプ別カラーバッジ表示

---

### `NutritionView.swift`

AI による栄養分析画面。

**主な機能:**
- 「分析を開始」ボタンで `IntelligenceService.analyzeMealHistory(_:)` を非同期実行
- 分析結果を 4 つのカードで表示（総評・不足栄養素・おすすめ食材・改善アドバイス）
- 「買い物リストに追加」: おすすめ食材のうち在庫にないものを `ShoppingItem` として追加
- Apple Intelligence 非対応端末ではエラーメッセージを表示

**カスタムレイアウト:**
- `TagLayout`: カスタム `Layout` 実装によるフロー折り返しタグ表示
- `NutrientTagsView`: `TagLayout` を使った栄養素タグの描画

---

## アプリの機能一覧

### 機能 1: 冷蔵庫の在庫管理（在庫自動入力機能）

- **レシートスキャン（AI OCR）**: カメラで撮影 → Vision OCR → Apple Intelligence 解析 → カテゴリ・推定賞味期限付きで一覧表示 → 編集後に一括登録
- **バーコードスキャン**: リアルタイム検出 → ローカルキャッシュ照合 → 即時在庫追加（連続スキャン対応）
- **手動追加（スキャン親和型）**: `ScanResultView` 内の `ManualScanItemSheet` から追加し、他のスキャン結果と合わせて一括登録
- カテゴリ別グループ表示（カラードット付き）
- スワイプ削除

### 機能 2: 買い物リスト管理

- 品目の追加・削除・チェック（タップでチェックトグル）
- チェック済みが存在する場合: スキャン誘導バナー表示、「チェック済みを削除」ボタン表示
- レシートスキャン保存時: 買い物リストの合致アイテムを自動削除（照合ロジック: 名前の部分一致）

### 機能 3: 食事計画の表示・管理

ダッシュボードの **「今日の献立」** セクションで当日の朝・昼・晩の計画を確認できる。

各カードをタップすると詳細画面（`MealPlanDetailView`）に遷移し、以下の操作が可能:

| 操作 | 動作 |
|---|---|
| 完了報告 | 在庫連動シート（`StockUpdateSheet`）を開く → 使用食材を記録 → 在庫を減算 → `MealHistory` に記録 |
| 内容変更報告 | 実際に食べたものに献立名を変更して `status = .changed` に更新 |
| 献立を編集 | 献立名を修正 |
| 計画を削除 | 確認ダイアログ → 削除 |

### 機能 4: 完了報告時の在庫連動

「完了報告」をタップすると `StockUpdateSheet` がシート表示される。

- 冷蔵庫の在庫がカテゴリ別に一覧表示される
- 各食材に `−` / `+` ボタンで使用個数（0〜在庫数の範囲）を入力
- 個数入力後に「在庫 N 個 → 残 M 個」をリアルタイムプレビュー
- 「完了報告する」で在庫を減算し、食事計画を完了にして食事履歴に記録
- 「キャンセル」で変更なしに閉じる

### 機能 5: 食事履歴の記録

- 過去の食事を日付ごとにグループ表示
- 手動での食事追加（メニュー名・食事種類・日時）
- 完了報告時には自動で履歴が追加される

### 機能 6: AI 栄養分析（Apple Intelligence 必須）

- 直近最大 42 食分の食事履歴を Apple Intelligence で分析
- 出力: 総評 / 不足栄養素リスト / おすすめ食材リスト / 改善アドバイス
- おすすめ食材を 1 タップで買い物リストに追加

### 機能 7: 献立・買い物リスト自動生成

- 設定したタイミング（朝5時 / 夕5時）で `BGTaskScheduler` により献立を自動生成
- 献立生成後、各料理のレシピを並行プリフェッチ
- レシピ完了後、不足食材を AI マージして買い物リストに自動追加
- 生成完了時にローカル通知を送信（フォアグラウンド・バックグラウンド両対応）

---

## データフロー

```
[カメラ / ScannerView]
    ├── レシートスキャン: OCR（Vision）→ AI解析（Apple Intelligence）→ [ScanResultView]
    │       ↓「冷蔵庫に追加」
    │       ↓ 買い物リスト照合 → 合致 ShoppingItem を自動削除
    └── バーコードスキャン: BarcodeCache → 即時追加（トースト）
             ↓
[冷蔵庫（StockItem）]
        ↓ ダッシュボードで期限警告
        ↓ 完了報告時に在庫減算
[食事計画（MealPlan）] ← AI 自動生成（BGTaskScheduler / 手動トリガー）
        ↓ レシピプリフェッチ
[レシピキャッシュ（IntelligenceService）]
        ↓ 全レシピ完了
[買い物リスト自動補充（ShoppingAutoFillService）]
        ↓ AI マージ → 不足食材を追加
        ↓ 完了時にローカル通知（NotificationService）
[食事計画（MealPlan）]
        ↓「完了報告」
[食事履歴（MealHistory）]
        ↓ AI 分析の入力データ
[栄養分析（NutritionAnalysis）]
        ↓「買い物リストに追加」
[買い物リスト（ShoppingItem）] ← ループ
        ↓（チェック後）
[カメラ / ScannerView] ← レシートスキャンで在庫に自動反映
```

---

## カラーガイド

| 用途 | 色 |
|---|---|
| 朝食 | `.orange` |
| 昼食 | `.green` |
| 夕食 | `.blue` / `.indigo`（計画カードは `.indigo`） |
| 期限切れ（0 日以内） | `.red` |
| 期限警告（1〜3 日） | `.orange` |
| 期限注意（4〜7 日） | `.yellow` |
| 計画ステータス: 予定 | `.blue` |
| 計画ステータス: 完了 | `.green` |
| 計画ステータス: 変更済 | `.orange` |
| AI 機能（栄養分析） | `.blue` |
| 在庫連動 | `.teal` |
