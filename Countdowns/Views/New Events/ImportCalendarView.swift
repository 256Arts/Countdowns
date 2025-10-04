import SwiftUI
import SwiftData
import StoreKit
import EventKit
#if canImport(WidgetKit)
import WidgetKit
#endif

struct ImportCalendarView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Query private var allEvents: [Event]
    
    private var calendarService: CalendarService = .shared
    
    @State private var allCalendars: [EKCalendar] = []
    @State private var selection: EKCalendar?
    @State private var showingError = false
    @State private var error: EventStoreError?
    @State var colorName: ColorName?
    @State var symbol: Symbol? = .defaultSymbol
    
    var body: some View {
        List {
            Section {
                Picker("Calendar", selection: $selection) {
                    ForEach(allCalendars, id: \.calendarIdentifier) { calendar in
                        Label {
                            Text(calendar.title)
                        } icon: {
                            Image(systemName: "circle")
                                .symbolVariant(.fill)
                                .foregroundStyle(Color(calendar.cgColor))
                        }
                        .tag(calendar as EKCalendar?)
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
                                dataSource: .calendar(id: selection.calendarIdentifier),
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
            _ = try await calendarService.store.verifyAuthorizationStatus()
            self.allCalendars = await calendarService.allCalendars
        } catch {
            self.error = error as? EventStoreError
            self.showingError = true
        }
    }
}

// Helper to build a SwiftUI Color from CGColor when available
fileprivate extension Color {
    init(_ cgColor: CGColor?) {
        #if canImport(UIKit)
        if let cg = cgColor { self = Color(UIColor(cgColor: cg)) } else { self = .accentColor }
        #else
        if let cg = cgColor { self = Color(NSColor(cgColor: cg) ?? .systemBlue) } else { self = .accentColor }
        #endif
    }
}

