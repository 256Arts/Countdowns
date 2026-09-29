import SwiftUI
import SwiftData
#if canImport(WidgetKit)
import WidgetKit
#endif

struct EditCustomEventView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Bindable var event: Event
    
    @State var repeatYearly = false
    @State var endRepeat = false
    @State var repeatEndDate: Date = .now
    @State var symbol: Symbol?
    
    @State var showingDeleteConfirmation = false
    
    /// Imported calendar events follow their calendar: only the look is editable here, and it
    /// applies to the whole calendar, since regeneration copies it from any of its events.
    private var calendarID: String? {
        if case .calendar(let id) = event.dataSource { id } else { nil }
    }
    
    var body: some View {
        List {
            if calendarID == nil {
                Section {
                    TextField("Title", text: Binding(get: {
                        event.title ?? ""
                    }, set: { newValue in
                        event.title = newValue
                    }))
                    .font(.largeTitle)
                    DatePicker("Date", selection: Binding(get: {
                        event.date ?? .now
                    }, set: { newValue in
                        event.date = newValue
                    }), displayedComponents: .date)
                    Toggle("Estimated", isOn: Binding(get: {
                        event.dateIsEstimate ?? false
                    }, set: { newValue in
                        event.dateIsEstimate = newValue
                    }))
                    Toggle("Repeat yearly", isOn: $repeatYearly)
                    if repeatYearly {
                        Toggle("End Repeat", isOn: $endRepeat)
                        if endRepeat {
                            DatePicker("End Date", selection: $repeatEndDate, displayedComponents: .date)
                        }
                    }
                }
            }
            Section {
                ColorPickerRow(selected: $event.colorName)
            } footer: {
                if calendarID != nil {
                    Text("Applies to every event from this calendar.")
                }
            }
            Section {
                SymbolPicker(selected: $symbol)
            }
            if calendarID == nil {
                Section {
                    Button("Delete", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                }
            }
        }
        #if !os(macOS)
        .navigationTitle("Details")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Done", systemImage: "checkmark") {
                    dismiss()
                }
                .disabled(event.title?.isEmpty == true)
            }
        }
        #endif
        .confirmationDialog("Delete Event?", isPresented: $showingDeleteConfirmation, actions: {
            Button("Delete", role: .destructive) {
                modelContext.delete(event)
                dismiss()
                #if canImport(WidgetKit)
                WidgetCenter.shared.reloadAllTimelines()
                #endif
            }
        })
        .onAppear {
            symbol = Symbol(rawValue: event.iconURL ?? "")
            if case .recurrence(month: _, day: _, let end) = event.dataSource {
                repeatYearly = true
                endRepeat = end != nil
                repeatEndDate = end ?? .now
            }
        }
        .onDisappear {
            if let symbol {
                event.icon = .symbolIcon(name: symbol.rawValue)
            }
            if let calendarID {
                applyLookToCalendar(id: calendarID)
            } else {
                applyDataSource()
            }
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
    }
    
    private func applyLookToCalendar(id: String) {
        let events = (try? modelContext.fetch(FetchDescriptor<Event>())) ?? []
        for other in events where other.dataSource == .calendar(id: id) {
            other.colorName = event.colorName
            other.icon = event.icon
        }
    }
    
    private func applyDataSource() {
        let day = Calendar.autoupdatingCurrent.dateComponents([.month, .day], from: event.date ?? .now)
        let dataSource: Event.DataSource? = {
            let end: Date? = endRepeat ? repeatEndDate : nil
            return repeatYearly ? .recurrence(month: day.month!, day: day.day!, end: end) : nil
        }()
        event.dataSource = dataSource
        Task {
            await event.fetch()
        }
    }
}

#Preview {
    EditCustomEventView(event: Event(dataSource: nil, title: "Content", colorName: nil, icon: .symbolIcon(name: "circle"), date: .now, dateIsEstimate: false))
}

