import Foundation

struct DesignNote: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var icon: String
    var room: String
    var description: String
    var status: String
    var light: String
    var width: String
    var depth: String
    var height: String
    var materials: [String]
    var checks: [String: Bool]
    var pairId: UUID?
    var isArchived: Bool
    var deletedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        icon: String,
        room: String,
        description: String,
        status: String = NoteStatus.sketch.rawValue,
        light: String = "",
        width: String = "",
        depth: String = "",
        height: String = "",
        materials: [String] = [],
        checks: [String: Bool] = [:],
        pairId: UUID? = nil,
        isArchived: Bool = false,
        deletedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.room = room
        self.description = description
        self.status = status
        self.light = light
        self.width = width
        self.depth = depth
        self.height = height
        self.materials = materials
        self.checks = checks
        self.pairId = pairId
        self.isArchived = isArchived
        self.deletedAt = deletedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, icon, room, description, status, light, width, depth, height
        case materials, checks, pairId, isArchived, deletedAt, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        icon = try container.decode(String.self, forKey: .icon)
        room = try container.decode(String.self, forKey: .room)
        description = try container.decode(String.self, forKey: .description)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? NoteStatus.sketch.rawValue
        light = try container.decodeIfPresent(String.self, forKey: .light) ?? ""
        width = try container.decodeIfPresent(String.self, forKey: .width) ?? ""
        depth = try container.decodeIfPresent(String.self, forKey: .depth) ?? ""
        height = try container.decodeIfPresent(String.self, forKey: .height) ?? ""
        materials = try container.decodeIfPresent([String].self, forKey: .materials) ?? []
        checks = try container.decodeIfPresent([String: Bool].self, forKey: .checks) ?? [:]
        pairId = try container.decodeIfPresent(UUID.self, forKey: .pairId)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }

    var measureLine: String? {
        let parts = [width, depth, height].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " × ")
    }

    var checksDone: Int {
        SiteChecklist.template.filter { checks[$0] == true }.count
    }
}

struct RoomCaption: Identifiable, Codable, Equatable {
    var id: UUID
    var noteId: UUID
    var text: String
    var updatedAt: Date
    var deletedAt: Date?

    init(id: UUID = UUID(), noteId: UUID, text: String, updatedAt: Date = Date(), deletedAt: Date? = nil) {
        self.id = id
        self.noteId = noteId
        self.text = text
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, noteId, text, updatedAt, deletedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        noteId = try container.decode(UUID.self, forKey: .noteId)
        text = try container.decode(String.self, forKey: .text)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
    }
}

struct MoodBoard: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var noteIds: [UUID]
    var pinIds: [String]
    var updatedAt: Date

    init(id: UUID = UUID(), title: String, noteIds: [UUID] = [], pinIds: [String] = [], updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.noteIds = noteIds
        self.pinIds = pinIds
        self.updatedAt = updatedAt
    }
}

struct InspirationItem: Identifiable, Hashable {
    let id: String
    let title: String
    let style: String
    let detail: String
    let image: String
}

enum RoomIcon: String, CaseIterable {
    case sofa = "sofa.fill"
    case lamp = "lamp.desk.fill"
    case plant = "leaf.fill"
    case bed = "bed.double.fill"
    case bath = "shower.fill"
    case table = "table.furniture.fill"
}

enum NoteStatus: String, CaseIterable {
    case sketch = "Sketch"
    case measured = "Measured"
    case styled = "Styled"
}

enum RoomLight: String, CaseIterable {
    case north = "North"
    case morning = "Morning"
    case evening = "Evening"
    case mixed = "Mixed"
}

enum MaterialChip: String, CaseIterable {
    case linen = "Linen"
    case oak = "Oak"
    case brass = "Brass"
    case wool = "Wool"
    case plaster = "Plaster"
    case marble = "Marble"
    case ceramic = "Ceramic"
    case glass = "Glass"
}

enum NoteShelf: String, CaseIterable {
    case active = "Active"
    case archived = "Archived"
    case bin = "Bin"
}

enum SiteChecklist {
    static let template = [
        "Measure openings",
        "Note the north wall",
        "Photograph corners",
        "Check outlets",
        "Sample the floor",
        "Record ceiling height"
    ]
}

enum StudioBrief {
    private static let lines = [
        "Hold the palette to three values.",
        "Leave negative space around the hero chair.",
        "Group plants in odd numbers near daylight.",
        "Test hardware against the coolest swatch.",
        "Write the cutline before you move the sofa.",
        "North light first, lamps second.",
        "One metal, one wood, one textile."
    ]

    static var today: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return lines[(day - 1) % lines.count]
    }
}

enum InspirationCatalog {
    static let all: [InspirationItem] = [
        InspirationItem(id: "linen", title: "Linen bay", style: "Quiet living", detail: "Low sofa, oak floor, sheer daylight. Keep the palette to sand and sage.", image: "bg_living"),
        InspirationItem(id: "lounge", title: "Window lounge", style: "Mid-century", detail: "One hero chair, terrazzo, a wool throw. Leave negative space around the silhouette.", image: "banner_chair"),
        InspirationItem(id: "swatch", title: "Sample table", style: "Material study", detail: "Paint chips, linen, brass. Test hardware against the coolest swatch.", image: "tile_palette"),
        InspirationItem(id: "atrium", title: "Plant atrium", style: "Biophilic", detail: "Ceramic pots, monstera, olive. Group in odd numbers near the brightest wall.", image: "tile_plants")
    ]

    static func item(id: String) -> InspirationItem? {
        all.first { $0.id == id }
    }
}
