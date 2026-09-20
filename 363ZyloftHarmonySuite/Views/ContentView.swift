import SwiftUI

struct ContentView: View {
    @StateObject private var store = DataStore()

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                NavigationStack {
                    StudioIndexView()
                }
            } else {
                OnboardingView()
            }
        }
        .environmentObject(store)
        .overlay(alignment: .bottom) {
            UndoBanner()
                .environmentObject(store)
        }
        .animation(.easeInOut(duration: 0.2), value: store.canUndo)
        .preferredColorScheme(.light)
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("VOL. I  ·  STUDIO EDITION")
                .font(.system(size: 11, weight: .bold, design: .serif))
                .tracking(2)
                .foregroundColor(Color("AppAccent"))
                .padding(.horizontal, 20)
                .padding(.top, 18)
            Text("Capture the room")
                .font(.system(size: 42, weight: .black, design: .serif))
                .foregroundColor(Color("AppPrimary"))
                .padding(.horizontal, 20)
                .padding(.top, 8)
            DoubleRule()
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            Cutline(image: "bg_living", height: 220, caption: "Figure 1 — living bay")
                .padding(.horizontal, 20)
            Text("Keep layouts as notes, write captions on furnishings, and pin looks from Discover — one folio you can reopen on site.")
                .font(.system(.body, design: .serif))
                .foregroundColor(Color("AppPrimary").opacity(0.75))
                .padding(20)
            Spacer()
            SlabButton(title: "Enter studio") {
                store.completeOnboarding()
            }
            .padding(20)
        }
        .canvasBackground()
    }
}

struct StudioIndexView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day().year()).uppercased())
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .tracking(1.8)
                    .foregroundColor(Color("AppAccent"))
                Text("Studio record")
                    .font(.system(size: 44, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                    .padding(.top, 4)
                Text("Rooms, captions, and borrowed ideas — set in type.")
                    .font(.system(.footnote, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.55))
                    .padding(.bottom, 10)
                DoubleRule()
                Cutline(image: "banner_chair", height: 168, caption: "Above — a chair held in daylight")
                    .padding(.vertical, 14)
                VStack(alignment: .leading, spacing: 6) {
                    Text("TODAY’S BRIEF")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .tracking(1.4)
                        .foregroundColor(Color("AppAccent"))
                    Text(StudioBrief.today)
                        .font(.system(.body, design: .serif))
                        .foregroundColor(Color("AppPrimary"))
                }
                .padding(.vertical, 10)
                Hairline()
                if let latest = store.latestActive {
                    NavigationLink {
                        NoteDetailView(note: latest)
                    } label: {
                        LeaderRow(number: "00", title: "Continue", subtitle: latest.title)
                    }
                    .buttonStyle(.plain)
                    Hairline()
                }
                NavigationLink {
                    NotesGalleryView()
                } label: {
                    LeaderRow(number: "01", title: "Room notes", subtitle: "\(store.activeNotes.count) spaces on file")
                }
                .buttonStyle(.plain)
                Hairline()
                NavigationLink {
                    CaptionStudioView()
                } label: {
                    LeaderRow(number: "02", title: "Captions", subtitle: "\(store.livingCaptions.count) annotations")
                }
                .buttonStyle(.plain)
                Hairline()
                NavigationLink {
                    InspirationView()
                } label: {
                    LeaderRow(number: "03", title: "Discover", subtitle: "\(store.favorites.count) pinned cuts")
                }
                .buttonStyle(.plain)
                Hairline()
                NavigationLink {
                    LedgerView()
                } label: {
                    LeaderRow(number: "04", title: "Ledger", subtitle: "Studio counts and graphs")
                }
                .buttonStyle(.plain)
                Hairline()
                NavigationLink {
                    CompareRoomsView()
                } label: {
                    LeaderRow(number: "05", title: "Compare", subtitle: "Two rooms on one plate")
                }
                .buttonStyle(.plain)
                Hairline()
                NavigationLink {
                    BoardsView()
                } label: {
                    LeaderRow(number: "06", title: "Boards", subtitle: "\(store.boards.count) local collections")
                }
                .buttonStyle(.plain)
                Hairline()
                NavigationLink {
                    SettingsView()
                } label: {
                    LeaderRow(number: "07", title: "Desk", subtitle: "Rate, privacy, terms")
                }
                .buttonStyle(.plain)
                Hairline()
            }
            .padding(22)
        }
        .canvasBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}
