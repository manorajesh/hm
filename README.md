# hm

[![Build](../../actions/workflows/build.yml/badge.svg)](../../actions/workflows/build.yml)

help me - answer a quick question

## Usage

```sh
.build/release/hm how do I set remote origin on a repo correctly
.build/release/hm --no-search what does git reset --soft HEAD~1 do
echo "error output" | .build/release/hm what is wrong
.build/release/hm --check
```

Useful flags:

```sh
.build/release/hm --verbose explain git remote origin
.build/release/hm --no-typewriter what does git reset soft do
.build/release/hm --typewriter-delay=3 what does git reset soft do
```

## Requirements

- macOS 26 or newer
- Apple Silicon Mac
- Apple Intelligence enabled
- Xcode / command line tools with the `FoundationModels` SDK
- `TAVILY_API_KEY` for optional web search

## Search

Web search is disabled unless `TAVILY_API_KEY` is set in the environment, `.env`, or `~/.hm.env`:

```sh
TAVILY_API_KEY=tvly-your-key
```

Search is conservative: use phrases like `search the web`, `look up`, `latest`, `current`, or `today` when you want fresh results.

## Build

```sh
swift build -c release
swift test
```

## License

MIT
