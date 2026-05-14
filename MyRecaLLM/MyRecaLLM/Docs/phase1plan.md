# Phase 1 Plan — JSON Export (Local, No Server)

## Goal

Let the user save one or many `Category`, `Topic`, or `SubTopic` rows (each with all descendants) as a JSON file on disk using the system file exporter. No server uploads and downloads (import) in this phase yet. For now, store the files in ~/Documents/MyRecaLLM/

## Storage semantics (from user)

- Each stored unit on the (eventual) server will be an **individual** `Category`, `Topic`, or `SubTopic` — they are independently importable.
- It is **not** a requirement to extract a `Topic` (or `SubTopic`) from inside a stored `Category` or a `Topic`. If a `Topic` or `SubTopic` is later to be imported, it must have been *exported* as a top-level `Topic` / `SubTopic` in the first place.
- "Export all" at a given level therefore produces JSON files for each `Category`, `Topic` or `SubTopic`. The future importer will treat each element as one server-side record.
- Dates use **ISO-8601** strings.
- `generatedAnswer` is **kept** in the exported JSON — regenerating thousands of answers would be costly.

## What already helps us

All four `@Model` classes (`Category`, `Topic`, `SubTopic`, `Item`) already conform to `Codable`, and their `encode(to:)` implementations already:

- Include the forward children (`topics`, `subTopics`, `questions`).
- Omit the back-reference (`category` on `Topic`, `topic` on `SubTopic`, `subTopic` on `Item`) from the *encoded* JSON, which prevents circular references when a child is encoded inside its parent's children array. The back-references are re-established on import (see Step 1).

So encoding a `Category` already cascades the full subtree as a tree-shaped JSON object — we don't need to invent a new serialization, just wrap it in an envelope and write it through `RecallFileStore`.

## Step 1 — Audit Codable conformance and back-reference handling

For each model, confirm `encode(to:)` writes every field that `init(from:)` reads, and round-tripping a tree through `JSONEncoder` → `JSONDecoder` produces an equivalent object graph. Specifically:

- `Item.encode` already writes `generatedAnswer` and `userAnswer` — good, matches the requirement to retain answers.
- `Topic.init(from:)` does not decode the `category` back-ref. Correct for a subtree; the link is re-established on import via SwiftData's inverse-relationship handling when the parent `Category` is inserted with its decoded `topics` array (or set explicitly by the importer if needed).
- `SubTopic.init(from:)` does not decode the `topic` back-ref. Same rationale.
- **`Item.init(from:)` — back-ref handling needs attention.** Items must remain attached to their `SubTopic`. The plan:
  - `Item.encode(to:)` deliberately keeps omitting `subTopic` — encoding it would produce a cycle when the Item is serialized inside its parent `SubTopic.questions` array.
  - `Item.init(from:)` should `decodeIfPresent(SubTopic.self, forKey: .subTopic)` so the field is read if ever present in JSON (forward-compatible for a future standalone-Item export shape). For phase-1 tree imports the field isn't in the JSON and `subTopic` decodes to `nil`.
  - On import (phase 2), the back-ref must end up set on every Item. The standard path is SwiftData's inverse-relationship handling — when the decoded `SubTopic` is inserted with its `questions` array populated, each `item.subTopic` is filled in automatically. If that proves unreliable in practice, the importer can set `item.subTopic = subTopic` explicitly during the insert loop.
  - A future `ItemUpdateView` may let the user reassign an Item to a different `SubTopic` by mutating `item.subTopic` directly. The field is already a mutable `var`, so no further model surgery is required.

If any other field is missing on encode/decode, fix it here before relying on the existing conformance.

## Step 2 — Add `Services/ExportService.swift`

A new file under `Services/` (sibling of `AnswerProviders.swift`) defining:

### Envelope

```
RecallExportEnvelope<T: Codable>
  version: Int            // 1
  exportedAt: Date        // ISO-8601 via encoder strategy
  kind: Kind              // .category | .topic | .subTopic
  item: T                 // a single independently-importable unit
```

One file = one unit. `kind` tells the future importer whether the `item` is a `Category`, `Topic`, or `SubTopic`. Multi-select export simply writes N files, each containing one unit.

### Encoder configuration

A shared, internal `JSONEncoder` factory:

- `outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]` — stable diffs and human-readable.
- `dateEncodingStrategy = .iso8601` — per user request.

