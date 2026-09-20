import Charts
import SwiftUI

struct NotesGalleryView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showEditor = false
    @State private var editing: DesignNote?
    @State private var query = ""
    @State private var statusFilter: String?
    @State private var shelf: NoteShelf = .active
    @State private var confirmEmpty = false

    private var filtered: [DesignNote] {
        store.notes(matching: query, status: statusFilter, shelf: shelf)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Room notes")
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                Hairline()
                    .padding(.vertical, 10)
                FolioField(placeholder: "Find a room, title, or layout", text: $query)
                    .padding(.bottom, 10)
                HStack(spacing: 8) {
                    ForEach(NoteShelf.allCases, id: \.rawValue) { item in
                        FolioChip(title: item.rawValue, selected: shelf == item) {
                            shelf = item
                        }
                    }
                }
                .padding(.bottom, 8)
                HStack(spacing: 8) {
                    ForEach(NoteStatus.allCases, id: \.rawValue) { status in
                        FolioChip(title: status.rawValue, selected: statusFilter == status.rawValue) {
                            statusFilter = statusFilter == status.rawValue ? nil : status.rawValue
                        }
                    }
                }
                .padding(.bottom, 8)
                if filtered.isEmpty {
                    Text(emptyCopy)
                        .font(.system(.body, design: .serif))
                        .foregroundColor(Color("AppPrimary").opacity(0.6))
                        .padding(.vertical, 16)
                } else {
                    ForEach(filtered) { note in
                        NavigationLink {
                            NoteDetailView(note: note)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(kicker(for: note))
                                    .font(.system(size: 11, weight: .bold, design: .serif))
                                    .tracking(1.4)
                                    .foregroundColor(Color("AppAccent"))
                                Text(note.title)
                                    .font(.system(size: 24, weight: .bold, design: .serif))
                                    .foregroundColor(Color("AppPrimary"))
                                Text(note.description)
                                    .font(.system(.body, design: .serif))
                                    .foregroundColor(Color("AppPrimary").opacity(0.65))
                                    .lineLimit(3)
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Hairline()
                    }
                }
                if shelf == .active {
                    SlabButton(title: "New room note") {
                        editing = nil
                        showEditor = true
                    }
                    .padding(.top, 18)
                }
                if shelf == .bin && notesInBin {
                    SlabButton(title: "Empty the bin", filled: false) {
                        confirmEmpty = true
                    }
                    .padding(.top, 18)
                }
            }
            .padding(22)
        }
        .canvasBackground()
        .scrollDismissesKeyboard(.immediately)
        .sheet(isPresented: $showEditor) {
            NoteEditorView(existing: editing)
        }
        .confirmationDialog("Permanently clear rooms in the bin?", isPresented: $confirmEmpty, titleVisibility: .visible) {
            Button("Empty the bin", role: .destructive) { store.emptyBin() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var notesInBin: Bool {
        store.notes.contains { $0.deletedAt != nil }
    }

    private var emptyCopy: String {
        switch shelf {
        case .active:
            return store.activeNotes.isEmpty
                ? "Add a room note, then write captions and pin a look from Discover."
                : "No rooms match this query."
        case .archived:
            return "No rooms in the archive."
        case .bin:
            return "The bin is empty."
        }
    }

    private func kicker(for note: DesignNote) -> String {
        var parts = [note.room.uppercased(), note.status.uppercased()]
        if !note.light.isEmpty { parts.append(note.light.uppercased()) }
        return parts.joined(separator: "  ·  ")
    }
}

struct NoteDetailView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let note: DesignNote
    @State private var showEdit = false
    @State private var captionText = ""
    @State private var error = ""
    @State private var confirmTrash = false
    @State private var confirmPurge = false

    private var live: DesignNote {
        store.notes.first(where: { $0.id == note.id }) ?? note
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Cutline(image: "tile_palette", height: 132, caption: "Material study")
                Text(headerKicker)
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.6)
                    .foregroundColor(Color("AppAccent"))
                Text(live.title)
                    .font(.system(size: 34, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                if let measure = live.measureLine {
                    Text(measure)
                        .font(.system(.footnote, design: .serif))
                        .foregroundColor(Color("AppPrimary").opacity(0.7))
                }
                Text(live.description)
                    .font(.system(.body, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.7))
                if !live.materials.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], alignment: .leading, spacing: 8) {
                        ForEach(live.materials, id: \.self) { item in
                            Text(item.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .serif))
                                .tracking(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .overlay(Rectangle().stroke(Color("AppPrimary"), lineWidth: 1))
                        }
                    }
                }
                if let pair = store.pairedNote(for: live) {
                    NavigationLink {
                        NoteDetailView(note: pair)
                    } label: {
                        LeaderRow(
                            number: pair.createdAt <= live.createdAt ? "B4" : "AF",
                            title: pair.createdAt <= live.createdAt ? "Before plate" : "After plate",
                            subtitle: pair.title
                        )
                    }
                    .buttonStyle(.plain)
                }
                DoubleRule()
                Text("Site visit")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundColor(Color("AppPrimary"))
                Text("\(live.checksDone) of \(SiteChecklist.template.count) marked")
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.5))
                ForEach(SiteChecklist.template, id: \.self) { item in
                    Button {
                        store.toggleCheck(noteId: live.id, item: item)
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(live.checks[item] == true ? "■" : "□")
                                .font(.system(size: 16, weight: .bold, design: .serif))
                                .foregroundColor(Color("AppAccent"))
                            Text(item)
                                .font(.system(.body, design: .serif))
                                .foregroundColor(Color("AppPrimary"))
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Hairline()
                }
                Text("Captions")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundColor(Color("AppPrimary"))
                    .padding(.top, 8)
                let items = store.captions(for: live.id)
                if items.isEmpty {
                    Text("No captions yet. Start by selecting a room photo to annotate.")
                        .font(.system(.body, design: .serif))
                        .foregroundColor(Color("AppPrimary").opacity(0.55))
                } else {
                    ForEach(items) { item in
                        NavigationLink {
                            CaptionEditorView(caption: item)
                        } label: {
                            CaptionRow(item: item)
                        }
                        .buttonStyle(.plain)
                        Hairline()
                    }
                }
                TextField("Add a caption", text: $captionText, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(10)
                    .overlay(Rectangle().stroke(Color("AppPrimary"), lineWidth: 1))
                if !error.isEmpty { Text(error).foregroundColor(.red).font(.caption) }
                SlabButton(title: "Save caption", action: saveCaption)
            }
            .padding(22)
        }
        .canvasBackground()
        .scrollDismissesKeyboard(.immediately)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit note") { showEdit = true }
                    Button("Duplicate note") {
                        store.duplicateNote(live)
                        Haptics.success()
                    }
                    if live.deletedAt == nil {
                        Button(live.isArchived ? "Move to active" : "Archive") {
                            store.archiveNote(live, archived: !live.isArchived)
                            Haptics.success()
                        }
                        Button("Move to bin", role: .destructive) { confirmTrash = true }
                    } else {
                        Button("Restore") {
                            store.restoreNote(live)
                            Haptics.success()
                        }
                        Button("Delete forever", role: .destructive) { confirmPurge = true }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Hide") { Keyboard.hide() }
                    .font(.system(size: 14, weight: .bold, design: .serif))
            }
        }
        .sheet(isPresented: $showEdit) {
            NoteEditorView(existing: live)
        }
        .confirmationDialog("Move this room to the bin?", isPresented: $confirmTrash, titleVisibility: .visible) {
            Button("Move to bin", role: .destructive) {
                store.trashNote(live)
                Haptics.success()
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Delete this room forever?", isPresented: $confirmPurge, titleVisibility: .visible) {
            Button("Delete forever", role: .destructive) {
                store.purgeNote(live)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerKicker: String {
        var parts = [live.room.uppercased(), live.status.uppercased()]
        if !live.light.isEmpty { parts.append(live.light.uppercased()) }
        if live.isArchived { parts.append("ARCHIVE") }
        if live.deletedAt != nil { parts.append("BIN") }
        return parts.joined(separator: "  ·  ")
    }

    private func saveCaption() {
        let text = captionText.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { error = "Write a caption before saving."; return }
        error = ""
        store.upsertCaption(RoomCaption(noteId: live.id, text: text))
        captionText = ""
        Keyboard.hide()
        Haptics.success()
    }
}

struct NoteEditorView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    var existing: DesignNote?
    @State private var title = ""
    @State private var room = ""
    @State private var icon = RoomIcon.sofa.rawValue
    @State private var description = ""
    @State private var status = NoteStatus.sketch.rawValue
    @State private var light = ""
    @State private var width = ""
    @State private var depth = ""
    @State private var height = ""
    @State private var materials: Set<String> = []
    @State private var pairKey = ""
    @State private var error = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Room or style", text: $room)
                Picker("Phase", selection: $status) {
                    ForEach(NoteStatus.allCases, id: \.rawValue) { item in
                        Text(item.rawValue).tag(item.rawValue)
                    }
                }
                Picker("Light", selection: $light) {
                    Text("Unset").tag("")
                    ForEach(RoomLight.allCases, id: \.rawValue) { item in
                        Text(item.rawValue).tag(item.rawValue)
                    }
                }
                Picker("Icon", selection: $icon) {
                    ForEach(RoomIcon.allCases, id: \.rawValue) { item in
                        Label(item.rawValue, systemImage: item.rawValue).tag(item.rawValue)
                    }
                }
                TextField("Width", text: $width)
                TextField("Depth", text: $depth)
                TextField("Height", text: $height)
                Section("Materials") {
                    ForEach(MaterialChip.allCases, id: \.rawValue) { chip in
                        Button {
                            if materials.contains(chip.rawValue) {
                                materials.remove(chip.rawValue)
                            } else {
                                materials.insert(chip.rawValue)
                            }
                        } label: {
                            HStack {
                                Text(chip.rawValue)
                                    .foregroundColor(Color("AppPrimary"))
                                Spacer()
                                if materials.contains(chip.rawValue) {
                                    Text("■").foregroundColor(Color("AppAccent"))
                                }
                            }
                        }
                    }
                }
                Picker("Before / after pair", selection: $pairKey) {
                    Text("None").tag("")
                    ForEach(store.activeNotes.filter { $0.id != existing?.id }) { note in
                        Text(note.title).tag(note.id.uuidString)
                    }
                }
                TextField("Furnishings and layout", text: $description, axis: .vertical)
                    .lineLimit(4...8)
                if !error.isEmpty { Text(error).foregroundColor(.red) }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(existing == nil ? "New note" : "Edit note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Hide") { Keyboard.hide() }
                }
            }
            .onAppear {
                if let existing {
                    title = existing.title
                    room = existing.room
                    icon = existing.icon
                    description = existing.description
                    status = existing.status
                    light = existing.light
                    width = existing.width
                    depth = existing.depth
                    height = existing.height
                    materials = Set(existing.materials)
                    pairKey = existing.pairId?.uuidString ?? ""
                }
            }
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let r = room.trimmingCharacters(in: .whitespacesAndNewlines)
        let d = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty || r.isEmpty || d.isEmpty {
            error = "Fill title, room, and description."
            return
        }
        store.upsertNote(
            DesignNote(
                id: existing?.id ?? UUID(),
                title: t,
                icon: icon,
                room: r,
                description: d,
                status: status,
                light: light,
                width: width.trimmingCharacters(in: .whitespacesAndNewlines),
                depth: depth.trimmingCharacters(in: .whitespacesAndNewlines),
                height: height.trimmingCharacters(in: .whitespacesAndNewlines),
                materials: MaterialChip.allCases.map(\.rawValue).filter { materials.contains($0) },
                checks: existing?.checks ?? [:],
                pairId: UUID(uuidString: pairKey),
                isArchived: existing?.isArchived ?? false,
                deletedAt: existing?.deletedAt,
                createdAt: existing?.createdAt ?? Date(),
                updatedAt: Date()
            )
        )
        Haptics.success()
        dismiss()
    }
}

