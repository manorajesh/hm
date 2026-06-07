import Foundation

struct CLIOptions: Equatable {
    var mode: CLIMode = .ask
    var allowsSearch = true
    var debug = false
    var verbose = false
    var typewriterDelayMilliseconds = 8
    var question = ""
}

enum CLIMode: Equatable {
    case ask
    case check
    case help
}

enum CLIParser {
    static func parse(arguments: [String], stdin: String?) -> CLIOptions {
        var options = CLIOptions()
        var questionParts: [String] = []

        for argument in arguments {
            switch argument {
            case "--help", "-h":
                options.mode = .help
            case "--check":
                options.mode = .check
            case "--no-search":
                options.allowsSearch = false
            case "--debug":
                options.debug = true
            case "--verbose":
                options.verbose = true
            case "--no-typewriter":
                options.typewriterDelayMilliseconds = 0
            default:
                if argument.hasPrefix("--typewriter-delay=") {
                    let value = String(argument.dropFirst("--typewriter-delay=".count))
                    if let delay = Int(value), delay >= 0 {
                        options.typewriterDelayMilliseconds = delay
                    }
                } else {
                    questionParts.append(argument)
                }
            }
        }

        options.question = buildQuestion(arguments: questionParts, stdin: stdin)
        return options
    }

    private static func buildQuestion(arguments: [String], stdin: String?) -> String {
        let argQuestion = arguments.joined(separator: " ")

        guard let stdin, !stdin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return argQuestion
        }

        if argQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return stdin
        }

        return """
        \(argQuestion)

        Context:
        \(stdin)
        """
    }

    static func readStandardInputIfAvailable() -> String? {
        let stdin = FileHandle.standardInput

        guard isatty(stdin.fileDescriptor) == 0 else {
            return nil
        }

        let data = stdin.readDataToEndOfFile()
        guard !data.isEmpty else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}