### API

```swift
enum ExportService {
    static func encode(category: Category) throws -> Data
    static func encode(topic: Topic) throws -> Data
    static func encode(subTopic: SubTopic) throws -> Data

    static func defaultFilename(kind: RecallExportEnvelope.Kind, title: String) -> String
}
```

Each call produces a single-unit envelope (one `Category` / `Topic` / `SubTopic` per file). Multi-select export writes N files, each holding one unit, into `~/Documents/MyRecaLLM/`.

`defaultFilename` example: `MyRecaLLM-category-Swift-2026-05-14.json` (title is slugified — non-alphanumerics replaced with `-`, collapsed runs, trimmed).

## Step 3 — Add a `RecallFileStore` (writes to `~/Documents/MyRecaLLM/`)

Because phase 1 always writes to the app's sandboxed Documents directory (not a user-chosen location), we don't need `FileDocument` / `.fileExporter`. A small `RecallFileStore` is enough:

```swift
enum RecallFileStore {
    static func exportDirectory() throws -> URL    // ~/Documents/MyRecaLLM/, created if missing
    static func write(_ data: Data, filename: String) throws -> URL
    static func listExportedFiles() throws -> [URL] // for ImportView later
}
```

Implementation notes:

- `exportDirectory()` resolves `URL.documentsDirectory.appending(path: "MyRecaLLM", directoryHint: .isDirectory)` and creates it via `FileManager.default.createDirectory(at:withIntermediateDirectories:true)`.
- `write(_:filename:)` writes atomically (`.atomic`) and returns the resulting URL so the UI can show "Saved 3 files to …".
- If a target filename already exists, append ` (2)`, ` (3)`, … before the extension to avoid silent overwrite. (Important if the user exports the same category twice on the same day.)
- The same directory is what `ImportView` will read from in phase 2.

This works identically on iOS, iPadOS, macOS, and visionOS — the sandbox Documents directory exists on all four and is the recommended location for user-visible files.

## Step 4 — Dedicated `ExportView` and `ImportView`

Export and import are infrequent, side operations, so they live in their own dedicated views rather than cluttering the main list views. The main `CategoryView` / `TopicView` / `SubTopicView` get **no** new toolbar items, no Edit-mode Export button, and no extra row affordances. The only thing that changes in those views is the bottom-container button labels (see Step 5), which navigate to the dedicated views.

Two new views — same module-internal style as the existing list views:

### `Views/ExportView.swift`

Parameterized by the kind to export:

```swift
struct ExportView: View {
    enum Scope { case categories, topics(parent: Category), subTopics(parent: Topic) }
    let scope: Scope
}
```

UI shape mirrors the three main list views:

- A `List(selection: $selection)` with `selection: Set<PersistentIdentifier>` and `.tag(model.persistentModelID)` rows.
- Path breadcrumb section at the top (Category / Topic ancestry where applicable) — same `LabeledContent` rows used elsewhere.
- A trailing items section titled "Categories" / "Topics" / "SubTopics" depending on scope.
- Multi-select **Edit/Done** toolbar toggle and `.environment(\.editMode, …)` gated on iOS/visionOS — exactly like the existing list views.
- A primary action toolbar **Export Selected** button (`.glassProminent`), disabled when `selection.isEmpty`, that:
  1. Resolves the selection to concrete models from the scope's source array.
  2. For each selected unit, calls the matching `ExportService.encode(...)` and writes one file via `RecallFileStore.write(...)`.
  3. Reports the result inline (a brief "Exported N files to ~/Documents/MyRecaLLM/" status row or a small toast/section).

The data source per scope:

| Scope                  | Source                          |
|------------------------|---------------------------------|
| `.categories`          | `@Query` over `[Category]`      |
| `.topics(parent: c)`   | `c.topics ?? []`                |
| `.subTopics(parent: t)`| `t.subTopics ?? []`             |

### `Views/ImportView.swift`

Same shape as `ExportView`, but its list is sourced from `RecallFileStore.listExportedFiles()` filtered to the requested kind. Phase 1 stops at *listing* the files — actual ingestion into the SwiftData store is phase 2. The view should still render the list and a disabled **Import Selected** button so the navigation entry point is real and we can iterate on the UI without waiting on the importer.

### Help views

