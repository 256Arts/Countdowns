import SwiftUI
import SwiftData
#if !os(watchOS)
import AppIntents
#endif

struct FullScreenEventView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage(UserDefaults.Key.countdownFormat) private var countdownFormat = CountdownFormat.default
    
    #if !os(watchOS)
    @State private var showingEditor = false
    #endif
    
    #if os(watchOS)
    private let headerFont = Font.title3.bold()
    private let posterSpacing: CGFloat = 4
    #else
    private let headerFont = Font.largeTitle.bold()
    private let posterSpacing: CGFloat = 16
    #endif
    
    @Bindable var event: Event
    
    var body: some View {
        VStack {
            #if !os(watchOS)
            Spacer()
                .frame(height: 40)
            #endif
            
            switch event.icon {
            case .symbolIcon(name: let name):
                HStack {
                    Image(systemName: name)
                        .symbolVariant(.fill)
                        .foregroundStyle(event.colorName?.color.gradient ?? Color.accentColor.gradient)
                    
                    Text(event.title ?? "")
                }
                .font(headerFont)
            case .remote(let url):
                Text(event.title ?? "")
                    .font(headerFont)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, posterSpacing)
                
                AsyncImage(url: url.poster(size: .large)) { image in
                    image.resizable()
                } placeholder: {
                    Color.secondary
                }
                .aspectRatio(contentMode: .fit)
                #if os(watchOS)
                .clipShape(.rect(cornerRadius: 8))
                .frame(maxHeight: 90)
                #else
                .clipShape(.rect(cornerRadius: 20))
                .frame(minWidth: 200, idealWidth: 300, minHeight: 300, idealHeight: 450)
                #endif
            case .preloaded, nil:
                EmptyView()
            }
            
            Spacer()
            
            if let date = event.date {
                VStack {
                    if event.dateIsEstimate == true {
                        Text("Expected:")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    // Minutes and seconds go stale the moment they are drawn, so a format that
                    // reaches that far redraws itself on a timer.
                    if let interval = countdownFormat.refreshInterval {
                        TimelineView(.periodic(from: .now, by: interval)) { context in
                            countdownText(now: context.date)
                        }
                    } else {
                        countdownText(now: .now)
                    }
                    Text(date, style: .date)
                        .foregroundStyle(.secondary)
                        #if os(watchOS)
                        .font(.footnote)
                        #else
                        .font(.title2)
                        #endif
                }
            }
            
            Spacer()
            
            if case .recurrence = event.dataSource {
                Text("Repeats Yearly")
                    .foregroundStyle(.secondary)
            }
        }
        .scenePadding()
        .frame(idealWidth: .infinity, maxWidth: .infinity)
        #if !os(visionOS)
        .background {
            if case .remote(let url) = event.icon {
                AsyncImage(url: url.poster(size: .large)) { image in
                    image.resizable()
                } placeholder: {
                    EmptyView()
                }
                .scaledToFill()
                .overlay(Material.thin)
                .ignoresSafeArea()
            } else {
                ZStack {
                    event.colorName?.color
                    Color.black.opacity(0.75)
                }
                .ignoresSafeArea()
            }
        }
        #endif
        .preferredColorScheme(.dark)
        #if !os(watchOS)
        .toolbar {
            if event.isEditable {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showingEditor = true
                    }
                    .popover(isPresented: $showingEditor, attachmentAnchor: .rect(.bounds), arrowEdge: .trailing) {
                        #if os(macOS)
                        EditCustomEventView(event: event)
                            .frame(idealHeight: 400)
                        #else
                        NavigationStack {
                            EditCustomEventView(event: event)
                        }
                        .frame(idealWidth: 360, idealHeight: 700)
                        #endif
                    }
                }
            }
        }
        // Tell Siri which countdown is on screen, so "how many days until this?" resolves to it.
        .userActivity("com.256arts.countdowns.viewing-event", element: event.asEntity()) { entity, activity in
            activity.title = event.title
            activity.appEntityIdentifier = .init(for: entity)
        }
        #endif
    }
    
    private func countdownText(now: Date) -> some View {
        Text(event.countdownString(format: countdownFormat, now: now))
            .font(.largeTitle.bold())
            .lineLimit(1)
            .allowsTightening(true)
            .minimumScaleFactor(0.5)
    }
}

#Preview {
    FullScreenEventView(event: Event(dataSource: nil, title: "Content", colorName: nil, icon: .symbolIcon(name: "circle"), date: .now, dateIsEstimate: false))
}
