import Foundation

@MainActor
final class DataStore: ObservableObject {
    @Published var hasSeenOnboarding: Bool
    @Published var notes: [DesignNote]
    @Published var captions: [RoomCaption]
    @Published var favorites: [String]
    @Published var boards: [MoodBoard]
    @Published var undoTitle = ""
    @Published var canUndo = false

    private let defaults = UserDefaults.standard
    private var undoNoteId: UUID?
    private var undoCaptionId: UUID?
    private var undoBoard: MoodBoard?
    private var undoWork: DispatchWorkItem?

    private enum Key {
        static let onboarding = "hasSeenOnboarding"
        static let notes = "designNotes"
        static let captions = "photoCaptions"
        static let favorites = "favorites"
        static let boards = "moodBoards"
    }

    init() {
        hasSeenOnboarding = defaults.bool(forKey: Key.onboarding)
        notes = Self.decode(key: Key.notes)
        captions = Self.decode(key: Key.captions)
        favorites = Self.decode(key: Key.favorites)
        boards = Self.decode(key: Key.boards)
        persist(notes, key: Key.notes)
        persist(captions, key: Key.captions)
    }

    var activeNotes: [DesignNote] {
        notes.filter { $0.deletedAt == nil && !$0.isArchived }.sorted { $0.updatedAt > $1.updatedAt }
    }

    var latestActive: DesignNote? {
        activeNotes.first
    }