The three main list views each pair with a help view (`CategoryHelpView`, `TopicHelpView`, `SubTopicHelpView`, `QuestionHelpView`). Following the same convention, add:

- `Views/ExportHelpView.swift` — describes what gets exported at each scope, the file format and location (`~/Documents/MyRecaLLM/`), how multi-select translates to N files, and the slugified filename convention.
- `Views/ImportHelpView.swift` — describes which files `ImportView` looks at, the expected envelope format, and notes that the actual import action is phase 2.

Each help view follows the existing help-view shape (presented via the same affordance the other help views use — sheet or navigation push — whichever the existing ones use; mirror it exactly to stay consistent). `ExportView` and `ImportView` each gain the same Help entry point used by the main list views.

### Settings view (shared by Export and Import)

Both `ExportView` and `ImportView` need user/server settings so the phase-2 transfer code can run unchanged. Add a single shared settings view, modeled after `LLMSettingsView`:

- `Views/ExportImportSettingsView.swift` — its own `NavigationStack` wrapping a grouped `Form` with:
  - A **User** `TextField` bound to `@AppStorage("exportImport.user")`, default `"rob"`.
  - A **Server / Port** `TextField` bound to `@AppStorage("exportImport.serverURL")`, default `"https://Rob-Travel-M5.local:8085"`.
  - A Done toolbar button (`.confirmationAction`) that dismisses the sheet.

Presentation: each of `ExportView` and `ImportView` adds a toolbar **Settings** button (gear icon, `.buttonStyle(.glass)`) on `.primaryAction` that flips an `@State private var showingSettings = false` and `.sheet(isPresented:) { ExportImportSettingsView() }`. This matches how `ItemDetailView` reaches `LLMSettingsView`.

`@AppStorage` keys (centralized at the top of `ExportImportSettingsView` and re-read from `ExportView` / `ImportView` as needed):

```swift
@AppStorage("exportImport.user")      private var exportImportUser: String = "rob"
@AppStorage("exportImport.serverURL") private var exportImportServerURL: String = "https://Rob-Travel-M5.local:8085"
```

Phase-1 behavior: the values are only stored. No network code reads them yet. They become inputs to the phase-2 upload/download flow without further UI changes.

### Notes

- `QuestionListView` is **not** in scope for phase 1 — the user explicitly listed Category / Topic / SubTopic as the export units.
- The Path breadcrumb in scoped exports (`.topics(parent:)`, `.subTopics(parent:)`) ensures the user knows which subtree they're exporting from.
- Both views are reached only via the bottom Export / Import buttons described in Step 5 — they don't appear in the navigation hierarchy otherwise.

## Step 5 — Rename bottom-container buttons to Export / Import (navigation entry points only)

`CategoryView` and `SubTopicView` already host a bottom `GlassEffectContainer` with TBD / Download / Upload buttons. Add the same container to `TopicView` so all three list views are symmetric. Then in all three views:

- **Upload** → **Export**. Navigates to `ExportView` with the appropriate scope:
  - `CategoryView` → `ExportView(scope: .categories)`
  - `TopicView` → `ExportView(scope: .topics(parent: category))`
  - `SubTopicView` → `ExportView(scope: .subTopics(parent: topic))`
- **Download** → **Import**. Navigates to `ImportView` with the matching scope.
- **TBD** stays a placeholder for now.

Buttons keep the existing `.buttonStyle(.glass)` + tints styling. They are pure navigation pushes (`NavigationLink` or a programmatic `navigationDestination` flag) — no selection logic lives in the main list views. All selection, encoding, and file-writing happens inside `ExportView` / `ImportView`.

## Step 6 — Unit test

In `MyRecaLLMTests/MyRecaLLMTests.swift`, add a Swift Testing case:

1. Build an in-memory `ModelContainer` for `[Category.self, Topic.self, SubTopic.self, Item.self]`.
2. Insert one `Category` with a 2×2×3 subtree (2 topics, each with 2 subtopics, each with 3 questions).
3. Encode the `Category` via `ExportService.encode(category:)`.
4. Decode the envelope's `item` back into a `Category` and `#expect`:
   - `kind == .category` on the envelope.
   - `topics?.count == 2`.
   - Each subtopic's `questions?.count == 3`.
   - One `Item.generatedAnswer` round-trips a known string (proves answers are retained).
   - One `Date` field round-trips through the ISO-8601 strategy.
