import Foundation
import Vision
import AVFoundation
import UIKit

class CameraOCRService: NSObject, ObservableObject {
    @Published var lastResult: OCRResult?
    @Published var isScanning: Bool = false
    @Published var lowConfidenceWarning: Bool = false

    private var textRecognitionRequest: VNRecognizeTextRequest?

    override init() {
        super.init()
        setupVision()
    }

    private func setupVision() {
        textRecognitionRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            self?.processObservations(observations)
        }
        textRecognitionRequest?.recognitionLevel = .accurate
        textRecognitionRequest?.usesLanguageCorrection = true
        textRecognitionRequest?.recognitionLanguages = ["en-US", "es-ES", "de-DE", "fr-FR", "ja-JP", "zh-Hans"]
    }

    func processImage(_ image: CGImage) {
        guard let request = textRecognitionRequest else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try? handler.perform([request])
        }
    }

    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let request = textRecognitionRequest else {
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
        }
    }

    private func processObservations(_ observations: [VNRecognizedTextObservation]) {
        var bestResult: OCRResult?
        var highestConfidence: Float = 0

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }

            let text = candidate.string
            let confidence = candidate.confidence

            if let result = extractCurrencyAmount(from: text, confidence: confidence) {
                if result.confidence > highestConfidence {
                    highestConfidence = result.confidence
                    bestResult = result
                }
            }
        }

        DispatchQueue.main.async {
            if let result = bestResult {
                self.lastResult = result
                self.lowConfidenceWarning = result.confidence < 0.7
            }
        }
    }

    private func extractCurrencyAmount(from text: String, confidence: Float) -> OCRResult? {
        let patterns = [
            "([\\$€£¥₹₩₽฿₱₫₺₪])\\s*([0-9]{1,3}(?:[,.]?[0-9]{3})*(?:[.,][0-9]{1,2})?)",
            "([0-9]{1,3}(?:[,.]?[0-9]{3})*(?:[.,][0-9]{1,2})?)\\s*([\\$€£¥₹₩₽฿₱₫₺₪]|EUR|USD|GBP|JPY|MXN)",
            "(R\\$|NT\\$|Fr|kr|zł|Kč|Ft|RM|Rp|S/)\\s*([0-9]{1,3}(?:[,.]?[0-9]{3})*(?:[.,][0-9]{1,2})?)",
            "^([0-9]{1,3}(?:[,.]?[0-9]{3})*(?:[.,][0-9]{1,2})?)$"
        ]

        for pattern in patterns {
            if let result = matchPattern(pattern, in: text, confidence: confidence) {
                return result
            }
        }

        return nil
    }

    private func matchPattern(_ pattern: String, in text: String, confidence: Float) -> OCRResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        var numberString: String?
        var currencySymbol: String?

        for i in 1..<match.numberOfRanges {
            if let groupRange = Range(match.range(at: i), in: text) {
                let groupText = String(text[groupRange])
                if let _ = parseNumber(groupText) {
                    numberString = groupText
                } else if !groupText.isEmpty {
                    currencySymbol = groupText
                }
            }
        }

        guard let numStr = numberString,
              let amount = parseNumber(numStr) else {
            return nil
        }

        return OCRResult(
            amount: amount,
            currencySymbol: currencySymbol,
            rawText: text,
            confidence: confidence
        )
    }

    private func parseNumber(_ text: String) -> Double? {
        var cleanedText = text

        let commaCount = cleanedText.filter { $0 == "," }.count
        let dotCount = cleanedText.filter { $0 == "." }.count

        if commaCount > 0 && dotCount > 0 {
            if let lastComma = cleanedText.lastIndex(of: ","),
               let lastDot = cleanedText.lastIndex(of: ".") {
                if lastComma > lastDot {
                    cleanedText = cleanedText.replacingOccurrences(of: ".", with: "")
                    cleanedText = cleanedText.replacingOccurrences(of: ",", with: ".")
                } else {
                    cleanedText = cleanedText.replacingOccurrences(of: ",", with: "")
                }
            }
        } else if commaCount == 1 && dotCount == 0 {
            if let commaIndex = cleanedText.firstIndex(of: ",") {
                let afterComma = cleanedText[cleanedText.index(after: commaIndex)...]
                if afterComma.count <= 2 {
                    cleanedText = cleanedText.replacingOccurrences(of: ",", with: ".")
                } else {
                    cleanedText = cleanedText.replacingOccurrences(of: ",", with: "")
                }
            }
        } else {
            cleanedText = cleanedText.replacingOccurrences(of: ",", with: "")
        }

        return Double(cleanedText)
    }

    func clearResult() {
        DispatchQueue.main.async {
            self.lastResult = nil
            self.lowConfidenceWarning = false
        }
    }

    /// Process raw text from VisionKit DataScanner
    func processText(_ text: String) {
        // Split into lines and words to find currency amounts
        let lines = text.components(separatedBy: .newlines)
        var bestResult: OCRResult?
        var highestConfidence: Float = 0

        for line in lines {
            // Also try individual words
            let words = line.components(separatedBy: .whitespaces)
            let candidates = [line] + words

            for candidate in candidates {
                let trimmed = candidate.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    if let result = extractCurrencyAmount(from: trimmed, confidence: 0.9) {
                        if result.confidence > highestConfidence {
                            highestConfidence = result.confidence
                            bestResult = result
                        }
                    }
                }
            }
        }

        DispatchQueue.main.async {
            if let result = bestResult {
                self.lastResult = result
                self.lowConfidenceWarning = false
            }
        }
    }
}
