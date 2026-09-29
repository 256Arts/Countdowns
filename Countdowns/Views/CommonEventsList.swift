import SwiftUI
import SwiftData
import StoreKit
#if canImport(WidgetKit)
import WidgetKit
#endif

struct CommonEventsList: View {
    
    let allEvents = CommonEvents.events()
    var results: [Event] {
        if searchString.isEmpty {
            return allEvents
        } else {
            return allEvents.filter({ $0.title?.localizedCaseInsensitiveContains(searchString) ?? false })
        }
    }
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Query private var events: [Event]
    
    @State var searchString = ""
    
    var body: some View {
        List(results) { event in
            HStack {
                VStack(alignment: .leading) {
                    Text(event.title ?? "")
                        .font(.title2)
                    Text(event.subtitle)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                let isAdded = events.contains(where: { $0.isSameSource(as: event) })
                Button(isAdded ? "Added" : "Add", systemImage: isAdded ? "checkmark" : "plus") {
                    let existingEvents = events.filter({ $0.isSameSource(as: event) })
                    if existingEvents.isEmpty {
                        Task { @MainActor in
                            await event.fetch()
                            modelContext.insert(event)
                            // Increment add count and maybe ask for a review
                            if UserDefaults.standard.incrementEventAddedCount() { requestReview() }
                            #if canImport(WidgetKit)
                            WidgetCenter.shared.reloadAllTimelines()
                            #endif
                        }
                    } else {
                        for existingEvent in existingEvents {
                            modelContext.delete(existingEvent)
                            #if canImport(WidgetKit)
                            WidgetCenter.shared.reloadAllTimelines()
                            #endif
                        }
                    }
                }
                .buttonStyle(.bordered)
                .contentTransition(.symbolEffect(.replace))
            }
        }
        .navigationTitle("Common Events")
        .searchable(text: $searchString, prompt: "Search")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    CommonEventsList()
}
