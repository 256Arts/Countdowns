//
//  NewCustomEventView.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-12-06.
//

import SwiftUI

struct NewCustomEventView: View {
    
    @EnvironmentObject var eventsData: EventsData
    @Environment(\.dismiss) var dismiss
    
    @State var title = ""
    @State var date: Date = .now
    @State var isEstimate = false
    @State var repeatYearly = false
    @State var endRepeat = false
    @State var repeatEndDate: Date = .now
    @State var color = Color.accentColor
    @State var symbol = Symbol.defaultSymbol
    
    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Toggle("Estimated", isOn: $isEstimate)
                Toggle("Repeat yearly", isOn: $repeatYearly)
                if repeatYearly {
                    Toggle("End Repeat", isOn: $endRepeat)
                    DatePicker("End Date", selection: $repeatEndDate, displayedComponents: .date)
                }
            }
//            Section {
//                ColorPickerRow(selected: $color)
//            }
            Section {
                SymbolPicker(selected: $symbol)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    let day = Calendar.current.dateComponents([.month, .day], from: date)
                    let dataSource: Event.DataSource? = {
                        let end: Date? = endRepeat ? repeatEndDate : nil
                        return repeatYearly ? .recurrence(month: day.month!, day: day.day!, end: end) : nil
                    }()
                    let event = Event(id: UUID().uuidString, dataSource: dataSource, title: title, colorHEX: nil, icon: .symbolIcon(name: symbol.rawValue), date: date, dateIsEstimate: false)
                    Task {
                        await event.fetch()
                    }
                    eventsData.events.append(event)
                    dismiss()
                }
                .disabled(title.isEmpty)
            }
        }
        .navigationTitle("New Event")
    }
}

struct NewCustomEventView_Previews: PreviewProvider {
    static var previews: some View {
        NewCustomEventView()
    }
}
