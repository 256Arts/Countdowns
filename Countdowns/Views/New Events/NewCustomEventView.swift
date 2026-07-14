import SwiftUI
import StoreKit
#if canImport(WidgetKit)
import WidgetKit
#endif

struct NewCustomEventView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.requestReview) private var requestReview
    
    @State var title = ""
    @State var date: Date = .now
    @State var isEstimate = false
    @State var repeatYearly = false
    @State var endRepeat = false
    @State var repeatEndDate: Date = .now
    @State var colorName: ColorName?
    @State var symbol: Symbol? = .defaultSymbol

    /// True while Apple Intelligence is looking up a date for the current title.
    @State private var isSuggestingDate = false
    /// A date, color, and icon Apple Intelligence guessed for the title, offered as a one-tap suggestion.
    @State private var suggestion: EventDateSuggester.Suggestion?
    /// Set once the user accepts a suggestion, so we stop offering new ones for this event.
    @State private var didAcceptSuggestion = false

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Title", text: $title)
                        .font(.largeTitle)
                    if isSuggestingDate {
                        ProgressView()
                    }
                }
                if let suggestion {
                    Button {
                        title = suggestion.title
                        date = suggestion.date
                        repeatYearly = suggestion.repeatsYearly
                        if let suggestedColor = suggestion.colorName { colorName = suggestedColor }
                        if let suggestedSymbol = suggestion.symbol { symbol = suggestedSymbol }
                        isEstimate = true
                        self.suggestion = nil
                        didAcceptSuggestion = true
                    } label: {
                        LabeledContent {
                            Text(suggestion.date.formatted(date: .abbreviated, time: .omitted))
                        } label: {
                            Label(suggestion.title, systemImage: "apple.intelligence")
                        }
                    }
                }
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Toggle("Estimated", isOn: $isEstimate)
                Toggle("Repeat yearly", isOn: $repeatYearly)
                if repeatYearly {
                    Toggle("End Repeat", isOn: $endRepeat)
                    if endRepeat {
                        DatePicker("End Date", selection: $repeatEndDate, displayedComponents: .date)
                    }
                }
            }
            Section {
                ColorPickerRow(selected: $colorName)
            }
            Section {
                SymbolPicker(selected: $symbol)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add", systemImage: "checkmark") {
                    let day = Calendar.autoupdatingCurrent.dateComponents([.month, .day], from: date)
                    let dataSource: Event.DataSource? = {
                        let end: Date? = endRepeat ? repeatEndDate : nil
                        return repeatYearly ? .recurrence(month: day.month!, day: day.day!, end: end) : nil
                    }()
                    let icon: IconResource? = if let symbol {
                        .symbolIcon(name: symbol.rawValue)
                    } else {
                        nil
                    }
                    let event = Event(dataSource: dataSource, title: title, colorName: colorName, icon: icon, date: date, dateIsEstimate: false)
                    Task {
                        await event.fetch()
                    }
                    modelContext.insert(event)
                    
                    // Increment add count and maybe ask for a review
                    if UserDefaults.standard.incrementEventAddedCount() { requestReview() }
                    
                    #if canImport(WidgetKit)
                    WidgetCenter.shared.reloadAllTimelines()
                    #endif
                    dismiss()
                }
                .disabled(title.isEmpty)
            }
        }
        .navigationTitle("New Event")
        .task(id: title) {
            await suggest()
        }
    }

    /// Waits for a 0.5s pause in typing, then asks Apple Intelligence for the most likely
    /// upcoming date, color, and icon for the title and offers them as a one-tap suggestion.
    /// Restarted on every keystroke (`.task(id: title)`), so the sleep is cancelled while the
    /// user is still typing.
    private func suggest() async {
        // Once the user has accepted a suggestion, don't offer more for this event.
        guard !didAcceptSuggestion else { return }

        // Clear any stale suggestion from a previous title.
        suggestion = nil

        let query = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard 2 <= query.count else { return }

        try? await Task.sleep(for: .seconds(0.5))
        guard !Task.isCancelled else { return }

        isSuggestingDate = true
        defer { isSuggestingDate = false }

        guard let result = await EventDateSuggester.suggestion(for: query) else { return }
        // The title may have changed while we were waiting.
        guard !Task.isCancelled else { return }

        suggestion = result
    }
}

#Preview {
    NewCustomEventView()
}
