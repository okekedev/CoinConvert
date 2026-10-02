import SwiftUI
import AVFoundation
import Vision

struct ScannerView: View {
    @EnvironmentObject var exchangeRateManager: ExchangeRateManager
    @EnvironmentObject var currencyManager: CurrencyManager
    @StateObject private var cameraManager = CameraManager()

    @Binding var scannedAmount: Double?
    @Binding var convertedAmount: Double?
    var isActive: Bool

    // Bracket dimensions (visual guide)
    private let bracketWidth: CGFloat = 300
    private let bracketHeight: CGFloat = 100

    // Region of interest extends 5px beyond brackets
    private let regionPadding: CGFloat = 5

    @State private var showFocusIndicator = false
    @State private var cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Environment(\.scenePhase) private var scenePhase
    @State private var focusLocation: CGPoint = .zero

    var body: some View {
        GeometryReader { geometry in
            let regionWidth = bracketWidth + (regionPadding * 2)
            let regionHeight = bracketHeight + (regionPadding * 2)
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2

            if cameraStatus == .denied || cameraStatus == .restricted {
                CameraAccessOffView()
            } else {
                ZStack {
                    // Camera preview
                    CameraPreviewView(cameraManager: cameraManager, onTapToFocus: { point, devicePoint in
                        focusLocation = point
                        showFocusIndicator = true
                        cameraManager.focus(at: devicePoint)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation {
                                showFocusIndicator = false
                            }
                        }
                    })
                    .ignoresSafeArea()

                    // Text highlight overlays (already in view coordinates)
                    if isActive {
                        ForEach(cameraManager.recognizedTextBoxes) { item in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.gold.opacity(0.18))
                                .frame(width: item.rect.width, height: item.rect.height)
                                .position(x: item.rect.midX, y: item.rect.midY)
                        }
                    }

                    // Paused overlay - 50% black with cutout for scan region
                    if !isActive {
                        PausedOverlay(
                            regionWidth: regionWidth,
                            regionHeight: regionHeight,
                            centerX: centerX,
                            centerY: centerY
                        )
                        .allowsHitTesting(false)
                    }

                    // Bracket overlay (visual guide)
                    ScanBrackets()
                        .frame(width: bracketWidth, height: bracketHeight)
                        .position(x: centerX, y: centerY)
                        .allowsHitTesting(false)

                    // Focus indicator
                    if showFocusIndicator {
                        FocusIndicator()
                            .position(focusLocation)
                            .transition(.opacity)
                    }
                }
                .onAppear {
                    cameraManager.updateLayout(viewSize: geometry.size, scanRect: scanRect(in: geometry.size))
                }
                .onChange(of: geometry.size) { _, size in
                    cameraManager.updateLayout(viewSize: size, scanRect: scanRect(in: size))
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Pick up a permission change made in Settings.
            if phase == .active {
                cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
            }
        }
        .onAppear {
            cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
            if isActive {
                cameraManager.startSession()
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                cameraManager.startSession()
            } else {
                cameraManager.stopSession()
            }
        }
        .onChange(of: cameraManager.recognizedAmount) { _, newAmount in
            if isActive, let amount = newAmount {
                withAnimation(.snappy(duration: 0.35)) {
                    scannedAmount = amount
                    convertedAmount = exchangeRateManager.convert(
                        amount: amount,
                        from: currencyManager.sourceCurrency,
                        to: currencyManager.destinationCurrency
                    )
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}

extension ScannerView {
    /// The bracket area in view coordinates, padded slightly. Only text in here is read.
    func scanRect(in size: CGSize) -> CGRect {
        let width = bracketWidth + regionPadding * 2
        let height = bracketHeight + regionPadding * 2
        return CGRect(x: (size.width - width) / 2, y: (size.height - height) / 2, width: width, height: height)
    }
}

// MARK: - Scan Readout

/// Two cards side by side, each in its country's flag colors: what was scanned and
/// what it is in the other currency. Digits roll to each new value and the
/// result card pops so the eye lands on it.
struct ScanReadout: View {
    @EnvironmentObject var currencyManager: CurrencyManager
    @EnvironmentObject var storeManager: StoreManager
    let sourceAmount: Double?
    let convertedAmount: Double?
    let selectSource: (Currency) -> Void
    let selectDestination: (Currency) -> Void
    /// Scanner: show locks on Pro currencies. Calculator: every currency is free.
    var locksProCurrencies = true
    /// Scanner: pop the result when a new price locks in. Calculator: no pop on every key.
    var popsOnChange = true

    @State private var showingSourcePicker = false
    @State private var showingDestinationPicker = false
    @State private var popped = false

    private func isLocked(_ currency: Currency) -> Bool {
        locksProCurrencies && !storeManager.isPro && !CurrencyManager.freeScanPair.contains(currency.code)
    }

    var body: some View {
        HStack(spacing: 10) {
            CurrencyCard(currency: currencyManager.sourceCurrency, amount: sourceAmount) {
                showingSourcePicker = true
            }
            CurrencyCard(currency: currencyManager.destinationCurrency, amount: convertedAmount) {
                showingDestinationPicker = true
            }
            .scaleEffect(popped ? 1.03 : 1)
        }
        .overlay(alignment: .center) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) { currencyManager.swapCurrencies() }
            }) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                    .frame(width: 44, height: 44)
                    .background(Color.white, in: Circle())
                    .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 2)
            }
            .accessibilityLabel("Swap currencies")
        }
        .onChange(of: sourceAmount) { _, _ in
            guard popsOnChange else { return }
            withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) { popped = true }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.15)) { popped = false }
        }
        .sheet(isPresented: $showingSourcePicker) {
            CurrencyListView(selectedCurrency: Binding(
                get: { currencyManager.sourceCurrency }, set: selectSource), isLocked: isLocked)
        }
        .sheet(isPresented: $showingDestinationPicker) {
            CurrencyListView(selectedCurrency: Binding(
                get: { currencyManager.destinationCurrency }, set: selectDestination), isLocked: isLocked)
        }
    }
}

