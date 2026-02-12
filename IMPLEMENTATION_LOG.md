# Implementation Log: SmartChef

## 概要

このドキュメントは、ダッシュボードの食事計画機能・在庫連動機能の実装記録です。

---

## Task 1: `dailyMealPlanSection` の実装

### 目的

`DashBordView` 内に 1 日の食事計画（朝・昼・晩）を表示・管理する `dailyMealPlanSection` を作成する。

---

### 1-1. データモデルの追加 — `Models.swift`

#### `MealPlanStatus` (enum)

| 値 | rawValue |
|---|---|
| `.planned` | `"予定"` |
| `.completed` | `"完了"` |
| `.changed` | `"変更済"` |

#### `MealPlan` (@Model)

| プロパティ | 型 | 説明 |
|---|---|---|
| `id` | `UUID` | 一意識別子 |
| `date` | `Date` | 食事の予定日時（時刻で朝昼晩を区別） |
| `mealType` | `MealType` | 朝食 / 昼食 / 夕食 |
| `menuName` | `String` | 献立名 |
| `status` | `MealPlanStatus` | 予定 / 完了 / 変更済（デフォルト: `.planned`） |

---

### 1-2. ModelContainer の更新 — `SmartChefApp.swift`

```swift
// 変更前
.modelContainer(for: [StockItem.self, ShoppingItem.self, MealHistory.self])

// 変更後
.modelContainer(for: [StockItem.self, ShoppingItem.self, MealHistory.self, MealPlan.self])
```

---

### 1-3. モックデータの追加 — `DataMockService.swift`

`seedMockData(context:)` に以下を追加:

- `try? context.delete(model: MealPlan.self)` — 既存計画の全削除
- 今日・翌日・翌々日の 3 日分 × 3 食 = 計 9 件のモックデータ
- ヘルパー関数 `planDate(daysFromNow:hour:)` — 未来日付を生成

```swift
MealPlan(date: planDate(daysFromNow: 0, hour: 8),  mealType: .breakfast, menuName: "トースト・スクランブルエッグ")
MealPlan(date: planDate(daysFromNow: 0, hour: 12), mealType: .lunch,     menuName: "鶏もも肉の照り焼き定食")
MealPlan(date: planDate(daysFromNow: 0, hour: 19), mealType: .dinner,    menuName: "豆腐とほうれん草の味噌汁・白米")
// 翌日・翌々日 各3食…
```

---

### 1-4. `DashBordView.swift` の変更点

#### 追加した `@Query`

```swift
@Query(sort: \MealPlan.date) private var mealPlans: [MealPlan]
```

#### `dailyMealPlanSection` (DashBordView.swift:50)

当日の計画を `todayMealPlans()` でフィルタリングし、`MealPlanCard` を `ForEach` で縦並びに表示。
計画がない場合はプレースホルダー表示。各カードは `NavigationLink` で `MealPlanDetailView` へ遷移。

#### `todayMealPlans()` (DashBordView.swift:137)

```swift
private func todayMealPlans() -> [MealPlan] {
    let today    = Calendar.current.startOfDay(for: Date())
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
    return mealPlans
        .filter { $0.date >= today && $0.date < tomorrow }
        .sorted { $0.date < $1.date }
}
```

---

### 1-5. 追加したビューコンポーネント

#### `MealPlanCard` (DashBordView.swift:157)

食事計画 1 件を表示するカード。

| 要素 | 内容 |
|---|---|
| 左側アイコン | 食事タイプ別の SF Symbol をカラー付き丸背景で表示 |
| 上段テキスト | `"2/11 朝食"` 形式の日付ラベル |
| 下段テキスト | 献立名（太字・最大 2 行） |
| 右側バッジ | `MealPlanStatusBadge`（予定/完了/変更済） |

食事タイプ別のカラー・アイコン:

| mealType | color | icon |
|---|---|---|
| `.breakfast` | `.orange` | `sunrise.fill` |
| `.lunch` | `.green` | `sun.max.fill` |
| `.dinner` | `.indigo` | `moon.stars.fill` |

#### `MealPlanStatusBadge` (DashBordView.swift:214)

カプセル型バッジ。`MealPlanStatus` に応じて色が変わる。

| status | color |
|---|---|
| `.planned` | `.blue` |
| `.completed` | `.green` |
| `.changed` | `.orange` |

