# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyRecaLLM is a multi-platform SwiftUI app (iOS, iPadOS, macOS, visionOS) for LLM-assisted recall — storing questions organized by Category → Topic → SubTopic → Question, and generating answers via on-device or local LLMs. Targets iOS/macOS/visionOS 26.5+.

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

### Data model

Four `@Model` classes form a strict hierarchy with cascade-delete relationships and inverse back-references:

- **`Category`** (`Models/Category.swift`) — root. `topics: [Topic]?` cascade.
- **`Topic`** (`Models/Topic.swift`) — back-ref `category: Category?`, `subTopics: [SubTopic]?` cascade.
- **`SubTopic`** (`Models/SubTopic.swift`) — back-ref `topic: Topic?`, `questions: [Item]?` cascade.
- **`Item`** (`Models/Item.swift`) — the question/answer leaf. Fields: `timestamp`, `question`, `generatedAnswer`, `userAnswer`, recall metadata. Back-ref `subTopic: SubTopic?`.

All four also conform to `Codable` for import/export. The `ModelContainer` is configured in `MyRecaLLMApp` and injected into the view hierarchy.

### View hierarchy & navigation

A single `NavigationStack` is rooted in `CategoryView`; every deeper screen is a navigation destination pushed onto that stack — same on iPhone, iPad, Mac, and Vision Pro (no `NavigationSplitView`, no iPad sidebar, no platform-specific layout). Each list-level view operates on the parent model passed in via `@Bindable`:

- **`CategoryView`** — root, `@Query` for all `[Category]`. Pushes `TopicView(category:)`.
- **`TopicView(category: Category)`** — pushes `SubTopicView(topic:)`.
- **`SubTopicView(topic: Topic)`** — pushes `QuestionListView(subTopic:)`.
- **`QuestionListView(subTopic: SubTopic)`** — pushes `ItemDetailView(item:)`.
- **`ItemDetailView(item: Item)`** — leaf detail.

Note the naming gotcha: `SubTopicView` lists subtopics inside a topic; the (renamed) `QuestionListView` lists items inside a subtopic. The original `SubTopicView`-as-question-list was renamed during a cleanup.

### Add* sheets

Each list view presents its own creation sheet via `@State showingAddX` + `.sheet(isPresented:)`:

- `AddCategoryView()`, `AddTopicView(category:)`, `AddSubTopicView(topic:)`, `AddItemView(subTopic:)`.

All four follow the same shape: a `NavigationStack` wrapping a grouped `Form` with Title/Subtitle fields, a Cancel toolbar item (`.cancellationAction`), and a Save toolbar item (`.confirmationAction`) disabled when `trimmedTitle.isEmpty`. Save sets the parent relationship and `modelContext.insert(...)` before `dismiss()`.

### List view conventions (Category/Topic/SubTopic/QuestionList)

All four list views share a common shape:

- `List(selection: $selection)` where `selection: Set<PersistentIdentifier>`. Each row is `.tag(model.persistentModelID)`.
- A leading **Path** section (breadcrumb `LabeledContent("Category", value: …)` rows showing ancestry; `CategoryView` shows just `Text("Categories")`).
- A trailing items section titled "Categories" / "Topics" / "SubTopics" / "Questions".
- Both section headers use `Text(...).font(.headline)` for visual prominence (overrides SwiftUI's default greyed-uppercased section caption).
- Multi-select **Edit/Done** toggle in the toolbar that flips `@State private var isEditing` and clears `selection` on exit. While editing, the **Add X** button is disabled and a destructive **Delete** button appears (disabled until `!selection.isEmpty`).
- `.environment(\.editMode, .constant(isEditing ? .active : .inactive))` wrapped in `#if os(iOS) || os(visionOS)` — required to make iOS/visionOS show selection checkboxes; macOS uses native cmd/shift-click multi-select instead and that env key is iOS-only.
- The "Add X" toolbar buttons use `.buttonStyle(.glass)` with text labels ("Add Category", "Add Topic", "Add SubTopic", "Add Question").
- The existing `.onDelete(perform:)` swipe-to-delete is preserved alongside the multi-select bulk delete.

### Toolbar placement

Cross-platform list views use `.navigation` and `.primaryAction` for toolbar groups (these resolve to leading/trailing on iOS, leading/trailing on macOS). `QuestionListView` puts both Edit/Done and Add Question on `.primaryAction`. **Avoid `.topBarLeading` / `.topBarTrailing`** — they're iOS-only and will fail macOS compilation. (`CategoryView` currently uses `.topBarTrailing` per a user edit; that file won't build for macOS until those are switched to `.navigation` / `.primaryAction`.)

### Bottom GlassEffectContainer

`CategoryView` and `SubTopicView` host a bottom `GlassEffectContainer` (anchored under the list via `Spacer()` in a parent `VStack`) with a TBD / Download / Upload triplet. Each button uses `.buttonStyle(.glass)` with green/blue tints, and the container has `.tint(.red)`. Download/Upload are placeholders for future import/export.

### Item detail

