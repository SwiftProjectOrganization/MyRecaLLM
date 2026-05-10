//
//  QuestionListView.swift
//  MyRecaLLM
//

import SwiftUI
import SwiftData

struct QuestionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var subTopic: SubTopic
    @State private var showingAddItem = false
    @State private var isEditing = false
    @State private var selection = Set<PersistentIdentifier>()
    @State private var itemToUpdate: Item?
    @State private var showingHelp = false

    private var items: [Item] {
        subTopic.questions ?? []
    }

    var body: some View {
        List(selection: $selection) {
            Section {
                LabeledContent("Category", value: subTopic.topic?.category?.title ?? "—")
                LabeledContent("Topic", value: subTopic.topic?.title ?? "—")
                LabeledContent("SubTopic", value: subTopic.title ?? "—")
            } header: {
                Text("Path")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            Section {
                ForEach(items) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        let question = item.question ?? ""
                        Text(question.isEmpty ? "New question" : question)
                            .foregroundStyle(question.isEmpty ? .secondary : .primary)
                            .lineLimit(2)
                    }
                    .tag(item.persistentModelID)
                }
                .onDelete(perform: deleteItems)
            } header: {
                Text("Questions")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
#if os(iOS) || os(visionOS)
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
#endif
        .sheet(isPresented: $showingAddItem) {
            AddItemView(subTopic: subTopic)
        }
        .sheet(item: $itemToUpdate) { item in
            QuestionUpdateView(item: item)
        }
        .sheet(isPresented: $showingHelp) {
            QuestionHelpView()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Help", systemImage: "questionmark.circle") {
                    showingHelp = true
                }
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation {
                        isEditing.toggle()
                        if !isEditing { selection.removeAll() }
                    }
                }
                Menu("Update") {
                    ForEach(items) { item in
                        let label = (item.question ?? "").isEmpty ? "New question" : (item.question ?? "")
                        Button(label) {
                            itemToUpdate = item
                        }
                    }
                }
                .buttonStyle(.glass)
                .disabled(isEditing || items.isEmpty)
                Button("Add Question") { addItem() }
                    .buttonStyle(.glass)
                    .disabled(isEditing)
                if isEditing {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        deleteSelected()
                    }
                    .disabled(selection.isEmpty)
                }
            }
        }
    }

    private func addItem() {
        showingAddItem = true
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }

    private func deleteSelected() {
        withAnimation {
            for item in items where selection.contains(item.persistentModelID) {
                modelContext.delete(item)
            }
            selection.removeAll()
            isEditing = false
        }
    }
}
