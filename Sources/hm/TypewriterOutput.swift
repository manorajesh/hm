import Foundation

actor TypewriterOutput {
    private let delay: Duration

    init(delayMilliseconds: Int) {
        self.delay = .milliseconds(delayMilliseconds)
    }

    func write(_ text: String) async {
        guard delay > .zero else {
            fputs(text, stdout)
            fflush(stdout)
            return
        }

        for character in text {
            fputs(String(character), stdout)
            fflush(stdout)

            if character != "\n" {
                try? await Task.sleep(for: delay)
            }
        }
    }

    func finishLine() {
        fputs("\n", stdout)
        fflush(stdout)
    }
}