#### `MealPlanDetailView` (DashBordView.swift:239)

`NavigationLink` の遷移先。`List` + 4 つの `Section` で構成。

| Section | 内容 |
|---|---|
| 計画内容 | 日付・食事種類・献立名・ステータスを `LabeledContent` で表示 |
| 報告 | 完了報告・内容変更報告ボタン（完了済みは disabled） |
| 管理 | 献立編集・削除ボタン |

モーダル・ダイアログ:
- `.sheet(isPresented: $showCompletionSheet)` → `StockUpdateSheet`
- `.sheet(isPresented: $showChangeSheet)` → `ChangeMenuSheet`
- `.sheet(isPresented: $showEditSheet)` → `EditMenuSheet`
- `.confirmationDialog(...)` → 削除確認

#### `ChangeMenuSheet` (DashBordView.swift:399)

変更前の献立を参照しながら実際に食べたものを入力するシート。
「報告」タップで `reportChange(to:)` を呼び出し、`plan.menuName` と `plan.status = .changed` を更新して保存。

#### `EditMenuSheet` (DashBordView.swift:457)

献立名のみを編集するシート。
「保存」タップで `updateMenuName(to:)` を呼び出し、`plan.menuName` を更新して保存。

---

## Task 2: 完了報告時の在庫連動機能の実装

### 目的

完了報告ボタンタップ時に `.sheet` で冷蔵庫の在庫一覧を表示し、使用した食材の個数を入力・在庫を減算できるようにする。

---

### 2-1. `MealPlanDetailView` の変更点

#### 追加した `@State`

```swift
@State private var showCompletionSheet = false
```

#### 完了報告ボタンの変更

```swift
// 変更前: 直接実行
Button { markAsCompleted() }

// 変更後: シートを開く
Button { showCompletionSheet = true }
```

#### 追加した `.sheet`

```swift
.sheet(isPresented: $showCompletionSheet) {
    StockUpdateSheet(plan: plan) {
        markAsCompleted()   // 在庫更新完了後に呼ばれる
    }
}
```

#### `markAsCompleted()` の更新

```swift
// 変更前
plan.status = .completed
// TODO コメントのみ

// 変更後
plan.status = .completed
let entry = MealHistory(date: plan.date, menuName: plan.menuName, mealType: plan.mealType)
modelContext.insert(entry)  // 食事履歴に記録
try? modelContext.save()
```

#### 削除した要素

- 「在庫連動」Section（UI はシートに統合）
- `updateStock(usedIngredients:)` スタブ関数

---

### 2-2. `StockUpdateSheet` (DashBordView.swift:470)

完了報告・在庫連動を担うシート。`.presentationDetents([.large])` で表示。

#### データ取得

```swift
@Query(sort: \StockItem.name) private var stockItems: [StockItem]
```

#### 状態管理

```swift
@State private var usageCounts: [UUID: Int] = [:]
// キー: StockItem.id, 値: 今回使う個数（0 = 変更なし）
```

#### 表示ロジック

- `availableCategories`: `count > 0` の食材が存在するカテゴリのみ `Category.allCases` の定義順で返す
- `items(in:)`: 指定カテゴリの `count > 0` の食材を返す
- 在庫が空の場合はプレースホルダー表示

#### UI 構成

| Section | 内容 |
|---|---|
| 「完了報告する献立」 | 献立名・日付・食事タイプを確認用に表示 |
| カテゴリ別 Section × N | `StockUsageRow` を `ForEach` で表示 |

#### ツールバー

| ボタン | 動作 |
|---|---|
| キャンセル | 在庫・計画を変更せずに `dismiss()` |
| 完了報告する | `applyStockChanges()` → `onConfirm()` → `dismiss()` |

#### `applyStockChanges()`

```swift
private func applyStockChanges() {
    for (id, usedCount) in usageCounts where usedCount > 0 {
        guard let item = stockItems.first(where: { $0.id == id }) else { continue }
        item.count = max(0, item.count - usedCount)
    }
    try? modelContext.save()
}
```

---

### 2-3. `StockUsageRow` (DashBordView.swift:584)

在庫 1 件の使用個数コントロール行。

#### レイアウト