/// One currency, tinted with its flag's colors.
struct CurrencyCard: View {
    let currency: Currency
    let amount: Double?
    let onChangeCurrency: () -> Void

    var body: some View {
        let palette = FlagPalette.palette(for: currency.flag)

        VStack(alignment: .leading, spacing: 0) {
            Button(action: onChangeCurrency) {
                HStack(spacing: 6) {
                    Text(currency.flag).font(.system(size: 26))
                    Text(currency.code)
                        .font(.system(size: 17, weight: .bold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .opacity(0.8)
                }
                .foregroundColor(.white)
                .padding(.trailing, 8)
                .frame(minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .accessibilityLabel("\(currency.name). Change currency")

            Spacer(minLength: 8)

            Text(format(amount ?? 0))
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
                .opacity(amount == nil ? 0.4 : 1)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .contentTransition(.numericText())
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [palette.primary, palette.primaryDeep],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        // The flag's second color as a stripe, so colors never blend into mud.
        .overlay(alignment: .bottom) {
            palette.accent.frame(height: 6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .animation(.easeInOut(duration: 0.3), value: currency.code)
    }

    private func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        formatter.currencySymbol = currency.symbol
        formatter.maximumFractionDigits = value >= 1000 ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(currency.symbol)\(value)"
    }
}

// MARK: - Flag Palette

/// Card colors taken from a flag emoji: its most common saturated color as the
/// background (darkened until white text reads clearly) and its second color as
/// an accent. Works for every currency without a hand-made color table.
enum FlagPalette {
    struct Palette {
        let primary: Color
        let primaryDeep: Color
        let accent: Color
    }

    private static var cache: [String: Palette] = [:]
    private static let fallback = Palette(primary: AppTheme.blue, primaryDeep: AppTheme.darkBlue, accent: AppTheme.gold)

    static func palette(for flag: String) -> Palette {
        if let cached = cache[flag] { return cached }
        let result = extract(flag) ?? fallback
        cache[flag] = result
        return result
    }

    private static func extract(_ flag: String) -> Palette? {
        // Draw into a buffer with a known RGBA layout so channels read correctly.
        let side = 48
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8,
                bytesPerRow: side * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            UIGraphicsPushContext(context)
            // UIKit text drawing expects a top-left origin.
            context.translateBy(x: 0, y: CGFloat(side))
            context.scaleBy(x: 1, y: -1)
            (flag as NSString).draw(at: .zero, withAttributes: [.font: UIFont.systemFont(ofSize: 40)])
            UIGraphicsPopContext()
            return true
        }
        guard drawn else { return nil }

        // Count pixels by coarse color bucket, skipping transparent, white-ish and black-ish.
        var buckets: [Int: (count: Int, r: Int, g: Int, b: Int)] = [:]
        for y in 0..<side {
            for x in 0..<side {
                let i = (y * side + x) * 4
                let r = Int(pixels[i]), g = Int(pixels[i + 1]), b = Int(pixels[i + 2]), a = Int(pixels[i + 3])
                guard a > 200 else { continue }
                let maxC = max(r, g, b), minC = min(r, g, b)
                // Skip white, black and greys (anti-aliased edges, white fields).
                if maxC < 30 || Double(maxC - minC) / Double(maxC) < 0.3 { continue }
                let key = (r / 48) << 8 | (g / 48) << 4 | (b / 48)
                let e = buckets[key] ?? (0, 0, 0, 0)
                buckets[key] = (e.count + 1, e.r + r, e.g + g, e.b + b)
            }
        }
        let top = buckets.values.sorted { $0.count > $1.count }.prefix(2)
        guard let first = top.first else { return nil }

        func average(_ bucket: (count: Int, r: Int, g: Int, b: Int)) -> (Double, Double, Double) {
            let n = Double(bucket.count) * 255
            return (Double(bucket.r) / n, Double(bucket.g) / n, Double(bucket.b) / n)
        }
        let (r, g, b) = average(first)
        let primary = readable(r: r, g: g, b: b)
        let primaryDeep = readable(r: r * 0.7, g: g * 0.7, b: b * 0.7)
        // Single-color flags (or white + one color) use white as the accent.
        let accent: Color = top.count > 1 ? {
            let (ar, ag, ab) = average(top[top.index(after: top.startIndex)])
            return Color(red: ar, green: ag, blue: ab)
        }() : .white
        return Palette(primary: primary, primaryDeep: primaryDeep, accent: accent)
    }

    /// Darkens a color until white text on it has at least ~4.5:1 contrast.
    private static func readable(r: Double, g: Double, b: Double) -> Color {
        func luminance(_ r: Double, _ g: Double, _ b: Double) -> Double {
            func channel(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
            return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
        }
        var (r, g, b) = (r, g, b)
        while luminance(r, g, b) > 0.18 {
            r *= 0.9; g *= 0.9; b *= 0.9
        }
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Paused Overlay
struct PausedOverlay: View {
    let regionWidth: CGFloat
    let regionHeight: CGFloat
    let centerX: CGFloat
    let centerY: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // Full screen rectangle
                path.addRect(CGRect(origin: .zero, size: geometry.size))

                // Cutout rectangle for scan region (slightly larger than brackets)
                let cutoutRect = CGRect(
                    x: centerX - regionWidth / 2,
                    y: centerY - regionHeight / 2,
                    width: regionWidth,
                    height: regionHeight
                )
                path.addRoundedRect(in: cutoutRect, cornerSize: CGSize(width: 8, height: 8))
            }
            .fill(Color.black.opacity(0.5), style: FillStyle(eoFill: true))
        }
    }
}

// MARK: - Identifiable Rect Wrapper
struct IdentifiableRect: Identifiable {
    let id = UUID()
    let rect: CGRect
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var recognizedAmount: Double?
    @Published var recognizedTextBoxes: [IdentifiableRect] = []
    private var pendingAmount: Double?

    /// Preview size and bracket rect (view coordinates), set from the main thread.
    private let layoutLock = NSLock()
    private var viewSize: CGSize = .zero
    private var scanRect: CGRect = .zero
    /// Mapping for the frame being processed (processing queue only).
    private var frameMapping: FrameMapping?

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "cameraSessionQueue")
    private let processingQueue = DispatchQueue(label: "videoProcessingQueue", qos: .userInitiated)

    private var lastProcessedTime: Date = .distantPast
    private let processInterval: TimeInterval = 0.3 // Process every 300ms

    private var textRecognitionRequest: VNRecognizeTextRequest?
    private var device: AVCaptureDevice?
    /// The wide-then-closer zoom runs once per camera session, never stacked.
    private var hasZoomedIn = false

    override init() {
        super.init()
        setupVision()
        setupSession()
    }

    private func setupVision() {
        textRecognitionRequest = VNRecognizeTextRequest { [weak self] request, error in
            self?.handleTextRecognition(request: request, error: error)
        }
        textRecognitionRequest?.recognitionLevel = .accurate
        textRecognitionRequest?.usesLanguageCorrection = false // Faster without language correction
        textRecognitionRequest?.recognitionLanguages = ["en-US"]
    }

    private func setupSession() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        // Get the best available camera for close-up scanning
        // Priority: Triple camera (Pro models) > Dual Wide > Wide Angle
        // Triple/DualWide cameras support automatic macro switching
        // Main (wide) lens only. Multi-lens virtual cameras switch lenses as you
        // move closer, which shows up as sudden zoom jumps and focus hunting.
        let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)

        guard let camera = camera else {
            print("❌ No back camera available")
            captureSession.commitConfiguration()
            return
        }

        self.device = camera

        // Configure camera for fast autofocus optimized for close-up scanning
        do {
            try camera.lockForConfiguration()

            // Start wide so the price is easy to find; zoomInOnce() tightens it shortly after.
            camera.videoZoomFactor = 1

            // Enable continuous autofocus - this is the key for instant focus
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }

            // Restrict autofocus to near range for close-up price tag scanning
            if camera.isAutoFocusRangeRestrictionSupported {
                camera.autoFocusRangeRestriction = .near
            }

            // Enable subject area change monitoring (like native Camera app)
            // This re-triggers autofocus when the scene changes
            camera.isSubjectAreaChangeMonitoringEnabled = true

            // Enable auto exposure
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposureMode = .continuousAutoExposure
            }

            // Smooth autofocus is meant for recording video and makes focusing slow.
            if camera.isSmoothAutoFocusSupported {
                camera.isSmoothAutoFocusEnabled = false
            }

            camera.unlockForConfiguration()
        } catch {
            print("❌ Could not configure camera: \(error)")
        }

        // Listen for subject area changes to re-trigger autofocus
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subjectAreaDidChange),
            name: .AVCaptureDeviceSubjectAreaDidChange,
            object: camera
        )

        // Add input
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("❌ Could not create camera input: \(error)")
            captureSession.commitConfiguration()
            return
        }

        // Add output
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        // Set video orientation
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }

        captureSession.commitConfiguration()
    }

    func updateLayout(viewSize: CGSize, scanRect: CGRect) {
        layoutLock.lock()
        self.viewSize = viewSize
        self.scanRect = scanRect
        layoutLock.unlock()
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
            self.zoomInOnce()
        }
    }

    /// After a moment on the wide view, smoothly zoom in once, just enough that a
    /// price fills the brackets while the phone is still beyond the lens's closest
    /// focus distance. Without this, people hold the phone too close and it can't focus.
    /// (Same approach as Apple's barcode-scanning sample.)
    private func zoomInOnce() {
        guard !hasZoomedIn, let device = device else { return }
        hasZoomedIn = true

        let target = Self.focusFriendlyZoom(for: device)
        sessionQueue.asyncAfter(deadline: .now() + 1.0) {
            do {
                try device.lockForConfiguration()
                device.ramp(toVideoZoomFactor: target, withRate: 2.0)
                device.unlockForConfiguration()
            } catch {
                print("❌ Could not zoom: \(error)")
            }
        }
    }

    static func focusFriendlyZoom(for device: AVCaptureDevice) -> CGFloat {
        let priceWidthMM: Double = 30          // a printed price like "£24.00"
        let fillOfPreviewWidth: Double = 0.5   // about 60% of the bracket width
        let minimumFocusMM = Double(device.minimumFocusDistance)
        guard minimumFocusMM > 0 else { return 1.15 }

        // videoFieldOfView is across the sensor's long side; the preview is portrait,
        // so its width is the short side.
        let dimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
        let shortOverLong = Double(min(dimensions.width, dimensions.height)) / Double(max(dimensions.width, dimensions.height))
        let longHalfFOV = Double(device.activeFormat.videoFieldOfView) / 2 * .pi / 180
        let shortHalfFOV = atan(tan(longHalfFOV) * shortOverLong)

        // Distance at which the price spans the target share of the preview width at 1x.
        let distanceAt1x = (priceWidthMM / fillOfPreviewWidth) / (2 * tan(shortHalfFOV))
        let zoom = max(1.15, minimumFocusMM / distanceAt1x)
        return min(CGFloat(zoom), min(2.5, device.maxAvailableVideoZoomFactor))
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }

    /// `focusPoint` is in capture-device coordinates (from the preview layer).
    func focus(at focusPoint: CGPoint) {
        guard let device = self.device else { return }

        do {
            try device.lockForConfiguration()

            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }

            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .autoExpose
            }

            device.unlockForConfiguration()

            // Return to continuous autofocus after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.resetToContinuousAutofocus()
            }
        } catch {
            print("❌ Could not focus: \(error)")
        }
    }

    private func resetToContinuousAutofocus() {
        guard let device = self.device else { return }

        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {
            print("❌ Could not reset to continuous autofocus: \(error)")
        }
    }

    // Called when the scene changes - re-triggers autofocus like native Camera app
    @objc private func subjectAreaDidChange(notification: NSNotification) {
        guard let device = self.device else { return }

        do {
            try device.lockForConfiguration()

            // Reset to center focus point
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            }

            // Re-enable continuous autofocus
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }

            // Reset exposure to center
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
            }

            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }

            device.unlockForConfiguration()
        } catch {
            print("❌ Could not reset focus on subject area change: \(error)")
        }
    }

    private func handleTextRecognition(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

        guard let mapping = frameMapping else { return }

        var boxes: [CGRect] = []
        var best: (amount: Double, score: Float)?

        for observation in observations {
            // Vision only read inside the brackets (regionOfInterest); map back for highlighting.
            boxes.append(mapping.viewRect(fromROIBox: observation.boundingBox))

            // Vision's top guess is sometimes a misread ("S12.99"); try the alternates too.
            for candidate in observation.topCandidates(3) {
                guard let match = extractAmount(from: candidate.string) else { continue }
                // Text with a currency symbol or code beats a bare number (years, phone digits).
                let score = candidate.confidence + (match.hasCurrencyMarker ? 1 : 0)
                if score > (best?.score ?? 0) {
                    best = (match.amount, score)
                }
                break
            }
        }

        let amount = best?.amount
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.recognizedTextBoxes = boxes.map { IdentifiableRect(rect: $0) }
            // Publish only once the same amount reads on two frames in a row,
            // so the result doesn't flicker or catch half-focused misreads.
            if let amount = amount, amount == self.pendingAmount {
                self.recognizedAmount = amount
            }
            self.pendingAmount = amount
        }
    }

    private static let symbols = "\\$€£¥₹₩₽฿₱₫₺₪"
    private static let number = "([0-9]{1,3}(?:[,.]?[0-9]{3})*(?:[.,][0-9]{1,2})?)"
    private static let code = "(?:USD|EUR|GBP|JPY|AUD|CAD|CHF|CNY|MXN|INR|THB|KRW|NZD|SGD|HKD|AED|SEK|NOK|DKK|ZAR|BRL|PHP|IDR|VND|TRY|PLN|CZK|HUF|ILS)"
    private static let markedPatterns: [NSRegularExpression] = [
        "[\(symbols)]\\s*\(number)",
        "\(number)\\s*[\(symbols)]",
        "\(code)\\s*\(number)",
        "\(number)\\s*\(code)",
    ].compactMap { try? NSRegularExpression(pattern: $0, options: [.caseInsensitive]) }
    private static let barePattern = try? NSRegularExpression(pattern: "^\(number)$")

    private func extractAmount(from rawText: String) -> (amount: Double, hasCurrencyMarker: Bool)? {
        let text = Self.normalizeOCR(rawText)
        let range = NSRange(text.startIndex..., in: text)

        for regex in Self.markedPatterns {
            if let match = regex.firstMatch(in: text, range: range),
               let numberRange = Range(match.range(at: 1), in: text),
               let value = parseNumber(String(text[numberRange])), value > 0 {
                return (value, true)
            }
        }
        if let regex = Self.barePattern,
           let match = regex.firstMatch(in: text, range: range),
           let numberRange = Range(match.range(at: 1), in: text),
           let value = parseNumber(String(text[numberRange])), value > 0 {
            return (value, false)
        }
        return nil
    }

    /// Fixes common OCR confusions on price text: "S12.99" -> "$12.99", "1O.5O" -> "10.50".
    private static func normalizeOCR(_ text: String) -> String {
        var t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = t.first, first == "S" || first == "s",
           t.dropFirst().first.map({ $0.isNumber || $0 == " " }) == true {
            t = "$" + t.dropFirst()
        }
        let digitLike: [Character: Character] = ["O": "0", "o": "0", "l": "1", "I": "1"]
        let chars = Array(t)
        return String(chars.enumerated().map { i, c in
            guard let replacement = digitLike[c] else { return c }
            let prevDigit = i > 0 && chars[i - 1].isNumber
            let nextDigit = i + 1 < chars.count && chars[i + 1].isNumber
            return (prevDigit || nextDigit) ? replacement : c
        })
    }

    private func parseNumber(_ text: String) -> Double? {
        var cleaned = text.trimmingCharacters(in: .whitespaces)

        // Remove currency symbols
        let symbols = CharacterSet(charactersIn: "$€£¥₹₩₽฿₱₫₺₪")
        cleaned = cleaned.trimmingCharacters(in: symbols)

        // Handle European vs US number format
        let commaCount = cleaned.filter { $0 == "," }.count
        let dotCount = cleaned.filter { $0 == "." }.count

        if commaCount > 0 && dotCount > 0 {
            if let lastComma = cleaned.lastIndex(of: ","),
               let lastDot = cleaned.lastIndex(of: ".") {
                if lastComma > lastDot {
                    cleaned = cleaned.replacingOccurrences(of: ".", with: "")
                    cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
                } else {
                    cleaned = cleaned.replacingOccurrences(of: ",", with: "")
                }
            }
        } else if commaCount == 1 && dotCount == 0 {
            if let commaIndex = cleaned.firstIndex(of: ",") {
                let afterComma = cleaned[cleaned.index(after: commaIndex)...]
                if afterComma.count <= 2 {
                    cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
                } else {
                    cleaned = cleaned.replacingOccurrences(of: ",", with: "")
                }
            }
        } else {
            cleaned = cleaned.replacingOccurrences(of: ",", with: "")
        }

        return Double(cleaned)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = Date()
        guard now.timeIntervalSince(lastProcessedTime) >= processInterval else { return }
        lastProcessedTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let request = textRecognitionRequest else { return }

        layoutLock.lock()
        let viewSize = self.viewSize
        let scanRect = self.scanRect
        layoutLock.unlock()
        let imageSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        guard let mapping = FrameMapping(imageSize: imageSize, viewSize: viewSize, scanRect: scanRect) else { return }

        // Only read text inside the brackets.
        frameMapping = mapping
        request.regionOfInterest = mapping.regionOfInterest
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}

