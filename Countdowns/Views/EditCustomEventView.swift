//
//  EditCustomEventView.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2023-10-08.
//

import SwiftUI
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
    
    init(event: Event) {
        self.event = event
        self.symbol = Symbol(rawValue: event.iconURL ?? "")
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Title", text: Binding(get: {
                    event.title ?? ""
                }, set: { newValue in
                    event.title = newValue
                }))
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
            Section {
                ColorPickerRow(selected: $event.colorName)
            }
            Section {
                SymbolPicker(selected: $symbol)
            }
            Section {
                Button("Delete", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }
        }
        .navigationTitle("Edit Event")
        .navigationBarTitleDisplayMode(.inline)
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
            if case .recurrence(month: _, day: _, end: nil) = event.dataSource {
                self.repeatYearly = true
                self.endRepeat = false
                self.repeatEndDate = .now
            } else if case .recurrence(month: _, day: _, end: repeatEndDate) = event.dataSource {
                self.repeatYearly = true
                self.endRepeat = true
                self.repeatEndDate = repeatEndDate
            }
        }
        .onDisappear {
            let day = Calendar.autoupdatingCurrent.dateComponents([.month, .day], from: event.date ?? .now)
            let dataSource: Event.DataSource? = {
                let end: Date? = endRepeat ? repeatEndDate : nil
                return repeatYearly ? .recurrence(month: day.month!, day: day.day!, end: end) : nil
            }()
            event.dataSource = dataSource
            // Ensure we don't override a preset (unselectable) symbol
            if let symbol {
                event.icon = .symbolIcon(name: symbol.rawValue)
            }
            Task {
                await event.fetch()
            }
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
    }
}

#Preview {
    EditCustomEventView(event: Event(dataSource: nil, title: "Content", colorName: nil, icon: .symbolIcon(name: "circle"), date: .now, dateIsEstimate: false))
}
