import Foundation
import FoundationModels

struct TavilySearchResult: Decodable, PromptRepresentable {
    let query: String?
    let answer: String?
    let results: [TavilyResult]

    var promptRepresentation: Prompt {
        Prompt(promptText)
    }

    var promptText: String {
        var lines: [String] = []

        if let answer, !answer.isEmpty {
            lines.append("Tavily answer: \(answer)")
            lines.append("")
        }

        for (index, result) in results.prefix(5).enumerated() {
            lines.append("[\(index + 1)] \(result.title)")
            lines.append("URL: \(result.url)")
            if let content = result.content, !content.isEmpty {
                lines.append("Snippet: \(content)")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct TavilyResult: Decodable {
    let title: String
    let url: String
    let content: String?
}

struct TavilyClient: Sendable {
    let apiKey: String?
    var endpoint = URL(string: "https://api.tavily.com/search")!

    var isConfigured: Bool {
        guard let apiKey else {
            return false
        }

        return !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func search(query: String) async throws -> TavilySearchResult {
        guard let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TavilyError.missingAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15
        request.httpBody = try JSONEncoder().encode(TavilySearchRequest(query: query))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TavilyError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw TavilyError.httpStatus(httpResponse.statusCode, body)
        }

        return try JSONDecoder().decode(TavilySearchResult.self, from: data)
    }
}

private struct TavilySearchRequest: Encodable {
    let query: String
    let searchDepth = "basic"
    let maxResults = 5
    let includeAnswer = true
    let includeRawContent = false

    enum CodingKeys: String, CodingKey {
        case query
        case searchDepth = "search_depth"
        case maxResults = "max_results"
        case includeAnswer = "include_answer"
        case includeRawContent = "include_raw_content"
    }
}

enum TavilyError: Error, CustomStringConvertible {
    case missingAPIKey
    case invalidResponse
    case httpStatus(Int, String)

    var description: String {
        switch self {
        case .missingAPIKey:
            return "web search needs TAVILY_API_KEY. Set it or pass --no-search."
        case .invalidResponse:
            return "Tavily returned a non-HTTP response."
        case .httpStatus(let status, let body):
            let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return "Tavily returned HTTP \(status)."
            }
            return "Tavily returned HTTP \(status): \(trimmed)"
        }
    }
}

@Generable
struct TavilySearchArguments {
    @Guide(description: "A concise web search query for current information.")
    let query: String
}

actor ToolCallBudget {
    private var used = false

    func claim() -> Bool {
        if used {
            return false
        }
        used = true
        return true
    }
}

struct TavilySearchTool: Tool {
    let description = "Search the web for current or version-specific information. Use this when the answer may be stale without up-to-date sources."

    private let client: TavilyClient
    private let budget: ToolCallBudget

    init(client: TavilyClient, budget: ToolCallBudget = ToolCallBudget()) {
        self.client = client
        self.budget = budget
    }

    func call(arguments: TavilySearchArguments) async throws -> TavilySearchResult {
        guard await budget.claim() else {
            throw ToolCallLimitError()
        }

        return try await client.search(query: arguments.query)
    }
}

struct ToolCallLimitError: Error, CustomStringConvertible {
    var description: String {
        "hm allows only one web search per question."
    }
}
