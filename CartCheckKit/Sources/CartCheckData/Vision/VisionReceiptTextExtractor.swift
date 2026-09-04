import Foundation
import ImageIO
import Vision
import CartCheckDomain

public enum ReceiptTextExtractionError: Error {
    case invalidImageData
}

/// Reads a photographed receipt using the Vision framework's on-device text
/// recognition — no network call, nothing leaves the phone. Raw recognized
/// lines are handed to `ReceiptLineParser` to turn into structured items.
public struct VisionReceiptTextExtractor: ReceiptTextExtracting, Sendable {
    public init() {}

    public func extractLines(fromReceiptImageData data: Data) async throws -> [ReceiptLine] {
        guard let cgImage = Self.makeCGImage(from: data) else {
            throw ReceiptTextExtractionError.invalidImageData
        }
        let rawLines = try await Self.recognizeText(in: cgImage)
        return ReceiptLineParser.parse(rawLines)
    }

    private static func makeCGImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private static func recognizeText(in cgImage: CGImage) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines)
            }
            // Register printing uses abbreviations that aren't real words
            // ("ORG BANANA") — language correction would fight that.
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
