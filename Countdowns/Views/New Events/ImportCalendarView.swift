import SwiftUI
import SwiftData
import StoreKit
#if canImport(WidgetKit)
import WidgetKit
#endif

struct ImportCalendarView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Query private var allEvents: [Event]
    
    private var calendarService: CalendarService = .shared
    
    @State private var allCalendars: [CalendarSummary] = []
    @State private var selection: CalendarSummary?
    @State private var showingError = false
    @State private var error: EventStoreError?
    @State var colorName: ColorName?
    @State var symbol: Symbol? = .defaultSymbol
    
    var body: some View {
        List {
            Section {
                Picker("Calendar", selection: $selection) {
                    ForEach(allCalendars) { calendar in
                        Label {
                            Text(calendar.title)
                        } icon: {
                            Image(systemName: "circle")
                                .symbolVariant(.fill)
                                .foregroundStyle(calendar.color)
                        }
                        .tag(calendar as CalendarSummary?)
                        // Named for the screenshot walk, which otherwise matches a calendar called
                        // "Family" against the symbol named "family" further down the same screen.
                        .accessibilityIdentifier("Calendar.\(calendar.title)")
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
            Section {
                ColorPickerRow(selected: $colorName)
            }
            Section {
                SymbolPicker(selected: $symbol)
            }
        }
        .navigationTitle("Import Calendar")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark") { dismiss() }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Import", systemImage: "checkmark") {
                    guard let selection else { return }
                    
                    let icon: IconResource? = if let symbol {
                        .symbolIcon(name: symbol.rawValue)
                    } else {
                        nil
                    }
                    
                    modelContext
                        .insert(
                            Event(
                                dataSource: .calendar(id: selection.id),
                                title: "\"\(selection.title)\" Calendar Placeholder",
                                colorName: colorName,
                                icon: icon,
                                date: .distantPast,
                                dateIsEstimate: false
                            )
                        )
                    
                    // Increment add count and maybe ask for a review
                    if UserDefaults.standard.incrementEventAddedCount() { requestReview() }
                    
                    Task {
                        await calendarService.regenerateCalendarEvents(modelContext: modelContext, allEvents: allEvents)
                        #if canImport(WidgetKit)
                        WidgetCenter.shared.reloadAllTimelines()
                        #endif
                    }
                    dismiss()
                }
                .disabled(selection == nil)
            }
        }
        .alert(isPresented: $showingError, error: error, actions: {
            Button("OK", role: .cancel) { }
        })
        .task { await loadCalendars() }
    }
    
    private func loadCalendars() async {
        do {
            _ = try await calendarService.verifyAuthorizationStatus()
            self.allCalendars = await calendarService.allCalendars
        } catch {
            self.error = error as? EventStoreError
            self.showingError = true
        }
    }
}