```
[ 食材名（太字）                ] [ − ] [ N ] [ + ]
[ 在庫 N 個 → 残 M 個（変化時）]
[ 期限ラベル（期限設定時）      ]
```

#### ±ボタンの制約

| 操作 | 条件 |
|---|---|
| − ボタン押下 | `usageCount > 0` のときのみ減算 |
| + ボタン押下 | `usageCount < item.count` のときのみ加算 |

#### 残数の色分け

| 状態 | 色 |
|---|---|
| `remaining == 0`（使い切り） | `.red` |
| `remaining > 0`（一部使用） | `.orange` |

---

## 操作フロー全体図

```
ダッシュボード（MealPlanCard）
  ↓ タップ（NavigationLink）
MealPlanDetailView
  │
  ├─ 完了報告ボタン → showCompletionSheet = true
  │       ↓
  │   StockUpdateSheet（.sheet）
  │     - 在庫一覧をカテゴリ別に表示
  │     - ±ボタンで使用個数を入力
  │     ↓「完了報告する」タップ
  │     applyStockChanges()
  │       → StockItem.count を減算・保存
  │     onConfirm() = markAsCompleted()
  │       → plan.status = .completed
  │       → MealHistory に記録追加・保存
  │     dismiss()
  │
  ├─ 内容変更報告 → ChangeMenuSheet
  │     → plan.menuName 更新 / plan.status = .changed
  │
  ├─ 献立を編集 → EditMenuSheet
  │     → plan.menuName 更新
  │
  └─ この計画を削除 → confirmationDialog → deletePlan()
```

---

## 今後の TODO

| 項目 | 詳細 |
|---|---|
| 内容変更報告時の在庫連動 | `ChangeMenuSheet` にも `StockUpdateSheet` に相当するフローを追加 |
| 使用済み食材の自動提案 | 献立名からよく使う食材を推測して `StockUpdateSheet` の初期値に反映 |
| 食材個数が 0 になった場合の処理 | 在庫から削除するか 0 のまま残すかをユーザーが選択できるようにする |
| 食事計画の新規追加 UI | ダッシュボードから新しい計画を追加するボタンの実装 |
| 翌日以降の計画表示 | `dailyMealPlanSection` を複数日対応に拡張（日付セレクタなど） |

---

## Task N: 在庫自動入力機能（スキャン・スロット）の実装

### 実装日: 2026-02-12

### 概要

買い物後の食材入力を「撮るだけ・かざすだけ」で完結させる在庫自動入力機能を実装した。
既存の手動追加フロー（冷蔵庫タブの＋ボタン）と「購入完了」フロー（買い物リストからの在庫移動）を廃止し、レシートスキャン・バーコードスキャンを中心とした新しいUXに刷新した。

---

### N-1. データモデルの追加 — `Models.swift`

#### `ScannedItem` (struct, 非永続)

スキャン結果の確認画面（`ScanResultView`）でステージングに使う一時モデル。SwiftData には保存されない。

| プロパティ | 型 | 説明 |
|---|---|---|
| `id` | `UUID` | 一意識別子 |
| `name` | `String` | 食材名（AI が正規化） |
| `category` | `Category` | カテゴリ（AI が推定） |
| `count` | `Int` | 個数（デフォルト: 1） |
| `deadline` | `Date?` | 推定賞味期限 |
| `hasDeadline` | `Bool` | 賞味期限を表示・保存するかどうか |

#### `BarcodeCache` (final class, シングルトン)

バーコード（JANコード等）と商品情報のペアを UserDefaults に永続化するローカル学習キャッシュ。

| 要素 | 説明 |
|---|---|
| `shared` | シングルトンインスタンス |
| `get(_ barcode: String)` | バーコード文字列から `BarcodeCacheEntry?` を取得 |
| `set(_ barcode:, name:, category:)` | 新しいエントリを保存（既存は上書き） |

#### `BarcodeCacheEntry` (struct, Codable)

| プロパティ | 型 |
|---|---|
| `name` | `String` |
| `category` | `Category` |

---

### N-2. AI 解析メソッドの追加 — `IntelligenceService.swift`

#### `analyzeReceiptItems(_ ocrText: String) async throws -> [ScannedItem]`

Vision OCR で抽出したテキストを受け取り、Apple Intelligence（Foundation Models）で食材リストに構造化する。

