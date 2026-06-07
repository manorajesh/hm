import Foundation
import FoundationModels

@main
struct HM {
    static func main() async {
        exit(await run())
    }

    private static func run() async -> Int32 {
        let stdin = CLIParser.readStandardInputIfAvailable()
        let options = CLIParser.parse(arguments: Array(CommandLine.arguments.dropFirst()), stdin: stdin)

        switch options.mode {
        case .help:
            printUsage()
            return ExitCode.ok
        case .check:
            return check(environment: AppEnvironment.load())
        case .ask:
            break
        }

        guard !options.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fputs("hm: missing question\n\n", stderr)
            printUsage(to: stderr)
            return ExitCode.usage
        }

        do {
            let harness = Harness(debug: options.debug, verbose: options.verbose)
            let output = TypewriterOutput(delayMilliseconds: options.typewriterDelayMilliseconds)
            try await harness.streamAnswer(question: options.question, allowsSearch: options.allowsSearch) { delta in
                await output.write(delta)
            }
            await output.finishLine()
            return ExitCode.ok
        } catch let error as HMError {
            fputs("hm: \(error.description)\n", stderr)
            return ExitCode.unavailable
        } catch let error as TavilyError {
            fputs("hm: \(error.description)\n", stderr)
            return ExitCode.generalError
        } catch {
            fputs("hm: model request failed: \(Diagnostics.describeGenerationError(error))\n", stderr)
            return ExitCode.generalError
        }
    }

    private static func check(environment: [String: String]) -> Int32 {
        var code = ExitCode.ok

        switch SystemLanguageModel.default.availability {
        case .available:
            print("apple: available")
        case .unavailable(let reason):
            print("apple: unavailable: \(Diagnostics.describe(reason))")
            code = ExitCode.unavailable
        @unknown default:
            print("apple: unavailable: unknown reason.")
            code = ExitCode.unavailable
        }

        if TavilyClient(apiKey: environment["TAVILY_API_KEY"]).isConfigured {
            print("tavily: configured")
        } else {
            print("tavily: disabled")
        }

        return code
    }

    private static func printUsage(to stream: UnsafeMutablePointer<FILE> = stdout) {
        fputs("""
        usage:
          hm what git command undoes the last commit but keeps changes
          hm --no-search what does git reset --soft HEAD~1 do
          hm --verbose how do I set remote origin on a repo correctly
          hm --no-typewriter what does git reset --soft HEAD~1 do
          hm --typewriter-delay=3 what does git reset --soft HEAD~1 do
          echo "error output..." | hm what is wrong
          hm --check

        Aliases:
          alias '?'='hm'
          ln -sf /path/to/hm ~/bin/helpme

        Uses Apple's on-device Foundation Models framework. Web search uses
        Tavily when TAVILY_API_KEY is set in the environment, .env, or ~/.hm.env.

        """, stream)
    }
}
