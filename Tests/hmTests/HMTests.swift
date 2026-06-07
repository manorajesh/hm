import Testing
@testable import hm

@Test func parserJoinsUnquotedPromptArguments() {
    let options = CLIParser.parse(arguments: ["what", "is", "this", "error", "code"], stdin: nil)

    #expect(options.mode == .ask)
    #expect(options.question == "what is this error code")
}

@Test func parserCombinesPromptAndStdinContext() {
    let options = CLIParser.parse(arguments: ["what", "is", "wrong"], stdin: "error output")

    #expect(options.question.contains("what is wrong"))
    #expect(options.question.contains("Context:"))
    #expect(options.question.contains("error output"))
}

@Test func noSearchFlagDisablesSearch() {
    let options = CLIParser.parse(arguments: ["--no-search", "latest", "node", "version"], stdin: nil)

    #expect(options.allowsSearch == false)
    #expect(options.question == "latest node version")
}

@Test func typewriterFlagsAreParsedAndExcludedFromPrompt() {
    let disabled = CLIParser.parse(arguments: ["--no-typewriter", "say", "hello"], stdin: nil)
    let custom = CLIParser.parse(arguments: ["--typewriter-delay=3", "say", "hello"], stdin: nil)

    #expect(disabled.typewriterDelayMilliseconds == 0)
    #expect(disabled.question == "say hello")
    #expect(custom.typewriterDelayMilliseconds == 3)
    #expect(custom.question == "say hello")
}

@Test func verboseFlagIsParsedAndExcludedFromPrompt() {
    let options = CLIParser.parse(arguments: ["--verbose", "explain", "git", "remote"], stdin: nil)

    #expect(options.verbose)
    #expect(options.question == "explain git remote")
}

@Test func freshnessRouterDetectsCurrentQuestions() {
    #expect(SearchRouter.shouldSearch("what is the latest pnpm version"))
    #expect(SearchRouter.shouldSearch("look up the current git docs for worktree"))
    #expect(SearchRouter.shouldSearch("search the web for swift foundationmodels examples"))
    #expect(!SearchRouter.shouldSearch("what does git reset soft do"))
    #expect(!SearchRouter.shouldSearch("what version command shows node version"))
    #expect(!SearchRouter.shouldSearch("how do I use the github api from curl"))
    #expect(!SearchRouter.shouldSearch("where are git docs installed locally"))
}

@Test func dotenvParserReadsTavilyKeyAndIgnoresComments() {
    let values = AppEnvironment.parseDotEnv("""
    # comment
    export TAVILY_API_KEY="tvly-test"
    OTHER=value
    """)

    #expect(values["TAVILY_API_KEY"] == "tvly-test")
    #expect(values["OTHER"] == "value")
}

@Test func tavilyClientConfigurationReflectsKeyPresence() {
    #expect(TavilyClient(apiKey: "tvly-test").isConfigured)
    #expect(!TavilyClient(apiKey: "").isConfigured)
    #expect(!TavilyClient(apiKey: nil).isConfigured)
}

@Test func terminalRendererRemovesNoisyMarkdownAndANSIEscapes() {
    let renderer = TerminalMarkdownRenderer()
    let rendered = renderer.render("""
    \u{001B}[31m# Title\u{001B}[0m
    Use `git status` and **read** [docs](https://example.com).
    ```sh
    git status
    ```
    """)

    #expect(rendered.contains("Title"))
    #expect(rendered.contains("Use git status and read docs (https://example.com)."))
    #expect(rendered.contains("git status"))
    #expect(!rendered.contains("\u{001B}"))
    #expect(!rendered.contains("```"))
}

@Test func streamingRendererDoesNotRewritePartialMarkdown() {
    var renderer = StreamingMarkdownRenderer()
    let first = renderer.render("**So")
    let second = renderer.render("urce")
    let third = renderer.render(":** docs")
    let final = renderer.finish()

    #expect(first + second + third + final == "**Source:** docs")
}

@Test func streamingRendererSuppressesSplitCodeFencesAndPreservesCode() {
    var renderer = StreamingMarkdownRenderer()
    let chunks = [
        "Use:\n\n`",
        "``ba",
        "sh\n",
        "git remote add origin git@github.com:yourusername/yourrepo.git\n",
        "``",
        "`\nDone."
    ]

    let rendered = chunks.map { renderer.render($0) }.joined() + renderer.finish()

    #expect(rendered.contains("Use:"))
    #expect(rendered.contains("git remote add origin git@github.com:yourusername/yourrepo.git"))
    #expect(rendered.contains("Done."))
    #expect(!rendered.contains("```"))
    #expect(!rendered.contains("bash"))
}
