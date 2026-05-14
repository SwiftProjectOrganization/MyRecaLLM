//
//  ExportView.swift
//  MyRecaLLM
//

import SwiftUI
import SwiftData

struct ExportView {
    enum Scope {
        case categories
        case topics(parent: Category)
        case subTopics(parent: Topic)
    }

    @Environment(\.modelContext) private var modelContext
    @Query private var allCategories: [Category]

    let scope: Scope

    @State private var selection = Set<PersistentIdentifier>()
    @State private var isEditing = false
    @State private var showingHelp = false
    @State private var showingSettings = false
    @State private var statusMessage: String?
    @State private var statusIsError = false
}

extension ExportView: View {
    var body: some View {
        VStack {
            List(selection: $selection) {
                Section {
                    pathRows
                } header: {
                    Text("Path")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                Section {
                    itemRows
                } header: {
                    Text(itemsSectionTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(statusIsError ? .red : .secondary)
                    }
                }
            }
#if os(iOS) || os(visionOS)
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
#endif
            .sheet(isPresented: $showingHelp) {
                ExportHelpView()
            }
            .sheet(isPresented: $showingSettings) {
                ExportImportSettingsView()
            }
            .navigationTitle(navigationTitle)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button("Help", systemImage: "questionmark.circle") {
                        showingHelp = true
                    }
                    Button("Settings", systemImage: "gearshape") {
                        showingSettings = true
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation {
                            isEditing.toggle()
                            if !isEditing { selection.removeAll() }
                        }
                    }
                    if isEditing {
                        Button("Export Selected", systemImage: "square.and.arrow.up") {
                            exportSelected()
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(selection.isEmpty)
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var pathRows: some View {
        switch scope {
        case .categories:
            Text("Categories")
        case .topics(let parent):
            LabeledContent("Category", value: parent.title ?? "—")
        case .subTopics(let parent):
            LabeledContent("Category", value: parent.category?.title ?? "—")
            LabeledContent("Topic", value: parent.title ?? "—")
        }
    }

    @ViewBuilder
    private var itemRows: some View {
        switch scope {
        case .categories:
            ForEach(allCategories) { category in
                row(title: category.title, id: category.persistentModelID)
            }
        case .topics(let parent):
            ForEach(parent.topics ?? []) { topic in
                row(title: topic.title, id: topic.persistentModelID)
            }
        case .subTopics(let parent):
            ForEach(parent.subTopics ?? []) { subTopic in
                row(title: subTopic.title, id: subTopic.persistentModelID)
            }
        }
    }

    private func row(title: String?, id: PersistentIdentifier) -> some View {
        Text((title?.isEmpty == false ? title! : "Untitled"))
            .padding(6)
            .glassEffect(.clear.tint(.blue).interactive(), in: .buttonBorder)
            .tag(id)
    }

    // MARK: - Scope-derived strings

    private var navigationTitle: String {
        switch scope {
        case .categories: "Export Categories"
        case .topics: "Export Topics"
        case .subTopics: "Export SubTopics"
        }
    }

    private var itemsSectionTitle: String {
        switch scope {
        case .categories: "Categories"
        case .topics: "Topics"
        case .subTopics: "SubTopics"
        }
    }

    // MARK: - Export

    private func exportSelected() {
        var written: [URL] = []
        var errors: [String] = []

        switch scope {
        case .categories:
            for category in allCategories where selection.contains(category.persistentModelID) {
                do {
                    let data = try ExportService.encode(category: category)
                    let filename = ExportService.defaultFilename(
                        kind: .category,
                        title: category.title ?? "Untitled"
                    )
                    let url = try RecallFileStore.write(data, filename: filename)
                    written.append(url)
                } catch {
                    errors.append(error.localizedDescription)
                }
            }
        case .topics(let parent):
            for topic in parent.topics ?? [] where selection.contains(topic.persistentModelID) {
                do {
                    let data = try ExportService.encode(topic: topic)
                    let filename = ExportService.defaultFilename(
                        kind: .topic,
                        title: topic.title ?? "Untitled"
                    )
                    let url = try RecallFileStore.write(data, filename: filename)
                    written.append(url)
                } catch {
                    errors.append(error.localizedDescription)
                }
            }
        case .subTopics(let parent):
            for subTopic in parent.subTopics ?? [] where selection.contains(subTopic.persistentModelID) {
                do {
                    let data = try ExportService.encode(subTopic: subTopic)
                    let filename = ExportService.defaultFilename(
                        kind: .subTopic,
                        title: subTopic.title ?? "Untitled"
                    )
                    let url = try RecallFileStore.write(data, filename: filename)
                    written.append(url)
                } catch {
                    errors.append(error.localizedDescription)
                }
            }
        }

        if errors.isEmpty {
            statusIsError = false
            let plural = written.count == 1 ? "" : "s"
            statusMessage = "Exported \(written.count) file\(plural) to ~/Documents/MyRecaLLM/."
        } else {
            statusIsError = true
            let firstError = errors.first ?? ""
            statusMessage = "Exported \(written.count); \(errors.count) failed: \(firstError)"
        }
    }
}