**`ItemDetailView`** (`Views/ItemDetailView.swift`, module-internal): a grouped `Form` with sections — **Path** (Category / Topic / SubTopic breadcrumb), **Created** (timestamp), **LLM** (selected provider + model), **Question** (editable multi-line `TextField`), **Generated Answer** (read-only, text-selectable), and an inline error section. Bottom-anchored via `.safeAreaInset(edge: .bottom)`: a `GlassEffectContainer` with a primary `.glassProminent` Answer button (shows a `ProgressView` while generating; disabled when generating or when the trimmed question is empty) and a secondary `.glassProminent` LLM button that presents `LLMSettingsView` as a sheet. `makeProvider()` reads the `@AppStorage` values directly per case to construct the right provider.

### LLM settings

**`LLMSettingsView`** (`Views/LLMSettingsView.swift`, module-internal): owns the provider segmented `Picker`, the server URL `TextField`, and the model `Picker` populated by fetching `{baseURL}/v1/models`. State is shared with `ItemDetailView` via `@AppStorage` keys (`answerProvider`, `swama.baseURL`, `swama.model`, `ollama.baseURL`, `ollama.model`). A `task(id:)` re-fetches the model list when the provider or URL changes. The view is wrapped in its own `NavigationStack` with a Done button (`.confirmationAction`).

### Answer providers

**Answer providers** (`Services/AnswerProviders.swift`): `AnswerProvider` protocol (`answer(prompt:) async throws -> String`) with two concrete implementations:

- `FoundationModelsProvider` — wraps `LanguageModelSession.respond(to:)` from the `FoundationModels` framework; requires Apple Intelligence to be enabled on-device; available on all platforms.
- `OpenAICompatibleProvider` — single struct used for both Swama and Ollama since both expose OpenAI-compatible `/v1/chat/completions` and `/v1/models` endpoints. Cross-platform (iOS, macOS, visionOS) — uses `URLSession` only, no platform-specific APIs.

`AnswerProviderID` enum (`.foundationModels`, `.swama`, `.ollama`) drives provider selection. `available` returns all three on every platform. Defaults: Swama at `http://127.0.0.1:28100`, Ollama at `http://127.0.0.1:11434`, both defaulting to model `llama3.2`. On iOS/visionOS the user must change the URL to a Mac LAN IP or `*.local` hostname — loopback won't reach the server.

### Liquid Glass UI

`GlassEffectContainer` + `.buttonStyle(.glass)` (or `.glassProminent` for primary actions) is the dominant visual style. Row affordances in lists also use `.glassEffect(.clear.tint(.blue).interactive(), in: .buttonBorder)` directly on the row label.

### Info.plist

`MyRecaLLM/Info.plist`: The app target uses a file-based Info.plist (`GENERATE_INFOPLIST_FILE = NO`, `INFOPLIST_FILE = MyRecaLLM/Info.plist`) rather than the auto-generated one, because `NSAppTransportSecurity` is a nested dict with no flat `INFOPLIST_KEY_*` equivalent. The file declares `NSAppTransportSecurity` → `NSAllowsLocalNetworking = YES` (lets iOS/visionOS reach a Mac on the LAN over plain HTTP) and `NSLocalNetworkUsageDescription` (required iOS 14+ permission string for local-network connections). Standard bundle keys use `$(VAR)` substitution. The file lives inside the synchronized source group; in Xcode the file's Target Membership for `MyRecaLLM` is unchecked so it isn't double-copied as a resource.

### macOS sandbox

`MyRecaLLM/MyRecaLLM.entitlements`: `com.apple.security.app-sandbox` + `com.apple.security.network.client` — required for outbound HTTP to Swama/Ollama servers (localhost on macOS, LAN on iOS/visionOS).

### Test frameworks

Unit tests use Swift Testing (`import Testing`, `@Test`, `#expect`). UI tests use XCTest/XCUIApplication.

## macOS code-signing gotcha

If the macOS build fails with `resource fork, Finder information, or similar detritus not allowed`, a source file (commonly an asset like `question.png`) was dragged in from Finder/web/AirDrop and carries `com.apple.FinderInfo`/`com.apple.quarantine` xattrs that codesign rejects. Fix:

```bash
xattr -cr MyRecaLLM/MyRecaLLM
```

Then clean and rebuild. Signing is configured for ad-hoc local signing (`CODE_SIGN_IDENTITY = -`, "Sign to Run Locally") which is fine for running on the build Mac; switch to the Developer ID team for distribution.

## Key Constraints

- Targets iOS/iPadOS/macOS/visionOS 26.5 — use only APIs available on these versions.
- Prefer async/await and actors for any networking or LLM code; avoid Combine.
- Multi-platform first: new views must compile on all four platforms or use explicit platform conditionals (`#if os(...)`).
- Remote providers (Swama, Ollama) require their servers running locally: `swama serve` / `ollama serve`. iOS/visionOS clients must point at the Mac's LAN IP or `*.local` hostname; the Mac firewall must allow inbound connections on the chosen port.