struct CaptionStudioView: View {
    @EnvironmentObject private var store: DataStore
    @State private var query = ""

    private var needle: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Captions")
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                Hairline()
                    .padding(.vertical, 10)
                Cutline(image: "tile_palette", height: 110, caption: "Swatches on the sample table")
                    .padding(.bottom, 12)
                FolioField(placeholder: "Find a caption or room", text: $query)
                    .padding(.bottom, 8)
                if store.livingCaptions.isEmpty {
                    Text("No captions yet. Start by selecting a room photo to annotate.")
                        .font(.system(.body, design: .serif))
                        .foregroundColor(Color("AppPrimary").opacity(0.55))
                } else if visibleNotes.isEmpty {
                    Text("No captions match this query.")
                        .font(.system(.body, design: .serif))
                        .foregroundColor(Color("AppPrimary").opacity(0.55))
                        .padding(.vertical, 12)
                } else {
                    ForEach(visibleNotes) { note in
                        Text(note.title.uppercased())
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .tracking(1.4)
                            .foregroundColor(Color("AppAccent"))
                            .padding(.top, 12)
                        ForEach(visibleCaptions(for: note)) { item in
                            NavigationLink {
                                CaptionEditorView(caption: item)
                            } label: {
                                CaptionRow(item: item)
                            }
                            .buttonStyle(.plain)
                            Hairline()
                        }
                    }
                }
            }
            .padding(22)
        }
        .canvasBackground()
        .scrollDismissesKeyboard(.immediately)
    }

    private var visibleNotes: [DesignNote] {
        store.activeNotes.filter { !visibleCaptions(for: $0).isEmpty }
    }

    private func visibleCaptions(for note: DesignNote) -> [RoomCaption] {
        store.captions(for: note.id).filter { item in
            guard !needle.isEmpty else { return true }
            return item.text.lowercased().contains(needle) || note.title.lowercased().contains(needle) || note.room.lowercased().contains(needle)
        }
    }
}