**内部モデル:** `ReceiptItemRaw` (private struct, Codable) — AI の JSON 出力を受け取る中間型

**処理内容:**
1. `LanguageModelSession` に対してレシートOCRテキストを渡す
2. 食品以外（税・合計・店名等）を除外、食材名を一般名称に正規化するよう指示
3. JSON 配列 `[{name, count, category, estimatedDaysUntilExpiry}]` を返させる
4. `parseJSON()` でデコード → `ScannedItem` 配列に変換（賞味期限は `estimatedDaysUntilExpiry >= 90` なら `hasDeadline = false`）
5. エラーハンドリング: `guardrailViolation` / `refusal` / `parsingFailed` を適切にスロー

**推定賞味期限の目安（AI プロンプトに含まれる）:**
- 生肉 3日 / ひき肉 2日 / 魚 2日 / 豆腐 4日 / 卵 14日 / 牛乳 10日 / 葉物 4日 / 根菜 14日 / 果物 7日 / 調味料 90日+

---

### N-3. 新規ファイル作成 — `ScannerView.swift`

カメラスキャン画面。`ScanMode` (`.receipt` / `.barcode`) を `Picker` で切り替える。

#### `CameraController` (NSObject, AVCapturePhotoCaptureDelegate, AVCaptureMetadataOutputObjectsDelegate)

- `AVCaptureSession` を管理（`.photo` プリセット）
- `AVCapturePhotoOutput` と `AVCaptureMetadataOutput` を同時使用
- `setup(mode:)` で初期化（`Task.detached` でバックグラウンド起動）
- `capturePhoto()` でレシート撮影
- `metadataOutput(_:didOutput:from:)` でリアルタイムバーコード検出（2.5秒クールダウン）
- `nonisolated` デリゲートメソッド + `Task { @MainActor in ... }` でメインスレッドにコールバック（`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` 対応）

#### `CameraPreviewView` (UIViewRepresentable)

`UIView.layerClass` を `AVCaptureVideoPreviewLayer.self` にオーバーライドしたカスタム UIView を使用。

#### レシートスキャンフロー

1. 撮影 → `AVCapturePhotoCaptureDelegate` で `UIImage` 取得
2. `performOCR(on:)`: `VNRecognizeTextRequest` を `withCheckedThrowingContinuation` でラップして非同期化
3. `IntelligenceService.shared.analyzeReceiptItems()` を呼び出し
4. 結果 `[ScannedItem]` を `showScanResult = true` にセット → `ScanResultView` へ NavigationStack でプッシュ

#### バーコードスキャンフロー

1. `AVCaptureMetadataOutput` でリアルタイム検出
2. `BarcodeCache.shared.get(barcode)` でキャッシュ検索
3. 未登録の場合: `BarcodeNameInputSheet` シートを表示
4. 追加後: 「追加済み」トーストを2秒表示

---

### N-4. 新規ファイル作成 — `ScanResultView.swift`

スキャン結果の確認・編集・一括登録画面。`ScannerView` から NavigationStack でプッシュされる。

#### `ScannedItemEditRow`

折りたたみ式の編集行。タップで展開し以下を編集可能:
- 食材名（TextField）、カテゴリ（Picker menu）、個数（Stepper）、賞味期限（Toggle + DatePicker compact）

#### 買い物リストとの照合

`matchedShoppingItems`: `shoppingList` の各 `ShoppingItem.name` が `scannedItems` のいずれかに部分一致するものを抽出して表示。

#### `saveAllItems()`

1. `scannedItems` を `StockItem` に変換して `modelContext.insert()`
2. `matchedShoppingItems` を `modelContext.delete()`
3. `try? modelContext.save()`
4. 完了アニメーション（1.2秒）→ `onComplete()` コールバックで `ScannerView` を閉じる

#### `ManualScanItemSheet`

食材名・カテゴリ・個数・賞味期限を入力し、`ScannedItem` を生成してスキャン結果リストに追加するシート。

#### `Category.color` 拡張

`ScanResultView` 内でカテゴリカラードットを表示するための `Color` 拡張を定義。

---

### N-5. 既存ファイルの変更 — `StockItemView.swift`

**削除:**
- `showAddItemView` @State 変数
- 手動追加フォームシート（名前・カテゴリ・個数・賞味期限入力）
- `addItem()` 関数

