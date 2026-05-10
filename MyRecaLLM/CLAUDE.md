# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyRecaLLM is a multi-platform SwiftUI app (iOS, macOS, visionOS) for LLM-assisted recall — storing questions and generating answers via on-device or local LLMs. Targets iOS/macOS/visionOS 26.5+.

## Build & Test Commands

```bash
# Build for macOS
xcodebuild -project MyRecaLLM.xcodeproj -scheme MyRecaLLM -destination 'platform=macOS' build

# Build for iOS Simulator
xcodebuild -project MyRecaLLM.xcodeproj -scheme MyRecaLLM -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run unit tests
xcodebuild test -project MyRecaLLM.xcodeproj -scheme MyRecaLLM -destination 'platform=macOS'

# Run a single test (Swift Testing)
xcodebuild test -project MyRecaLLM.xcodeproj -scheme MyRecaLLM -destination 'platform=macOS' -only-testing MyRecaLLMTests/MyRecaLLMTests/example
```

## Architecture

**SwiftData model** (`Models/Item.swift`): `@Model` class `Item` with `timestamp`, `question`, and `generatedAnswer` fields. `ModelContainer` is configured in `MyRecaLLMApp` and injected into the view hierarchy.

**Answer providers** (`Services/AnswerProviders.swift`): `AnswerProvider` protocol (`answer(prompt:) async throws -> String`) with two concrete implementations:
- `FoundationModelsProvider` — wraps `LanguageModelSession.respond(to:)` from the `FoundationModels` framework; requires Apple Intelligence to be enabled on-device; available on all platforms.
- `OpenAICompatibleProvider` — single struct used for both Swama and Ollama since both expose OpenAI-compatible `/v1/chat/completions` and `/v1/models` endpoints. Cross-platform (iOS, macOS, visionOS) — uses `URLSession` only, no platform-specific APIs.

`AnswerProviderID` enum (`.foundationModels`, `.swama`, `.ollama`) drives provider selection. `available` returns all three on every platform. Defaults: Swama at `http://127.0.0.1:28100`, Ollama at `http://127.0.0.1:11434`, both defaulting to model `llama3.2`. On iOS/visionOS the user must change the URL to a Mac LAN IP or `*.local` hostname — loopback won't reach the server.

**`ItemDetailView`** (`Views/ItemDetailView.swift`, module-internal so `ContentView` can reference it): renders the timestamp, an editable multi-line `TextField` for the question, the read-only `Generated Answer` section, and the bottom answer button. An **LLM** toolbar button (`.primaryAction`) presents `LLMSettingsView` as a sheet. `makeProvider()` reads the `@AppStorage` values directly per case to construct the right provider.

**`LLMSettingsView`** (`Views/LLMSettingsView.swift`, module-internal so `ItemDetailView` can reference it): owns the provider segmented `Picker`, the server URL `TextField`, and the model `Picker` populated by fetching `{baseURL}/v1/models`. State is shared with `ItemDetailView` via `@AppStorage` keys (`answerProvider`, `swama.baseURL`, `swama.model`, `ollama.baseURL`, `ollama.model`). A `task(id:)` re-fetches the model list when the provider or URL changes. The view is wrapped in its own `NavigationStack` with a Done button (`.confirmationAction`).

**Cross-platform navigation**: `NavigationViewWrapper` switches between `NavigationSplitView` (macOS) and `NavigationStack` (iOS/visionOS). Platform guards (`#if os(macOS)` / `#if os(iOS)`) handle toolbar placement and column sizing.

**Liquid Glass UI**: The detail view's answer button uses `GlassEffectContainer` + `.buttonStyle(.glassProminent)` anchored via `.safeAreaInset(edge: .bottom)`.

**Info.plist** (`MyRecaLLM/Info.plist`): The app target uses a file-based Info.plist (`GENERATE_INFOPLIST_FILE = NO`, `INFOPLIST_FILE = MyRecaLLM/Info.plist`) rather than the auto-generated one, because `NSAppTransportSecurity` is a nested dict with no flat `INFOPLIST_KEY_*` equivalent. The file declares `NSAppTransportSecurity` → `NSAllowsLocalNetworking = YES` (lets iOS/visionOS reach a Mac on the LAN over plain HTTP) and `NSLocalNetworkUsageDescription` (required iOS 14+ permission string for local-network connections). Standard bundle keys use `$(VAR)` substitution (`PRODUCT_BUNDLE_IDENTIFIER`, `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`, etc.). The file lives inside the synchronized source group; in Xcode the file's Target Membership for `MyRecaLLM` is unchecked so it isn't double-copied as a resource.

**macOS sandbox** (`MyRecaLLM/MyRecaLLM.entitlements`): `com.apple.security.app-sandbox` + `com.apple.security.network.client` — required for outbound HTTP to Swama/Ollama servers (localhost on macOS, LAN on iOS/visionOS).

**Test frameworks**: Unit tests use Swift Testing (`import Testing`, `@Test`, `#expect`). UI tests use XCTest/XCUIApplication.

## Key Constraints

- Targets iOS/macOS/visionOS 26.5 — use only APIs available on these versions.
- Prefer async/await and actors for any networking or LLM code.
- Multi-platform first: new views must compile on all three platforms or use explicit platform conditionals.
- Remote providers (Swama, Ollama) require their servers running locally: `swama serve` / `ollama serve`. iOS/visionOS clients must point at the Mac's LAN IP or `*.local` hostname; the Mac firewall must allow inbound connections on the chosen port.