5. Repeat for `Topic` and `SubTopic` via the matching `encode(topic:)` / `encode(subTopic:)` entry points (smaller subtrees suffice).

This validates the end-to-end Codable contract without needing UI.

## Files this plan touches

| Action | Path |
|---|---|
| New    | `MyRecaLLM/MyRecaLLM/Services/ExportService.swift` |
| New    | `MyRecaLLM/MyRecaLLM/Services/RecallFileStore.swift` *(or folded into `ExportService.swift`)* |
| New    | `MyRecaLLM/MyRecaLLM/Views/ExportView.swift` |
| New    | `MyRecaLLM/MyRecaLLM/Views/ImportView.swift` |
| New    | `MyRecaLLM/MyRecaLLM/Views/ExportHelpView.swift` |
| New    | `MyRecaLLM/MyRecaLLM/Views/ImportHelpView.swift` |
| New    | `MyRecaLLM/MyRecaLLM/Views/ExportImportSettingsView.swift` |
| Edit   | `MyRecaLLM/MyRecaLLM/Models/Item.swift` *(add `decodeIfPresent(SubTopic.self, forKey: .subTopic)` to `init(from:)`; encode side unchanged)* |
| Edit   | `MyRecaLLM/MyRecaLLM/Views/CategoryView.swift` *(rename Upload/Download → Export/Import + nav destinations)* |
| Edit   | `MyRecaLLM/MyRecaLLM/Views/TopicView.swift` *(add bottom container with Export/Import + nav destinations)* |
| Edit   | `MyRecaLLM/MyRecaLLM/Views/SubTopicView.swift` *(rename Upload/Download → Export/Import + nav destinations)* |
| Edit   | `MyRecaLLM/MyRecaLLMTests/MyRecaLLMTests.swift` |

## JSON shape (illustrative)

```json
{
  "version": 1,
  "exportedAt": "2026-05-14T10:24:55Z",
  "kind": "category",
  "item": {
    "title": "Swift",
    "subTitle": "Language fundamentals",
    "includedInRecall": true,
    "lastRecallCycle": "2026-05-10T08:00:00Z",
    "noOfRecallCycles": 3,
    "recallTimeStamps": ["2026-04-01T08:00:00Z"],
    "topics": [
      {
        "title": "Concurrency",
        "subTopics": [
          {
            "title": "Actors",
            "questions": [
              {
                "timestamp": "2026-04-15T12:00:00Z",
                "question": "What is an actor?",
                "generatedAnswer": "An actor is …",
                "userAnswer": "",
                "includedInRecall": true,
                "lastRecallCycle": "2026-04-15T12:00:00Z",
                "noOfRecallCycles": 1
              }
            ]
          }
        ]
      }
    ]
  }
}
```

Each file holds one self-contained subtree that the phase-2 importer can post to the server as a single independent record. Selecting N rows in `ExportView` writes N files of this shape.

## Out of scope for phase 1

- Actually ingesting JSON back into the SwiftData store (`ImportView` lists files but the Import action stays disabled).
- Server upload / sync (phase 2).
- Exporting a single `Item` from `ItemDetailView` or `QuestionListView`.
- Extracting a `Topic`/`SubTopic` out of an already-exported `Category` file — by the user's instruction, explicitly **not** supported.
- User-chosen save locations (`.fileExporter`) — phase 1 always writes to `~/Documents/MyRecaLLM/`.

## Resolved decisions

| Question | Decision |
|---|---|
| Date format | ISO-8601 strings |
| Keep `generatedAnswer` in JSON | Yes (avoid expensive regeneration) |
| File layout | One JSON file per `Category` / `Topic` / `SubTopic`; each file is one independent unit |
| Save location | `~/Documents/MyRecaLLM/` (app sandbox Documents directory) |
| Where export/import lives in the UI | Dedicated `ExportView` / `ImportView`, reached only from the bottom-container Export / Import buttons on the three list views |
| In-list Edit-mode export button | Not added — selection happens inside `ExportView` |
| Export/Import user + server settings | Shared `ExportImportSettingsView` (sheet), backed by `@AppStorage("exportImport.user")` = `"rob"` and `@AppStorage("exportImport.serverURL")` = `"https://Rob-Travel-M5.local:8085"`. Stored in phase 1, consumed in phase 2. |