struct CaptionEditorView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let caption: RoomCaption
    @State private var text = ""
    @State private var error = ""
    @State private var confirmDelete = false

    private var live: RoomCaption {
        store.captions.first(where: { $0.id == caption.id }) ?? caption
    }

    private var parent: DesignNote? {
        store.note(for: live.noteId)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if let parent {
                    Text(parent.room.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .tracking(1.6)
                        .foregroundColor(Color("AppAccent"))
                    Text(parent.title)
                        .font(.system(size: 28, weight: .black, design: .serif))
                        .foregroundColor(Color("AppPrimary"))
                }
                TextField("Caption", text: $text, axis: .vertical)
                    .lineLimit(4...12)
                    .padding(10)
                    .overlay(Rectangle().stroke(Color("AppPrimary"), lineWidth: 1))
                if !error.isEmpty { Text(error).foregroundColor(.red).font(.caption) }
                SlabButton(title: "Save caption", action: save)
                SlabButton(title: "Move to bin", filled: false) { confirmDelete = true }
            }
            .padding(22)
        }
        .canvasBackground()
        .scrollDismissesKeyboard(.immediately)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Hide") { Keyboard.hide() }
            }
        }
        .onAppear { text = live.text }
        .confirmationDialog("Move this caption to the bin?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Move to bin", role: .destructive) {
                store.trashCaption(live)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { error = "Write a caption before saving."; return }
        error = ""
        store.upsertCaption(RoomCaption(id: live.id, noteId: live.noteId, text: trimmed))
        Keyboard.hide()
        Haptics.success()
        dismiss()
    }
}

