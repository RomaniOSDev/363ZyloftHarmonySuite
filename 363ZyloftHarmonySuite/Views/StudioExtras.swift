import SwiftUI

struct CompareRoomsView: View {
    @EnvironmentObject private var store: DataStore
    @State private var leftId = ""
    @State private var rightId = ""

    private var left: DesignNote? { store.note(forUUIDString: leftId) }
    private var right: DesignNote? { store.note(forUUIDString: rightId) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Compare")
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                DoubleRule()
                if store.activeNotes.count < 2 {
                    Text("File two rooms to set them on the same plate.")
                        .font(.system(.body, design: .serif))
                        .foregroundColor(Color("AppPrimary").opacity(0.55))
                } else {
                    menu("Left plate", selection: $leftId)
                    menu("Right plate", selection: $rightId)
                    Hairline()
                    HStack(alignment: .top, spacing: 12) {
                        CompareColumn(note: left, captions: left.map { store.captions(for: $0.id).count } ?? 0)
                        Rectangle().fill(Color("AppPrimary")).frame(width: 1)
                        CompareColumn(note: right, captions: right.map { store.captions(for: $0.id).count } ?? 0)
                    }
                }
            }
            .padding(22)
        }
        .canvasBackground()
        .onAppear {
            if leftId.isEmpty { leftId = store.activeNotes.first?.id.uuidString ?? "" }
            if rightId.isEmpty { rightId = store.activeNotes.dropFirst().first?.id.uuidString ?? "" }
        }
    }

    private func menu(_ title: String, selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .serif))
                .tracking(1.4)
                .foregroundColor(Color("AppAccent"))
            Picker(title, selection: selection) {
                ForEach(store.activeNotes) { note in
                    Text(note.title).tag(note.id.uuidString)
                }
            }
            .pickerStyle(.menu)
            .tint(Color("AppPrimary"))
        }
    }
}

struct CompareColumn: View {
    let note: DesignNote?
    let captions: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let note {
                Text(note.room.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundColor(Color("AppAccent"))
                Text(note.title)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                Text(note.status)
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.6))
                Text(note.light.isEmpty ? "Light unset" : note.light)
                    .font(.system(.footnote, design: .serif))
                Text(note.measureLine ?? "No measure")
                    .font(.system(.footnote, design: .serif))
                Text(note.materials.isEmpty ? "No swatches" : note.materials.joined(separator: ", "))
                    .font(.system(.footnote, design: .serif))
                Text("Site \(note.checksDone)/\(SiteChecklist.template.count)")
                    .font(.system(.footnote, design: .serif))
                Text("\(captions) captions")
                    .font(.system(.footnote, design: .serif))
                Text(note.description)
                    .font(.system(.footnote, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.65))
                    .lineLimit(6)
            } else {
                Text("Choose a room")
                    .font(.system(.body, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.45))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BoardsView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showNew = false
    @State private var title = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Boards")
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                Hairline()
                    .padding(.vertical, 10)
                if store.boards.isEmpty {
                    Text("Pin rooms and Discover cuts into a local collection.")
                        .font(.system(.body, design: .serif))
                        .foregroundColor(Color("AppPrimary").opacity(0.55))
                        .padding(.bottom, 16)
                } else {
                    ForEach(store.boards) { board in
                        NavigationLink {
                            BoardDetailView(board: board)
                        } label: {
                            LeaderRow(
                                number: String(format: "%02d", (store.boards.firstIndex(where: { $0.id == board.id }) ?? 0) + 1),
                                title: board.title,
                                subtitle: "\(board.noteIds.count) rooms · \(board.pinIds.count) pins"
                            )
                        }
                        .buttonStyle(.plain)
                        Hairline()
                    }
                }
                SlabButton(title: "New board") { showNew = true }
                    .padding(.top, 18)
            }
            .padding(22)
        }
        .canvasBackground()
        .sheet(isPresented: $showNew) {
            NavigationStack {
                Form {
                    TextField("Board title", text: $title)
                }
                .navigationTitle("New board")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showNew = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !name.isEmpty else { return }
                            store.upsertBoard(MoodBoard(title: name))
                            title = ""
                            showNew = false
                            Haptics.success()
                        }
                    }
                }
            }
        }
    }
}

struct BoardDetailView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let board: MoodBoard

    private var live: MoodBoard {
        store.boards.first(where: { $0.id == board.id }) ?? board
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(live.title)
                    .font(.system(size: 34, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                DoubleRule()
                Text("ROOMS")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.4)
                    .foregroundColor(Color("AppAccent"))
                if store.activeNotes.isEmpty {
                    Text("No active rooms to pin.")
                        .font(.system(.body, design: .serif))
                        .foregroundColor(Color("AppPrimary").opacity(0.55))
                } else {
                    ForEach(store.activeNotes) { note in
                        Button {
                            store.toggleBoardNote(live, noteId: note.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(note.title)
                                        .font(.system(size: 18, weight: .bold, design: .serif))
                                        .foregroundColor(Color("AppPrimary"))
                                    Text(note.room)
                                        .font(.system(size: 12, design: .serif))
                                        .foregroundColor(Color("AppPrimary").opacity(0.55))
                                }
                                Spacer()
                                Text(live.noteIds.contains(note.id) ? "PINNED" : "PIN")
                                    .font(.system(size: 11, weight: .heavy, design: .serif))
                                    .foregroundColor(Color("AppAccent"))
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Hairline()
                    }
                }
                Text("DISCOVER CUTS")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.4)
                    .foregroundColor(Color("AppAccent"))
                    .padding(.top, 8)
                ForEach(InspirationCatalog.all) { item in
                    Button {
                        store.toggleBoardPin(live, pinId: item.id)
                    } label: {
                        HStack {
                            Text(item.title)
                                .font(.system(size: 18, weight: .bold, design: .serif))
                                .foregroundColor(Color("AppPrimary"))
                            Spacer()
                            Text(live.pinIds.contains(item.id) ? "PINNED" : "PIN")
                                .font(.system(size: 11, weight: .heavy, design: .serif))
                                .foregroundColor(Color("AppAccent"))
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Hairline()
                }
                SlabButton(title: "Discard board", filled: false) {
                    store.trashBoard(live)
                    dismiss()
                }
                .padding(.top, 12)
            }
            .padding(22)
        }
        .canvasBackground()
    }
}

extension DataStore {
    func note(forUUIDString value: String) -> DesignNote? {
        guard let id = UUID(uuidString: value) else { return nil }
        return note(for: id)
    }
}
