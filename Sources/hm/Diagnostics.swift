import Foundation
import FoundationModels

enum Diagnostics {
    static func describe(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is not enabled. Enable it in System Settings."
        case .deviceNotEligible:
            return "this Mac is not eligible for Apple Intelligence."
        case .modelNotReady:
            return "the language model is not ready yet. Keep the Mac on power/Wi-Fi and try again later."
        @unknown default:
            return "unknown reason."
        }
    }

    static func describeGenerationError(_ error: Error) -> String {
        let nsError = error as NSError
        let raw = String(describing: error)

        if raw.contains("ModelManagerError Code=1008") {
            return """
            Apple ModelManagerError Code=1008. The SDK reports the model as available, but generation could not start.
            This usually means local Apple Intelligence model assets/runtime are not ready for FoundationModels yet.
            Check System Settings -> Apple Intelligence, keep the Mac on power/Wi-Fi, and try again later.
            Raw error: \(raw)
            """
        }

        if raw.contains("assetsUnavailable") {
            return """
            model assets are unavailable. Keep the Mac on power/Wi-Fi so Apple Intelligence can finish downloading.
            Raw error: \(raw)
            """
        }

        return "\(nsError.domain) code \(nsError.code): \(raw)"
    }
}

enum ExitCode {
    static let ok: Int32 = 0
    static let generalError: Int32 = 1
    static let usage: Int32 = 2
    static let unavailable: Int32 = 69
}