**追加:**
- `showScanner` @State 変数
- ツールバーの `camera.badge.plus` ボタン → `.fullScreenCover(isPresented: $showScanner) { ScannerView() }`
- `emptyStateView`: 空状態のガイダンスビュー（スキャン誘導テキスト付き）
- `StockItemRow`: 名前・賞味期限（残日数テキスト）・個数を表示するサブビュー
- `categoryHeader(_:)`: カテゴリ名とカラードットを表示するセクションヘッダー

---

### N-6. 既存ファイルの変更 — `ShoppingListView.swift`

**削除:**
- `showCompletionSheet` @State 変数
- `ShoppingCompletionSheet` 構造体（購入完了 → 賞味期限設定 → 在庫追加）
- `applyStockAddition(results:)` 関数
- ツールバーの「購入完了」ボタン

**追加:**
- `checkedCount`: チェック済みアイテム数を算出する computed property
- チェック済みが存在する場合のスキャン誘導バナー（`camera.badge.plus` アイコン付き）
- ツールバーへの「チェック済みを削除」ボタン（`checkedCount > 0` の場合のみ表示）
- `clearCheckedItems()`: チェック済みアイテムを一括削除する関数
- 空状態の説明文にスキャン誘導テキストを追加

---

### N-7. `Info.plist` の変更

`NSCameraUsageDescription` キーを追加:
```
レシートやバーコードをスキャンして食材を冷蔵庫に追加するために使用します。
```

---

### 設計上の注意点

#### `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` への対応
Xcode 26 プロジェクトの設定により、すべての型がデフォルトで `@MainActor` に隔離される。
`CameraController` の AVFoundation デリゲートメソッドには `nonisolated` を付与し、
コールバック時は `Task { @MainActor in ... }` でメインアクターに戻すパターンを採用。

#### `AVCaptureSession` の非同期起動
`session.startRunning()` は UI スレッドをブロックするため `Task.detached { }` で実行。
同様に `session.stopRunning()` も `Task.detached { }` で実行。

#### バーコードキャッシュのスレッドセーフ性
`BarcodeCache` は `UserDefaults` へのシリアルアクセスのみで構成されており、
`@MainActor` 隔離下で利用するため実質的にシングルスレッドアクセスが保証される。

#### `PBXFileSystemSynchronizedRootGroup` による自動ファイル参照
プロジェクトは Xcode 26 の `PBXFileSystemSynchronizedRootGroup` を使用しているため、
`SmartChef/` ディレクトリに配置した Swift ファイルは自動的にビルドターゲットに含まれる。
新規ファイル（`ScannerView.swift`, `ScanResultView.swift`）の `.xcodeproj` 手動追加は不要。

---

### 既知の制限・今後の改善案

| 課題 | 内容 |
|---|---|
| バーコード外部 API | 現在はローカルキャッシュのみ。楽天商品検索 API 等の統合で未登録商品の自動名前解決が可能 |
| OCR 精度 | 照明・角度によって認識精度が低下する場合がある。フレーム内収まり検出やガイドアニメーションで改善余地あり |
| 買い物リスト照合精度 | 現在は部分一致。AI によるセマンティックマッチングで精度向上が期待できる |
| バーコードスキャン → ScanResultView | 現在バーコードスキャンは即時追加。複数商品をステージングしてから一括確認・追加するフローへの拡張を検討 |

---

## Task N+1: 設定画面の拡充（AppSettings + SettingsView 全面改修）

### 実装日: 2026-02-12

### 概要

既存の設定画面（献立自動生成タイミングと AI 機能表示のみ）を拡充し、アプリ全体に影響するユーザー設定を一元管理できる設定画面に改修した。

---

### N+1-1. `AppSettings.swift` — 設定プロパティの追加

既存の `generationMode` に加えて以下の 4 プロパティを追加:

| プロパティ | 型 | デフォルト | UserDefaults キー |
|---|---|---|---|
| `servingsCount` | `Int` | `2` | `"servingsCount"` |
| `expiryWarningDays` | `Int` | `7` | `"expiryWarningDays"` |
| `showExpiredItems` | `Bool` | `true` | `"showExpiredItems"` |
| `autoDeleteMatchedShoppingItems` | `Bool` | `true` | `"autoDeleteMatchedShoppingItems"` |

