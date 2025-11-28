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
    @State private var focusLocation: CGPoint = .zero

    var body: some View {
        GeometryReader { geometry in
            let regionWidth = bracketWidth + (regionPadding * 2)
            let regionHeight = bracketHeight + (regionPadding * 2)
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2

            ZStack {
                // Camera preview
                CameraPreviewView(cameraManager: cameraManager, onTapToFocus: { point in
                    focusLocation = point
                    showFocusIndicator = true
                    cameraManager.focus(at: point, viewSize: geometry.size)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation {
                            showFocusIndicator = false
                        }
                    }
                })
                .ignoresSafeArea()

                // Text highlight overlays (only show when active)
                if isActive {
                    ForEach(cameraManager.recognizedTextBoxes) { item in
                        TextHighlightBox(boundingBox: item.rect, viewSize: geometry.size)
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

                // Tap to focus hint (only show when active)
                if isActive {
                    VStack {
                        Spacer()
                        Text("Tap to focus")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(12)
                            .padding(.bottom, 8)
                    }
                    .allowsHitTesting(false)
                }
            }
        }
        .onAppear {
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
                scannedAmount = amount
                convertedAmount = exchangeRateManager.convert(
                    amount: amount,
                    from: currencyManager.sourceCurrency,
                    to: currencyManager.destinationCurrency
                )
            }
        }
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

// MARK: - Text Highlight Box
struct TextHighlightBox: View {
    let boundingBox: CGRect
    let viewSize: CGSize

    var body: some View {
        // Convert Vision coordinates (bottom-left origin, normalized) to SwiftUI (top-left origin)
        let x = boundingBox.minX * viewSize.width
        let y = (1 - boundingBox.maxY) * viewSize.height
        let width = boundingBox.width * viewSize.width
        let height = boundingBox.height * viewSize.height

        return RoundedRectangle(cornerRadius: 4)
            .fill(AppTheme.gold.opacity(0.15))
            .frame(width: width, height: height)
            .position(x: x + width/2, y: y + height/2)
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

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "cameraSessionQueue")
    private let processingQueue = DispatchQueue(label: "videoProcessingQueue", qos: .userInitiated)

    private var lastProcessedTime: Date = .distantPast
    private let processInterval: TimeInterval = 0.3 // Process every 300ms

    private var textRecognitionRequest: VNRecognizeTextRequest?
    private var device: AVCaptureDevice?

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
        let camera: AVCaptureDevice? = {
            // iPhone Pro models with triple camera (includes ultra-wide for macro)
            if let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
                print("✅ Using Triple Camera (macro supported)")
                return device
            }
            // iPhone models with dual wide camera (includes ultra-wide for macro)
            if let device = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                print("✅ Using Dual Wide Camera (macro supported)")
                return device
            }
            // Fallback to standard wide angle camera
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                print("ℹ️ Using Wide Angle Camera (no macro)")
                return device
            }
            return nil
        }()

        guard let camera = camera else {
            print("❌ No back camera available")
            captureSession.commitConfiguration()
            return
        }

        self.device = camera

        // Configure camera for fast autofocus optimized for close-up scanning
        do {
            try camera.lockForConfiguration()

            // Enable automatic camera switching for macro mode (Pro models)
            // This allows the camera to automatically switch to ultra-wide for close-up focus
            if camera.activePrimaryConstituentDeviceSwitchingBehavior != .unsupported {
                camera.setPrimaryConstituentDeviceSwitchingBehavior(.auto, restrictedSwitchingBehaviorConditions: [])
                print("✅ Automatic macro switching enabled")
            }

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

            // Smooth autofocus for video (less jarring transitions)
            if camera.isSmoothAutoFocusSupported {
                camera.isSmoothAutoFocusEnabled = true
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

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }

    func focus(at point: CGPoint, viewSize: CGSize) {
        guard let device = self.device else { return }

        // Convert view coordinates to camera coordinates (0-1 range)
        let focusPoint = CGPoint(
            x: point.y / viewSize.height,
            y: 1.0 - (point.x / viewSize.width)
        )

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

        // Define region of interest in normalized coordinates (0-1)
        // Center region: roughly 300x100 brackets + 5px padding on a typical screen
        // Vision coordinates: origin at bottom-left, so we need to calculate center
        let roiWidth: CGFloat = 0.85  // ~85% of screen width
        let roiHeight: CGFloat = 0.25 // ~25% of screen height
        let roiX = (1.0 - roiWidth) / 2
        let roiY = (1.0 - roiHeight) / 2
        let regionOfInterest = CGRect(x: roiX, y: roiY, width: roiWidth, height: roiHeight)

        var boxes: [CGRect] = []
        var bestAmount: Double?
        var highestConfidence: Float = 0

        for observation in observations {
            // Only process text within the region of interest
            let boundingBox = observation.boundingBox
            let centerX = boundingBox.midX
            let centerY = boundingBox.midY

            guard regionOfInterest.contains(CGPoint(x: centerX, y: centerY)) else {
                continue
            }

            guard let candidate = observation.topCandidates(1).first else { continue }

            let text = candidate.string
            let confidence = candidate.confidence

            // Add bounding box for highlighting
            boxes.append(boundingBox)

            // Try to extract currency amount
            if let amount = extractAmount(from: text), confidence > highestConfidence {
                highestConfidence = confidence
                bestAmount = amount
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.recognizedTextBoxes = boxes.map { IdentifiableRect(rect: $0) }
            if let amount = bestAmount {
                self?.recognizedAmount = amount
            }
        }
    }

    private func extractAmount(from text: String) -> Double? {
        let patterns = [
            "[\\$€£¥₹₩₽฿₱₫₺₪]\\s*([0-9]{1,3}(?:[,.]?[0-9]{3})*(?:[.,][0-9]{1,2})?)",
            "([0-9]{1,3}(?:[,.]?[0-9]{3})*(?:[.,][0-9]{1,2})?)\\s*[\\$€£¥₹₩₽฿₱₫₺₪]",
            "^([0-9]{1,3}(?:[,.]?[0-9]{3})*(?:[.,][0-9]{1,2})?)$"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {

                // Find the number group
                for i in 0..<match.numberOfRanges {
                    if let range = Range(match.range(at: i), in: text) {
                        let groupText = String(text[range])
                        if let number = parseNumber(groupText) {
                            return number
                        }
                    }
                }
            }
        }
        return nil
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

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    var onTapToFocus: ((CGPoint) -> Void)?

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
    var onTapToFocus: ((CGPoint) -> Void)?

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
        onTapToFocus?(point)
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