struct CaptionRow: View {
    let item: RoomCaption

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.text)
                .font(.system(.body, design: .serif))
                .foregroundColor(Color("AppPrimary"))
            Text(item.updatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 11, design: .serif))
                .foregroundColor(Color("AppPrimary").opacity(0.45))
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

struct FolioField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(.body, design: .serif))
            .padding(10)
            .overlay(Rectangle().stroke(Color("AppPrimary"), lineWidth: 1))
    }
}

struct InspirationView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Discover")
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                Hairline()
                    .padding(.vertical, 10)
                if InspirationCatalog.all.isEmpty {
                    Text("Explore stunning room inspirations!")
                        .font(.system(.body, design: .serif))
                }
                ForEach(InspirationCatalog.all) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Cutline(image: item.image, height: 176, caption: item.style)
                        Text(item.title)
                            .font(.system(size: 26, weight: .black, design: .serif))
                            .foregroundColor(Color("AppPrimary"))
                        Text(item.detail)
                            .font(.system(.body, design: .serif))
                            .foregroundColor(Color("AppPrimary").opacity(0.7))
                        SlabButton(
                            title: store.favorites.contains(item.id) ? "Pinned to project" : "Pin to project",
                            filled: store.favorites.contains(item.id)
                        ) {
                            store.toggleFavorite(item.id)
                            Haptics.success()
                        }
                    }
                    .padding(.bottom, 22)
                }
            }
            .padding(22)
        }
        .canvasBackground()
    }
}

struct LedgerView: View {
    @EnvironmentObject private var store: DataStore

