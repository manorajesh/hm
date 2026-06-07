import Foundation

struct TerminalMarkdownRenderer {
    func render(_ markdown: String) -> String {
        let withoutANSIEscapes = stripANSIEscapes(markdown)

        var inCodeFence = false
        var renderedLines: [String] = []

        for line in withoutANSIEscapes.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inCodeFence.toggle()
                continue
            }

            if inCodeFence {
                renderedLines.append(line)
                continue
            }

            renderedLines.append(renderInlineMarkdown(renderBlockMarkdown(line)))
        }

        return renderedLines.joined(separator: "\n")
    }

    func stripANSIEscapes(_ input: String) -> String {
        var output = ""
        var index = input.startIndex

        while index < input.endIndex {
            let character = input[index]

            guard character == "\u{001B}" else {
                output.append(character)
                index = input.index(after: index)
                continue
            }

            let next = input.index(after: index)
            guard next < input.endIndex, input[next] == "[" else {
                index = next
                continue
            }

            index = input.index(after: next)

            while index < input.endIndex {
                let scalar = input[index].unicodeScalars.first?.value ?? 0
                let isFinalByte = scalar >= 0x40 && scalar <= 0x7E
                index = input.index(after: index)

                if isFinalByte {
                    break
                }
            }
        }

        return output
    }

    private func renderBlockMarkdown(_ line: String) -> String {
        var output = line

        output = output.replacingOccurrences(
            of: #"^\s{0,3}#{1,6}\s+"#,
            with: "",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"^\s{0,3}>\s?"#,
            with: "",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"^\s{0,3}([-*_]){3,}\s*$"#,
            with: "",
            options: .regularExpression
        )

        return output
    }

    private func renderInlineMarkdown(_ line: String) -> String {
        var output = line

        output = output.replacingOccurrences(
            of: #"`([^`]+)`"#,
            with: "$1",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"\*\*([^*]+)\*\*"#,
            with: "$1",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"__([^_]+)__"#,
            with: "$1",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"\*([^*\n]+)\*"#,
            with: "$1",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"_([^_\n]+)_"#,
            with: "$1",
            options: .regularExpression
        )

        output = output.replacingOccurrences(
            of: #"\[([^\]]+)\]\(([^)]+)\)"#,
            with: "$1 ($2)",
            options: .regularExpression
        )

        return output
    }
}

struct StreamingMarkdownRenderer {
    private enum LineState {
        case lineStart
        case normal
        case suppressFenceLine
    }

    private var inCodeFence = false
    private var lineState = LineState.lineStart
    private var pendingLineStart = ""
    private let baseRenderer = TerminalMarkdownRenderer()

    mutating func render(_ markdownDelta: String) -> String {
        var output = ""
        let cleanDelta = baseRenderer.stripANSIEscapes(markdownDelta)

        for character in cleanDelta {
            output += consume(character)
        }

        return output
    }

    mutating func finish() -> String {
        defer {
            pendingLineStart = ""
            lineState = .lineStart
        }

        guard lineState != .suppressFenceLine else {
            return ""
        }

        return pendingLineStart
    }

    private mutating func consume(_ character: Character) -> String {
        switch lineState {
        case .suppressFenceLine:
            if character == "\n" {
                lineState = .lineStart
            }
            return ""
        case .normal:
            if character == "\n" {
                lineState = .lineStart
            }
            return String(character)
        case .lineStart:
            return consumeAtLineStart(character)
        }
    }

    private mutating func consumeAtLineStart(_ character: Character) -> String {
        if character == "\n" {
            pendingLineStart = ""
            return "\n"
        }

        pendingLineStart.append(character)

        let trimmed = pendingLineStart.trimmingCharacters(in: .whitespaces)

        if trimmed == "```" || trimmed == "~~~" {
            inCodeFence.toggle()
            lineState = .suppressFenceLine
            pendingLineStart = ""
            return ""
        }

        if canStillBecomeFencePrefix(trimmed) {
            return ""
        }

        let output = pendingLineStart
        pendingLineStart = ""
        lineState = .normal
        return output
    }

    private func canStillBecomeFencePrefix(_ text: String) -> Bool {
        if text.isEmpty {
            return true
        }

        return "```".hasPrefix(text) || "~~~".hasPrefix(text)
    }
}
