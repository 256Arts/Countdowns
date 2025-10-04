//
//  NewCustomEventView.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-12-06.
//

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
    
    var body: some View {
        List {
            Section {
                TextField("Title", text: $title)
                    .font(.largeTitle)
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
    }
}

#Preview {
    NewCustomEventView()
}