全プロパティが `didSet` で `UserDefaults.standard.set()` を呼び出し、アプリ再起動後も値を保持。
初期化では `UserDefaults` から値を復元し、未設定時はデフォルト値にフォールバック。

---

### N+1-2. `Models.swift` — `BarcodeCache.reset()` の追加

設定画面の「バーコードキャッシュをリセット」機能に対応するため `reset()` メソッドを追加:

```swift
func reset() {
    UserDefaults.standard.removeObject(forKey: userDefaultsKey)
}
```

---

### N+1-3. `SettingsView.swift` — 設定 UI の全面再構成

8 つのセクションで構成された設定フォームに全面的に書き換えた:

1. **食事設定** — `servingsCount` Stepper (1〜8人前)
2. **在庫管理** — `expiryWarningDays` Picker (3/5/7/10/14日) + `showExpiredItems` Toggle
3. **スキャン設定** — `autoDeleteMatchedShoppingItems` Toggle
4. **献立の自動生成タイミング** — 既存 `ModeSelectionRow` を流用
5. **AI機能** — 既存の Apple Intelligence 利用可否表示を流用
6. **データ管理** — バーコードキャッシュリセット + 全データ削除（`confirmationDialog` 付き）
7. **このアプリについて** — バージョン・ビルド番号
8. **開発用ツール** — 既存のサンプルデータ投入ボタンを流用

**`@Observable` と `Binding` のブリッジ:**
```swift
// AppSettings (@Observable) のプロパティを SwiftUI コントロール用 Binding に変換
Stepper(value: Binding(
    get: { settings.servingsCount },
    set: { settings.servingsCount = $0 }
), in: 1...8) { ... }
```

**全データ削除の実装:**
```swift
private func clearAllData() {
    try? modelContext.delete(model: StockItem.self)
    try? modelContext.delete(model: MealPlan.self)
    try? modelContext.delete(model: MealHistory.self)
    try? modelContext.delete(model: ShoppingItem.self)
    try? modelContext.save()
}
```

---

### N+1-4. `DashBordView.swift` — 期限警告日数のハードコード除去

`urgentItems()` 内のハードコードされた `7` を設定値に変更:

```swift
// 変更前
let sevenDaysLater = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

// 変更後
let threshold = Calendar.current.date(
    byAdding: .day,
    value: settings.expiryWarningDays,  // AppSettings.shared から取得
    to: Date()
) ?? Date()
```

---

### N+1-5. `StockItemView.swift` — 期限切れアイテムのフィルタリング

`filteredItems` computed property を追加し、`showExpiredItems = false` のとき期限切れアイテムを除外:

```swift
private var filteredItems: [StockItem] {
    guard !settings.showExpiredItems else { return items }
    let today = Calendar.current.startOfDay(for: Date())
    return items.filter { item in
        guard let deadline = item.deadline else { return true }  // 期限なし → 表示
        return Calendar.current.startOfDay(for: deadline) >= today
    }
}
```

`groupedItems` と `categories`、空状態判定のすべてを `filteredItems` ベースに変更。

---

### N+1-6. `ScanResultView.swift` — 買い物リスト自動削除の条件分岐

`saveAllItems()` 内の買い物リスト削除を設定値で制御:

```swift
// 設定が有効な場合のみ削除
if AppSettings.shared.autoDeleteMatchedShoppingItems {
    for shoppingItem in matchedShoppingItems {
        modelContext.delete(shoppingItem)
    }
}
```

完了アニメーションの「削除しました」メッセージも同様に条件分岐。

---

## Task N+2: 献立・買い物リスト生成完了時のローカル通知

### 実装日: 2026-02-12

### 概要

献立生成 → レシピ生成 → 買い物リスト自動補充の一連の処理は AI 生成を含むため数十秒〜数分かかる。完了タイミングをユーザーに通知するため、`UNUserNotificationCenter` を使ったローカル通知機能を実装した。

---

### N+2-1. 新規ファイル作成 — `NotificationService.swift`

ローカル通知の許可リクエストと送信を管理する enum。

#### `requestAuthorization()`

アプリ起動時に一度呼び出して `.alert`, `.sound`, `.badge` の通知許可をリクエスト。

#### `sendMealPlanReadyNotification(dishCount:shoppingItemCount:)`

