import SwiftUI
import SwiftData

@main
struct CountdownsApp: App {

    /// Lets the macOS menu bar extra bring the main window forward.
    static let mainWindowID = "main"

    init() {
        UserDefaults.standard.register()

        #if os(macOS)
        if ScreenshotMode.isActive {
            ScreenshotMode.clearSavedWindowLayout()
        }
        #endif
    }

    @State private var navigation = AppNavigation.shared
    @State private var showingAppStoreEvent = false

    var body: some Scene {
        WindowGroup(id: Self.mainWindowID) {
            NavigationSplitView {
                UpcomingList()
                    // The day count takes a fixed slice of every row, so at the default column
                    // width an ordinary title like "Album Release" truncates.
                    .navigationSplitViewColumnWidth(min: 380, ideal: 380, max: 500)
            } detail: {
                NavigationStack {
                    if let selectedEvent = navigation.selectedEvent {
                        FullScreenEventView(event: selectedEvent)
                    } else {
                        Text("No Content Selected")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            // A screenshot run hangs what it seeded here, where the walk can read it back.
            .screenshotModeStatus()
            .alert("Event Intro", isPresented: $showingAppStoreEvent) {
                Button("OK", role: .close) { }
            } message: {
                Text("Now let's celebrate by adding the event through the \"+\" menu, and trying out the new features!")
            }
            .onOpenURL { url in
                if url.path().contains("countdowns/appstoreevent") {
                    showingAppStoreEvent = true
                }
            }
        }
        .commands {
            CommandGroup(after: .help) {
                Self.links()
            }
        }
        .modelContainer(modelContainer)
        #if os(macOS)
        // Wide enough that the sidebar's countdowns and the detail column both have room; 500x300
        // left the split view too cramped to read either side.
        .defaultSize(width: 900, height: 600)
        #elseif os(visionOS)
        // Below about a thousand points the split view collapses and the sidebar disappears behind
        // the detail, so the list — the whole point of the app — is not on screen at launch.
        .defaultSize(width: 1100, height: 700)
        #else
        .defaultSize(width: 700, height: 600)
        #endif

        #if os(macOS)
        MenuBarExtra {
            MenuBarEventsMenu()
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.menu)
        .modelContainer(modelContainer)
        #endif
    }

    private var modelContainer: ModelContainer {
        // Screenshot runs get their own seeded in-memory store, on every platform and configuration,
        // so a shot never shows the machine's real countdowns.
        if ScreenshotMode.isActive {
            return ScreenshotMode.container
        }
        #if (targetEnvironment(simulator) || os(macOS)) && DEBUG
        return previewContainer
        #else
        return .shared
        #endif
    }

    #if DEBUG
    let previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try! ModelContainer(for: Event.self, configurations: config)

        for event in CommonEventsList().allEvents.filter({ !$0.dateIsEstimate! }) {
            container.mainContext.insert(event)
            Task {
                await event.fetch()
            }
        }
        
        return container
    }()
    #endif
    
    @ViewBuilder
    static func links() -> some View {
        Link(destination: URL(string: "https://www.256arts.com/")!) {
            Label("Developer Website", systemImage: "safari")
        }
        Link(destination: URL(string: "https://www.256arts.com/joincommunity/")!) {
            Label("Join Community", systemImage: "bubble.left.and.bubble.right")
        }
        Link(destination: URL(string: "https://github.com/256Arts/Countdowns")!) {
            Label("Contribute on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
        }
    }
    
}
