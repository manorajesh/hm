# hm

[![Build](../../actions/workflows/build.yml/badge.svg)](../../actions/workflows/build.yml)

help me - answer a quick question

## Usage

```sh
hm how do I set remote origin on a repo correctly
hm --no-search what does git reset --soft HEAD~1 do
echo "error output" | hm what is wrong
hm --check
```

Useful flags:

```sh
hm --verbose explain git remote origin
hm --no-typewriter what does git reset soft do
hm --typewriter-delay=3 what does git reset soft do
```

## Requirements

- macOS 26 or newer
- Apple Silicon Mac
- Apple Intelligence enabled
- Xcode / command line tools with the `FoundationModels` SDK
- `TAVILY_API_KEY` for web search

## Build

```sh
swift build -c release
swift test
```

Install locally:

```sh
cp .build/release/hm ~/.local/bin/hm
ln -sf ~/.local/bin/hm ~/.local/bin/helpme
alias '?'='hm'
```

## License

MIT