フォアグラウンドでの献立・レシピ・買い物リスト生成完了時に通知を送信する。

```swift
static func sendMealPlanReadyNotification(dishCount: Int, shoppingItemCount: Int) {
    let content = UNMutableNotificationContent()
    content.title = "🍽️ 今日の献立が準備できました"
    if shoppingItemCount > 0 {
        content.body = "\(dishCount)品の献立とレシピを生成し、\(shoppingItemCount)件の食材を買い物リストに追加しました。"
    } else {
        content.body = "\(dishCount)品の献立とレシピを生成しました。買い物リストに追加する食材はありませんでした。"
    }
    content.sound = .default
    // 1秒後に即時通知
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    // ...
}
```

#### `sendBackgroundMealPlanNotification(mode:)`

バックグラウンドタスクでの自動生成完了時に通知を送信する。モードに応じてメッセージを変える。

---

### N+2-2. `ShoppingAutoFillService.swift` — 戻り値の変更

`fillShoppingList()` の戻り値を `Void` → `Int` に変更し、買い物リストに追加した食材の件数を返すようにした。

```swift
// 変更前
static func fillShoppingList(...) async throws { ... }

// 変更後
static func fillShoppingList(...) async throws -> Int { ... return insertedCount }
```

通知メッセージで「N件の食材を追加しました」と表示するために使用。

---

### N+2-3. `DashBordView.swift` — 通知送信の追加

`autoFillShoppingList(for:)` 内の `fillShoppingList()` 完了後に通知を送信。

```swift
do {
    let addedCount = try await ShoppingAutoFillService.fillShoppingList(...)
    // 献立・レシピ・買い物リスト生成完了の通知を送信
    NotificationService.sendMealPlanReadyNotification(
        dishCount: dishes.count,
        shoppingItemCount: addedCount
    )
} catch { ... }
```

---

### N+2-4. `MealPlanScheduler.swift` — バックグラウンド通知の追加

`handleTask(_:modelContainer:)` の `task.setTaskCompleted(success: true)` 直前に追加:

```swift
// バックグラウンドで献立生成が完了したことを通知
NotificationService.sendBackgroundMealPlanNotification(mode: mode)
```

バックグラウンドタスクで献立が自動生成された場合にも通知が届く。

---

### N+2-5. `SmartChefApp.swift` — 通知許可リクエストの追加

`init()` に `NotificationService.requestAuthorization()` を追加:

```swift
init() {
    MealPlanScheduler.registerHandler(modelContainer: container)
    MealPlanScheduler.scheduleNextGeneration()
    NotificationService.requestAuthorization()  // ← 追加
}
```

初回起動時にシステムの通知許可ダイアログが表示される。

---

### 通知内容一覧

| シナリオ | タイトル | 本文例 |
|---|---|---|
| フォアグラウンド（追加あり） | 🍽️ 今日の献立が準備できました | 6品の献立とレシピを生成し、15件の食材を買い物リストに追加しました。 |
| フォアグラウンド（追加なし） | 🍽️ 今日の献立が準備できました | 6品の献立とレシピを生成しました。買い物リストに追加する食材はありませんでした。 |
| バックグラウンド（朝モード） | 🍽️ 献立を自動生成しました | 今日の朝食・昼食・夕食の献立が準備できました。アプリを開いて確認してください。 |
| バックグラウンド（夕モード） | 🍽️ 献立を自動生成しました | 今夜の夕食と明日の朝食・昼食の献立が準備できました。アプリを開いて確認してください。 |

---

## Task N+3: 開発支援機能の強化（モックデータランダム化 + テストコード拡充）

### 実装日: 2026-02-12

### 概要

開発効率を向上させるため、モックデータ生成にランダム性を導入し、テストコードを大幅に拡充した。

---

### N+3-1. `DataMockService.swift` — ランダムデータ生成への全面改修

固定データを廃止し、豊富なデータプール（在庫65種類以上、料理名12〜24種類×3食事タイプ）からランダムに選択・生成する仕組みに変更。

**ランダム化されたパラメータ:**

