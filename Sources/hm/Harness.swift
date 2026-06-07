import Foundation
import FoundationModels

enum PromptDefaults {
    static func instructions(verbose: Bool) -> String {
        if verbose {
            return """
            You are hm, a command-line assistant for a developer.
            Answer programming, shell, and git questions clearly.
            Prefer exact commands and explain only the relevant reasoning.
            For Git questions, prefer standard Git CLI commands over editing config files manually.
            If you are unsure, say what assumption you are making.
            If you use web search, ground the answer in the search results and include source URLs.
            """
        }

        return """
    You are hm, a concise command-line assistant for a developer.
    Be direct. No tutorials. No step-by-step setup unless explicitly requested.
    For simple command questions, answer with only the command and at most one short note.
    Prefer exact commands over explanation.
    For Git questions, prefer standard Git CLI commands over editing config files manually.
    If there are two common cases, show the primary command first and the alternate case second.
    Do not say "open your terminal", "navigate to the directory", or explain obvious CLI basics.
    If you are unsure, state the assumption in one short sentence.
    If you use web search, include only the answer plus source URLs.
    If the user asks for current, latest, recent, version-specific, API, release, price, legal, financial, or news information, use web search when available.
    Keep the final answer under 6 lines unless the user asks for detail.
    """
    }
}

struct Harness {
    var environment: [String: String] = AppEnvironment.load()
    var debug = false
    var verbose = false

    func answer(question: String, allowsSearch: Bool) async throws -> String {
        var output = ""
        try await streamAnswer(question: question, allowsSearch: allowsSearch) { delta in
            output += delta
        }
        return output
    }

    func streamAnswer(question: String, allowsSearch: Bool, onDelta: (String) async -> Void) async throws {
        switch SystemLanguageModel.default.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw HMError.modelUnavailable(Diagnostics.describe(reason))
        @unknown default:
            throw HMError.modelUnavailable("unknown reason.")
        }

        let tavilyClient = TavilyClient(apiKey: environment["TAVILY_API_KEY"])
        let searchEnabled = allowsSearch && tavilyClient.isConfigured

        if searchEnabled && SearchRouter.shouldSearch(question) {
            if debug {
                fputs("hm: routing directly to Tavily search\n", stderr)
            }

            let searchResult = try await tavilyClient.search(query: SearchRouter.query(from: question))
            try await answerWithSearchContext(question: question, searchResult: searchResult, onDelta: onDelta)
            return
        }

        let tools: [any Tool] = searchEnabled ? [TavilySearchTool(client: tavilyClient)] : []

        if debug {
            let searchStatus = searchEnabled ? "enabled" : "disabled"
            fputs("hm: asking local model with \(tools.count) tool(s); search \(searchStatus)\n", stderr)
        }

        let session = LanguageModelSession(tools: tools, instructions: PromptDefaults.instructions(verbose: verbose))
        try await stream(session: session, prompt: question, onDelta: onDelta)
    }

    private func answerWithSearchContext(
        question: String,
        searchResult: TavilySearchResult,
        onDelta: (String) async -> Void
    ) async throws {
        let prompt = """
        Answer the user's question using the web search context.
        Be concise. Include source URLs that support the answer.

        User question:
        \(question)

        Web search context:
        \(searchResult.promptText)
        """

        let session = LanguageModelSession(instructions: PromptDefaults.instructions(verbose: verbose))
        try await stream(session: session, prompt: prompt, onDelta: onDelta)
    }

    private func stream(session: LanguageModelSession, prompt: String, onDelta: (String) async -> Void) async throws {
        var renderer = StreamingMarkdownRenderer()
        var rawPrefix = ""

        for try await snapshot in session.streamResponse(to: prompt) {
            let raw = String(snapshot.content)

            guard raw.count >= rawPrefix.count else {
                rawPrefix = raw
                continue
            }

            let deltaStart = raw.index(raw.startIndex, offsetBy: rawPrefix.count)
            let rawDelta = String(raw[deltaStart...])
            let delta = renderer.render(rawDelta)

            if !delta.isEmpty {
                await onDelta(delta)
            }

            rawPrefix = raw
        }

        let finalDelta = renderer.finish()
        if !finalDelta.isEmpty {
            await onDelta(finalDelta)
        }
    }
}

enum HMError: Error, CustomStringConvertible {
    case modelUnavailable(String)

    var description: String {
        switch self {
        case .modelUnavailable(let reason):
            return "Apple on-device model is unavailable: \(reason)"
        }
    }
}