    private var roomBars: [LedgerBar] { store.captionsByRoom() }
    private var statusBars: [LedgerBar] { store.notesByStatus() }
    private var activity: [LedgerPoint] { store.captionActivity() }
    private var average: Double {
        guard !store.activeNotes.isEmpty else { return 0 }
        return Double(store.livingCaptions.count) / Double(store.activeNotes.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ledger")
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                DoubleRule()
                HStack(alignment: .top, spacing: 0) {
                    LedgerStat(label: "Rooms", value: "\(store.activeNotes.count)")
                    LedgerStat(label: "Cutlines", value: "\(store.livingCaptions.count)")
                    LedgerStat(label: "Pins", value: "\(store.favorites.count)")
                }
                Text("Average \(average.formatted(.number.precision(.fractionLength(1)))) captions per room.")
                    .font(.system(.footnote, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.55))
                Hairline()
                LedgerChartFrame(title: "Captions by room", caption: "Figure A — volume on file") {
                    if roomBars.isEmpty {
                        Text("File a room to open this plate.")
                            .font(.system(.body, design: .serif))
                            .foregroundColor(Color("AppPrimary").opacity(0.55))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    } else {
                        Chart(roomBars) { row in
                            BarMark(
                                x: .value("Count", row.value),
                                y: .value("Room", row.label)
                            )
                            .foregroundStyle(Color("AppPrimary"))
                        }
                        .chartXAxis {
                            AxisMarks(position: .bottom) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                                AxisValueLabel()
                                    .font(.system(size: 10, design: .serif))
                                    .foregroundStyle(Color("AppPrimary").opacity(0.6))
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .font(.system(size: 10, design: .serif))
                                    .foregroundStyle(Color("AppPrimary"))
                            }
                        }
                    }
                }
                LedgerChartFrame(title: "Seven-day captions", caption: "Figure B — marks this week") {
                    Chart(activity) { point in
                        AreaMark(
                            x: .value("Day", point.day),
                            y: .value("Captions", point.value)
                        )
                        .foregroundStyle(Color("AppPrimary").opacity(0.12))
                        LineMark(
                            x: .value("Day", point.day),
                            y: .value("Captions", point.value)
                        )
                        .foregroundStyle(Color("AppPrimary"))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        PointMark(
                            x: .value("Day", point.day),
                            y: .value("Captions", point.value)
                        )
                        .foregroundStyle(Color("AppAccent"))
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(date, format: .dateTime.weekday(.narrow))
                                        .font(.system(size: 10, design: .serif))
                                }
                            }
                            .foregroundStyle(Color("AppPrimary").opacity(0.6))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                            AxisValueLabel()
                                .font(.system(size: 10, design: .serif))
                                .foregroundStyle(Color("AppPrimary").opacity(0.6))
                        }
                    }
                }
                LedgerChartFrame(title: "Rooms by phase", caption: "Figure C — sketch to styled") {
                    Chart(statusBars) { row in
                        BarMark(
                            x: .value("Phase", row.label),
                            y: .value("Rooms", row.value)
                        )
                        .foregroundStyle(by: .value("Phase", row.label))
                    }
                    .chartForegroundStyleScale([
                        NoteStatus.sketch.rawValue: Color("AppPrimary").opacity(0.35),
                        NoteStatus.measured.rawValue: Color("AppPrimary"),
                        NoteStatus.styled.rawValue: Color("AppAccent")
                    ])
                    .chartLegend(.hidden)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(.system(size: 10, design: .serif))
                                .foregroundStyle(Color("AppPrimary"))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                            AxisValueLabel()
                                .font(.system(size: 10, design: .serif))
                                .foregroundStyle(Color("AppPrimary").opacity(0.6))
                        }
                    }
                }
            }
            .padding(22)
        }
        .canvasBackground()
    }
}

struct LedgerStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .serif))
                .tracking(1.4)
                .foregroundColor(Color("AppAccent"))
            Text(value)
                .font(.system(size: 32, weight: .black, design: .serif))
                .foregroundColor(Color("AppPrimary"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LedgerChartFrame<Content: View>: View {
    let title: String
    let caption: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .serif))
                .tracking(1.4)
                .foregroundColor(Color("AppAccent"))
            content
                .frame(maxWidth: .infinity)
                .frame(height: 188)
                .padding(10)
                .overlay(Rectangle().stroke(Color("AppPrimary"), lineWidth: 1))
            Text(caption.uppercased())
                .font(.system(size: 10, weight: .bold, design: .serif))
                .tracking(1.1)
                .foregroundColor(Color("AppPrimary").opacity(0.45))
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Desk")
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                DoubleRule()
                SlabButton(title: "Rate Us") { viewModel.rateApp() }
                SlabButton(title: "Privacy") { viewModel.openPrivacy() }
                SlabButton(title: "Terms") { viewModel.openTerms() }
                SlabButton(title: "Reset All Data", filled: false) {
                    viewModel.confirmReset = true
                }
            }
            .padding(22)
        }
        .canvasBackground()
        .confirmationDialog("Clear notes, captions, boards, and pins?", isPresented: $viewModel.confirmReset, titleVisibility: .visible) {
            Button("Reset All Data", role: .destructive) { store.resetAllData() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