// MARK: - Frame Mapping

/// Converts between view coordinates and Vision's normalized image coordinates
/// for a preview shown with aspect-fill (the image is scaled up and cropped).
struct FrameMapping {
    let scale: CGFloat
    let offset: CGPoint      // how much of the scaled image is cropped off left/top
    let imageSize: CGSize
    /// The bracket area in Vision coordinates (normalized, origin bottom-left).
    let regionOfInterest: CGRect

    init?(imageSize: CGSize, viewSize: CGSize, scanRect: CGRect) {
        guard imageSize.width > 0, imageSize.height > 0, viewSize.width > 0, viewSize.height > 0,
              !scanRect.isEmpty else { return nil }
        let scale = max(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let offset = CGPoint(x: (imageSize.width * scale - viewSize.width) / 2,
                             y: (imageSize.height * scale - viewSize.height) / 2)
        let displayed = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

        let x = (scanRect.minX + offset.x) / displayed.width
        let yTop = (scanRect.minY + offset.y) / displayed.height
        let roi = CGRect(x: x, y: 1 - yTop - scanRect.height / displayed.height,
                         width: scanRect.width / displayed.width, height: scanRect.height / displayed.height)

        self.scale = scale
        self.offset = offset
        self.imageSize = imageSize
        self.regionOfInterest = roi.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
    }

    /// A Vision box relative to the region of interest -> view coordinates.
    func viewRect(fromROIBox box: CGRect) -> CGRect {
        let roi = regionOfInterest
        let image = CGRect(x: roi.minX + box.minX * roi.width, y: roi.minY + box.minY * roi.height,
                           width: box.width * roi.width, height: box.height * roi.height)
        let displayedWidth = imageSize.width * scale
        let displayedHeight = imageSize.height * scale
        return CGRect(x: image.minX * displayedWidth - offset.x,
                      y: (1 - image.maxY) * displayedHeight - offset.y,
                      width: image.width * displayedWidth,
                      height: image.height * displayedHeight)
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    var onTapToFocus: ((_ viewPoint: CGPoint, _ devicePoint: CGPoint) -> Void)?

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.session = cameraManager.captureSession
        view.onTapToFocus = onTapToFocus
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.onTapToFocus = onTapToFocus
    }
}

class CameraPreviewUIView: UIView {
    var onTapToFocus: ((_ viewPoint: CGPoint, _ devicePoint: CGPoint) -> Void)?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    var session: AVCaptureSession? {
        get { previewLayer.session }
        set {
            previewLayer.session = newValue
            previewLayer.videoGravity = .resizeAspectFill
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTapGesture()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTapGesture()
    }

    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        onTapToFocus?(point, previewLayer.captureDevicePointConverted(fromLayerPoint: point))
    }
}

// MARK: - Scan Brackets
struct ScanBrackets: View {
    private let bracketLength: CGFloat = 30
    private let lineWidth: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                // Top-left bracket
                Path { path in
                    path.move(to: CGPoint(x: 0, y: bracketLength))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: bracketLength, y: 0))
                }
                .stroke(AppTheme.gold, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

                // Top-right bracket
                Path { path in
                    path.move(to: CGPoint(x: width - bracketLength, y: 0))
                    path.addLine(to: CGPoint(x: width, y: 0))
                    path.addLine(to: CGPoint(x: width, y: bracketLength))
                }
                .stroke(AppTheme.gold, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

                // Bottom-left bracket
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height - bracketLength))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: bracketLength, y: height))
                }
                .stroke(AppTheme.gold, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

                // Bottom-right bracket
                Path { path in
                    path.move(to: CGPoint(x: width - bracketLength, y: height))
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: width, y: height - bracketLength))
                }
                .stroke(AppTheme.gold, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

// MARK: - Focus Indicator
struct FocusIndicator: View {
    @State private var scale: CGFloat = 1.5
    @State private var opacity: Double = 1.0

    var body: some View {
        Circle()
            .stroke(AppTheme.gold, lineWidth: 2)
            .frame(width: 70, height: 70)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    scale = 1.0
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                    opacity = 0.3
                }
            }
    }
}