    var livingCaptions: [RoomCaption] {
        captions.filter { caption in
            caption.deletedAt == nil && notes.contains { $0.id == caption.noteId && $0.deletedAt == nil && !$0.isArchived }
        }
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: Key.onboarding)
    }

    func upsertNote(_ item: DesignNote) {
        var item = item
        item.updatedAt = Date()
        let previousPair = notes.first(where: { $0.id == item.id })?.pairId
        if let index = notes.firstIndex(where: { $0.id == item.id }) {
            item.createdAt = notes[index].createdAt
            notes[index] = item
        } else {
            notes.append(item)
        }
        relinkPair(for: item, previous: previousPair)
        persist(notes, key: Key.notes)
    }

    func archiveNote(_ item: DesignNote, archived: Bool) {
        guard let index = notes.firstIndex(where: { $0.id == item.id }) else { return }
        notes[index].isArchived = archived
        if archived { notes[index].deletedAt = nil }
        notes[index].updatedAt = Date()
        persist(notes, key: Key.notes)
    }

    func trashNote(_ item: DesignNote) {
        guard let index = notes.firstIndex(where: { $0.id == item.id }) else { return }
        notes[index].deletedAt = Date()
        notes[index].isArchived = false
        persist(notes, key: Key.notes)
        armUndo(title: "Room moved to the bin.", noteId: item.id)
    }

    func restoreNote(_ item: DesignNote) {
        guard let index = notes.firstIndex(where: { $0.id == item.id }) else { return }
        notes[index].deletedAt = nil
        notes[index].isArchived = false
        notes[index].updatedAt = Date()
        persist(notes, key: Key.notes)
        clearUndo()
    }

    func purgeNote(_ item: DesignNote) {
        notes.removeAll { $0.id == item.id }
        captions.removeAll { $0.noteId == item.id }
        for index in notes.indices where notes[index].pairId == item.id {
            notes[index].pairId = nil
        }
        for index in boards.indices {
            boards[index].noteIds.removeAll { $0 == item.id }
        }
        persist(notes, key: Key.notes)
        persist(captions, key: Key.captions)
        persist(boards, key: Key.boards)
        clearUndo()
    }

    func emptyBin() {
        let trashed = Set(notes.filter { $0.deletedAt != nil }.map(\.id))
        notes.removeAll { $0.deletedAt != nil }
        captions.removeAll { $0.deletedAt != nil || trashed.contains($0.noteId) }
        for index in notes.indices where notes[index].pairId.map(trashed.contains) == true {
            notes[index].pairId = nil
        }
        for index in boards.indices {
            boards[index].noteIds.removeAll { trashed.contains($0) }
        }
        persist(notes, key: Key.notes)
        persist(captions, key: Key.captions)
        persist(boards, key: Key.boards)
        clearUndo()
    }

    func duplicateNote(_ item: DesignNote) {
        let copy = DesignNote(
            title: item.title + " (copy)",
            icon: item.icon,
            room: item.room,
            description: item.description,
            status: item.status,
            light: item.light,
            width: item.width,
            depth: item.depth,
            height: item.height,
            materials: item.materials,
            checks: item.checks
        )
        notes.insert(copy, at: 0)
        let clones = captions(for: item.id, includeDeleted: true).filter { $0.deletedAt == nil }.map { caption in
            RoomCaption(noteId: copy.id, text: caption.text)
        }
        captions.append(contentsOf: clones)
        persist(notes, key: Key.notes)
        persist(captions, key: Key.captions)
    }

    func toggleCheck(noteId: UUID, item: String) {
        guard let index = notes.firstIndex(where: { $0.id == noteId }) else { return }
        notes[index].checks[item] = !(notes[index].checks[item] ?? false)
        notes[index].updatedAt = Date()
        persist(notes, key: Key.notes)
    }

    func upsertCaption(_ item: RoomCaption) {
        var item = item
        item.updatedAt = Date()
        item.deletedAt = nil
        if let index = captions.firstIndex(where: { $0.id == item.id }) {
            captions[index] = item
        } else {
            captions.append(item)
        }
        persist(captions, key: Key.captions)
    }

    func trashCaption(_ item: RoomCaption) {
        guard let index = captions.firstIndex(where: { $0.id == item.id }) else { return }
        captions[index].deletedAt = Date()
        persist(captions, key: Key.captions)
        armUndo(title: "Caption moved to the bin.", captionId: item.id)
    }

    func captions(for noteId: UUID, includeDeleted: Bool = false) -> [RoomCaption] {
        captions
            .filter { $0.noteId == noteId && (includeDeleted || $0.deletedAt == nil) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func note(for id: UUID) -> DesignNote? {
        notes.first { $0.id == id }
    }

    func pairedNote(for item: DesignNote) -> DesignNote? {
        guard let pairId = item.pairId else { return nil }
        return notes.first { $0.id == pairId && $0.deletedAt == nil }
    }

    func toggleFavorite(_ id: String) {
        if let index = favorites.firstIndex(of: id) {
            favorites.remove(at: index)
        } else {
            favorites.append(id)
        }
        persist(favorites, key: Key.favorites)
    }

    func upsertBoard(_ item: MoodBoard) {
        var item = item
        item.updatedAt = Date()
        if let index = boards.firstIndex(where: { $0.id == item.id }) {
            boards[index] = item
        } else {
            boards.insert(item, at: 0)
        }
        persist(boards, key: Key.boards)
    }

    func trashBoard(_ item: MoodBoard) {
        boards.removeAll { $0.id == item.id }
        persist(boards, key: Key.boards)
        undoBoard = item
        armUndo(title: "Board discarded.", board: item)
    }

    func toggleBoardNote(_ board: MoodBoard, noteId: UUID) {
        guard let index = boards.firstIndex(where: { $0.id == board.id }) else { return }
        if let existing = boards[index].noteIds.firstIndex(of: noteId) {
            boards[index].noteIds.remove(at: existing)
        } else {
            boards[index].noteIds.append(noteId)
        }
        boards[index].updatedAt = Date()
        persist(boards, key: Key.boards)
    }

    func toggleBoardPin(_ board: MoodBoard, pinId: String) {
        guard let index = boards.firstIndex(where: { $0.id == board.id }) else { return }
        if let existing = boards[index].pinIds.firstIndex(of: pinId) {
            boards[index].pinIds.remove(at: existing)
        } else {
            boards[index].pinIds.append(pinId)
        }
        boards[index].updatedAt = Date()
        persist(boards, key: Key.boards)
    }

    func undoLast() {
        if let id = undoNoteId, let index = notes.firstIndex(where: { $0.id == id }) {
            notes[index].deletedAt = nil
            persist(notes, key: Key.notes)
        } else if let id = undoCaptionId, let index = captions.firstIndex(where: { $0.id == id }) {
            captions[index].deletedAt = nil
            persist(captions, key: Key.captions)
        } else if let board = undoBoard {
            boards.insert(board, at: 0)
            persist(boards, key: Key.boards)
        }
        clearUndo()
    }

    func resetAllData() {
        if let domain = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: domain)
        }
        hasSeenOnboarding = false
        notes = []
        captions = []
        favorites = []
        boards = []
        clearUndo()
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    func notes(matching query: String, status: String?, shelf: NoteShelf) -> [DesignNote] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return notes
            .filter { note in
                switch shelf {
                case .active: return note.deletedAt == nil && !note.isArchived
                case .archived: return note.deletedAt == nil && note.isArchived
                case .bin: return note.deletedAt != nil
                }
            }
            .filter { status == nil || $0.status == status }
            .filter { note in
                guard !needle.isEmpty else { return true }
                return note.title.lowercased().contains(needle)
                    || note.room.lowercased().contains(needle)
                    || note.description.lowercased().contains(needle)
                    || note.light.lowercased().contains(needle)
                    || note.materials.joined(separator: " ").lowercased().contains(needle)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func captionsByRoom() -> [LedgerBar] {
        let grouped = Dictionary(grouping: activeNotes, by: \.room)
        return grouped
            .map { room, items in
                LedgerBar(label: room, value: items.reduce(0) { $0 + captions(for: $1.id).count })
            }
            .sorted { $0.value > $1.value }
    }

    func notesByStatus() -> [LedgerBar] {
        NoteStatus.allCases.map { status in
            LedgerBar(label: status.rawValue, value: activeNotes.filter { $0.status == status.rawValue }.count)
        }
    }

    func captionActivity(days: Int = 7) -> [LedgerPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<days).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let value = livingCaptions.filter { calendar.isDate($0.updatedAt, inSameDayAs: day) }.count
            return LedgerPoint(day: day, value: value)
        }
    }

    private func relinkPair(for item: DesignNote, previous: UUID?) {
        if let previous, previous != item.pairId, let index = notes.firstIndex(where: { $0.id == previous }), notes[index].pairId == item.id {
            notes[index].pairId = nil
        }
        guard let partner = item.pairId, let index = notes.firstIndex(where: { $0.id == partner }) else { return }
        let old = notes[index].pairId
        notes[index].pairId = item.id
        if let old, old != item.id, let other = notes.firstIndex(where: { $0.id == old }), notes[other].pairId == partner {
            notes[other].pairId = nil
        }
    }

    private func armUndo(title: String, noteId: UUID? = nil, captionId: UUID? = nil, board: MoodBoard? = nil) {
        undoWork?.cancel()
        undoNoteId = noteId
        undoCaptionId = captionId
        undoBoard = board
        undoTitle = title
        canUndo = true
        let work = DispatchWorkItem { [weak self] in
            self?.clearUndo()
        }
        undoWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: work)
    }

    private func clearUndo() {
        undoWork?.cancel()
        undoWork = nil
        undoNoteId = nil
        undoCaptionId = nil
        undoBoard = nil
        undoTitle = ""
        canUndo = false
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func decode<T: Decodable>(key: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key), let value = try? JSONDecoder().decode([T].self, from: data) else {
            return []
        }
        return value
    }
}

struct LedgerBar: Identifiable {
    var id: String { label }
    let label: String
    let value: Int
}

struct LedgerPoint: Identifiable {
    var id: Date { day }
    let day: Date
    let value: Int
}
