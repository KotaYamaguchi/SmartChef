//
//  ScannerView.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import AVFoundation
import SwiftData
import SwiftUI
import Vision

// MARK: - スキャンモード

enum ScanMode: String, CaseIterable {
    case receipt = "レシート"
    case barcode = "バーコード"
}

// MARK: - カメラプレビューView（UIViewRepresentable）

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - カメラコントローラー

final class CameraController: NSObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let metadataOutput = AVCaptureMetadataOutput()

    var onPhotoCaptured: ((UIImage) -> Void)?
    var onBarcodeDetected: ((String) -> Void)?

    private(set) var currentMode: ScanMode = .receipt
    private var lastDetectedBarcode: String?
    private var lastDetectionTime: Date?
    private let detectionCooldown: TimeInterval = 2.5

    func setup(mode: ScanMode) {
        currentMode = mode
        guard !session.isRunning else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            let supported = metadataOutput.availableMetadataObjectTypes
            let desired: [AVMetadataObject.ObjectType] = [
                .ean8, .ean13, .upce, .code128, .code39, .code93, .qr,
            ]
            metadataOutput.metadataObjectTypes = desired.filter { supported.contains($0) }
        }

        session.commitConfiguration()

        let capturedSession = session
        Task.detached {
            capturedSession.startRunning()
        }
    }

    func setScanMode(_ mode: ScanMode) {
        currentMode = mode
        // バーコード検出のクールダウンをリセット
        lastDetectedBarcode = nil
        lastDetectionTime = nil
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func stop() {
        let capturedSession = session
        Task.detached {
            capturedSession.stopRunning()
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
            let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        else { return }

        Task { @MainActor [weak self] in
            self?.onPhotoCaptured?(image)
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension CameraController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard currentMode == .barcode,
            let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let barcode = obj.stringValue
        else { return }

        let now = Date()
        if barcode == lastDetectedBarcode,
            let last = lastDetectionTime,
            now.timeIntervalSince(last) < detectionCooldown
        {
            return
        }
        lastDetectedBarcode = barcode
        lastDetectionTime = now
        onBarcodeDetected?(barcode)
    }
}

// MARK: - スキャナーメインView

struct ScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var scanMode: ScanMode = .receipt
    @State private var isAnalyzing = false
    @State private var scannedItems: [ScannedItem] = []
    @State private var showScanResult = false
    @State private var analysisError: String?
    @State private var showError = false
    @State private var barcodeToastMessage: String?

    // バーコード名前入力
    @State private var pendingBarcode: String?
    @State private var showBarcodeNameSheet = false

    @State private var cameraController = CameraController()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                CameraPreviewView(session: cameraController.session)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // モードセレクター
                    Picker("スキャンモード", selection: $scanMode) {
                        ForEach(ScanMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .onChange(of: scanMode) { _, newMode in
                        cameraController.setScanMode(newMode)
                    }

                    Spacer()

                    // スキャンガイドオーバーレイ
                    if scanMode == .receipt {
                        receiptGuideOverlay
                    } else {
                        barcodeGuideOverlay
                    }

                    Spacer()

                    // ボタンエリア
                    bottomControls
                        .padding(.bottom, 48)
                }

                // バーコード追加済みトースト
                if let message = barcodeToastMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(message)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.bottom, 160)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // AI解析中オーバーレイ
                if isAnalyzing {
                    Color.black.opacity(0.65).ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.6)
                            .tint(.white)
                        Text("AIが食材を解析中...")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("少々お待ちください")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .navigationTitle(scanMode == .receipt ? "レシートをスキャン" : "バーコードをスキャン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black.opacity(0.5), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationDestination(isPresented: $showScanResult) {
                ScanResultView(items: scannedItems) {
                    dismiss()
                }
            }
        }
        .alert("解析エラー", isPresented: $showError) {
            Button("手動で追加する") {
                scannedItems = []
                showScanResult = true
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text(analysisError ?? "食材の解析に失敗しました。手動で追加してください。")
        }
        .sheet(isPresented: $showBarcodeNameSheet) {
            if let barcode = pendingBarcode {
                BarcodeNameInputSheet(barcode: barcode) { name, category in
                    BarcodeCache.shared.set(barcode, name: name, category: category)
                    addBarcodeItemToStock(name: name, category: category)
                    showToast("「\(name)」を追加しました")
                }
            }
        }
        .onAppear {
            cameraController.setup(mode: scanMode)
            cameraController.onPhotoCaptured = { image in
                processReceiptImage(image)
            }
            cameraController.onBarcodeDetected = { barcode in
                handleBarcode(barcode)
            }
        }
        .onDisappear {
            cameraController.stop()
        }
    }

    // MARK: - サブビュー

    private var receiptGuideOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.75), lineWidth: 2)
                .frame(width: 310, height: 460)
                .overlay(alignment: .bottom) {
                    Text("レシート全体を枠内に収めてください")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.bottom, 14)
                }
        }
    }

    private var barcodeGuideOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.white.opacity(0.75), lineWidth: 2)
                .frame(width: 260, height: 110)
                .overlay(alignment: .bottom) {
                    Text("バーコードを枠内に合わせると自動で読み取ります")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .offset(y: 30)
                }
        }
    }

    private var bottomControls: some View {
        Group {
            if scanMode == .receipt {
                // 撮影ボタン
                Button {
                    cameraController.capturePhoto()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 72, height: 72)
                        Circle()
                            .stroke(.white.opacity(0.4), lineWidth: 5)
                            .frame(width: 84, height: 84)
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundStyle(.black)
                    }
                }
                .disabled(isAnalyzing)
                .opacity(isAnalyzing ? 0.4 : 1.0)
            } else {
                // バーコード完了ボタン
                Button {
                    dismiss()
                } label: {
                    Text("完了")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
        }
    }

    // MARK: - アクション

    private func handleBarcode(_ barcode: String) {
        if let entry = BarcodeCache.shared.get(barcode) {
            addBarcodeItemToStock(name: entry.name, category: entry.category)
            showToast("「\(entry.name)」を追加しました")
        } else {
            pendingBarcode = barcode
            showBarcodeNameSheet = true
        }
    }

    private func addBarcodeItemToStock(name: String, category: FoodCategory) {
        let item = StockItem(name: name, category: category)
        modelContext.insert(item)
        try? modelContext.save()
    }

    private func showToast(_ message: String) {
        withAnimation {
            barcodeToastMessage = message
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                barcodeToastMessage = nil
            }
        }
    }

    private func processReceiptImage(_ image: UIImage) {
        isAnalyzing = true
        Task {
            do {
                let text = try await performOCR(on: image)
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await MainActor.run {
                        isAnalyzing = false
                        analysisError = "テキストを認識できませんでした。レシートをもう少し近づけて再撮影してください。"
                        showError = true
                    }
                    return
                }

                if IntelligenceService.shared.isModelAvailable {
                    let items = try await IntelligenceService.shared.analyzeReceiptItems(text)
                    await MainActor.run {
                        scannedItems = items
                        isAnalyzing = false
                        showScanResult = true
                    }
                } else {
                    // AI未対応デバイスはScanResultViewで手動入力へ
                    await MainActor.run {
                        scannedItems = []
                        isAnalyzing = false
                        analysisError = "このデバイスではAI解析機能が利用できません。スキャン結果画面から手動で食材を追加してください。"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    analysisError = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    /// Vision フレームワークで画像からテキストを抽出する
    private func performOCR(on image: UIImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: IntelligenceError.parsingFailed)
                return
            }

            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text =
                    observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ja-JP", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - バーコード商品名入力シート

struct BarcodeNameInputSheet: View {
    let barcode: String
    let onRegister: (String, FoodCategory) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category: FoodCategory = .other

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    HStack {
                        Image(systemName: "barcode")
                            .foregroundStyle(.secondary)
                        Text(barcode)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    TextField("商品名を入力", text: $name)
                        .autocorrectionDisabled()
                }
                Section("カテゴリー") {
                    CategoryGridPicker(selection: $category)
                }
                Section {
                    Text("このバーコードは初めてスキャンされました。商品名とカテゴリを入力すると、次回から自動で認識されます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("商品を登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("登録して追加") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        onRegister(trimmed, category)
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
