# MyRecaLLM

A multi-platform SwiftUI app (iOS, macOS, visionOS) for LLM-assisted recall. Store questions and generate answers using Apple Intelligence, Swama, or Ollama.

Requires iOS/macOS/visionOS 26.5 or later.

## Features

- Save questions with SwiftData persistence
- Generate answers via:
  - **Apple Intelligence** — on-device, via the `FoundationModels` framework (all platforms)
  - **Swama** — local OpenAI-compatible server (macOS only)
  - **Ollama** — local OpenAI-compatible server (macOS only)
- Per-provider base URL and model selection, persisted across launches
- Automatic model list fetch from running local servers

## Requirements

- Xcode 26.5+
- For Apple Intelligence: Apple Intelligence enabled on the device/Mac
- For Swama: [`swama`](https://github.com/tattn/swama) installed and `swama serve` running
- For Ollama: [`ollama`](https://ollama.com) installed and `ollama serve` running, with at least one model pulled (e.g. `ollama pull llama3.2`)

## Build

```bash
# macOS
xcodebuild -project MyRecaLLM.xcodeproj -scheme MyRecaLLM -destination 'platform=macOS' build

# iOS Simulator
xcodebuild -project MyRecaLLM.xcodeproj -scheme MyRecaLLM -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Tests

```bash
xcodebuild test -project MyRecaLLM.xcodeproj -scheme MyRecaLLM -destination 'platform=macOS'
```