| データ種別 | ランダムレンジ | ランダム要素 |
|---|---|---|
| 在庫（StockItem） | 6〜12件 | 食材名・カテゴリ、期限の有無（75%/25%）、期限日数（-1〜14日）、数量（1〜5個） |
| 買い物リスト（ShoppingItem） | 2〜6件 | 食材名・カテゴリ、数量（1〜4個）、チェック状態（20%チェック済み） |
| 食事履歴（MealHistory） | 7〜14日分 | 料理名（食事種類別プール）、記録率（朝60%/昼70%/夕85%）、時間帯のばらつき |
| 食事計画（MealPlan） | 3日×3食=9件 | 料理名（食事種類別計画用プール） |

**設計方針:**
- 名前の重複を防止するため `usedNames: Set<String>` で管理
- 個々の生成メソッドを `static` で公開し、テストコードからも直接呼べるように
- ヘルパー関数 `date(daysAgo:hour:)`, `planDate(daysFromNow:hour:)` も `static` に変更

---

### N+3-2. テストコードの拡充

既存 3 ファイルの更新 + 新規 5 ファイルの追加。

#### `DataMockServiceTests.swift` — 更新

ランダム化対応テストに更新:
- レンジチェック（6〜12件、2〜6件等）
- 名前の重複がないことのチェック
- 10回生成での多様性検証（少なくとも2種類以上の異なるデータセット）
- 期限付き・期限なしの混在テスト
- 食事履歴の日付範囲テスト
- 食事計画の未来日付テスト

#### `AppSettingsTests.swift` — 新規

- `AppSettings.shared` のシングルトン性テスト
- デフォルト値のテスト（`servingsCount`, `expiryWarningDays`）
- `MealPlanGenerationMode` の全プロパティテスト（rawValue, displayName, scheduledHour）

#### `MealPlanTests.swift` — 新規

- `MealPlan` の初期化・ステータス変更テスト
- `MealPlanStatus` の Codable テスト
- SwiftData CRUD テスト（保存・更新・削除）
- `MealType` でのフィルタ取得テスト

#### `BarcodeCacheTests.swift` — 新規

- シングルトン性テスト
- CRUD操作テスト（get/set/overwrite/delete）
- `reset()` による全クリアテスト
- `BarcodeCacheEntry` の Codable テスト
- 全カテゴリのエントリ保存・取得テスト

#### `ScannedItemTests.swift` — 新規

- デフォルト初期化テスト
- 全プロパティ初期化テスト
- UUID一意性テスト
- プロパティ変更テスト
- Identifiable準拠テスト

#### `ShoppingItemTests.swift` — 新規

- オプショナルプロパティ（`sourceMenuName`, `recipeAmount`）テスト
- SwiftData CRUD テスト
- `isSelected` トグルテスト
- 自動追加アイテム（`sourceMenuName != nil`）のフィルタテスト
- `ShoppingAutoFillService.clearAutoAddedItems()` テスト

#### `StockItemSwiftDataTests.swift` — 新規

- `StockItem` の SwiftData CRUD テスト
- カテゴリ別フィルタテスト
- 期限切れフィルタテスト
- ゼロカウントの保存テスト
- 一括削除テスト
- `MealHistory` の SwiftData テスト（保存・日付順ソート・MealType フィルタ・一括削除）

#### `IntegrationTests.swift` — 新規

実際のユーザーワークフローを再現する統合テスト:
- 完了報告→履歴記録ワークフロー
- 完了報告→在庫減算ワークフロー
- 献立変更ワークフロー
- モックデータ投入後の全データ取得テスト
- 全データ削除テスト
- 買い物リスト→在庫変換ワークフロー
- 当日の食事計画フィルタテスト
- 期限が近い食材（urgentItems）フィルタテスト

---

### テストファイル一覧

```
SmartChefTests/
├── ModelTests.swift              ← 既存（StockItem, ShoppingItem, MealHistory, Category 初期化）
├── DashBordLogicTests.swift      ← 既存（urgentItems, daysLabel ロジック）
├── DataMockServiceTests.swift    ← 更新（ランダム化対応テスト）
├── AppSettingsTests.swift        ← 新規
├── MealPlanTests.swift           ← 新規
├── BarcodeCacheTests.swift       ← 新規
├── ScannedItemTests.swift        ← 新規
├── ShoppingItemTests.swift       ← 新規
├── StockItemSwiftDataTests.swift ← 新規
└── IntegrationTests.swift        ← 新規
```


