//
//  CategoryView.swift
//  MyRecaLLM
//

import SwiftUI
import SwiftData

struct CategoryView {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State var isOpacityEnabled: Bool = true
    @State private var showingAddCategory = false
    @State private var isEditing = false
    @State private var selection = Set<PersistentIdentifier>()
}

extension CategoryView: View {
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
//                    Image("question")
//                        .resizable()
//                        .ignoresSafeArea(.all)

                    List(selection: $selection) {
                        Section {
                            Text("Categories")
                        } header: {
                            Text("Path").font(.headline)
                        }
//                        Toggle("Increase opacity", isOn: $isOpacityEnabled)
                        Section {
                            ForEach(categories) { category in
                                NavigationLink(destination: TopicView(category: category)) {
                                    Text((category.title?.isEmpty == false ? category.title! : "Untitled"))
                                        .padding(10)
                                        .glassEffect(.clear.tint(.blue).interactive(), in: .buttonBorder)
                                }
                                .tag(category.persistentModelID)
                            }
                            .onDelete(perform: deleteCategories)
                        } header: {
                            Text("Categories").font(.headline)
                        }
                    }
                    .opacity(isOpacityEnabled ? 0.95 : 1)
#if os(iOS) || os(visionOS)
                    .environment(\.editMode, .constant(isEditing ? .active : .inactive))
#endif
                    .sheet(isPresented: $showingAddCategory) {
                        AddCategoryView()
                    }
                    .toolbar {
                      ToolbarItemGroup(placement: .topBarTrailing) {
                        Button(isEditing ? "Done" : "Edit") {
                          withAnimation {
                            isEditing.toggle()
                            if !isEditing { selection.removeAll() }
                          }
                        }
                      }
                      ToolbarItemGroup(placement: .topBarTrailing) {
                            Button("Add Category") { addCategory() }
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
                Spacer()
                GlassEffectContainer {
                    HStack(spacing: 24) {
                        Button("TBD", systemImage: "square.and.arrow.up.fill") { }
                            .padding(10)
                            .buttonStyle(.glass)
                        Button("Download", systemImage: "square.and.arrow.down") { }
                            .padding(10)
                            .buttonStyle(.glass)
                            .tint(Color.green)
                        Button("Upload", systemImage: "square.and.arrow.up") { }
                            .padding(10)
                            .buttonStyle(.glass)
                            .tint(.blue)
                    }
                }
                .tint(.red)
            }
            .opacity(1.0)
        }
    }

    private func addCategory() {
        showingAddCategory = true
    }

    private func deleteCategories(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(categories[index])
            }
        }
    }

    private func deleteSelected() {
        withAnimation {
            for category in categories where selection.contains(category.persistentModelID) {
                modelContext.delete(category)
            }
            selection.removeAll()
            isEditing = false
        }
    }
}

#Preview {
    CategoryView()
        .modelContainer(for: [Category.self, Topic.self, SubTopic.self, Item.self], inMemory: true)
}
