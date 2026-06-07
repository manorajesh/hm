import Foundation

enum SearchRouter {
    private static let explicitSearchPhrases = [
        "search the web", "web search", "search online", "look online",
        "look up", "lookup", "google", "find online"
    ]

    private static let freshnessPhrases = [
        "latest", "current", "currently", "today", "yesterday", "tomorrow",
        "recent", "newest", "right now", "up to date", "up-to-date",
        "as of", "news", "price", "pricing", "stock price"
    ]

    static func shouldSearch(_ question: String) -> Bool {
        let normalized = question.lowercased()

        if explicitSearchPhrases.contains(where: { normalized.contains($0) }) {
            return true
        }

        return freshnessPhrases.contains { normalized.contains($0) }
    }

    static func query(from question: String) -> String {
        question
            .replacingOccurrences(of: "search for", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: "look up", with: "", options: [.caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
