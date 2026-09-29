import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

struct NewDateEstimateView: View {
    
    @Bindable var event: Event
    
    @Environment(\.dismiss) var dismiss
    
    @State var dateEstimate = Date.now
    
    var body: some View {
        Form {
            Section {
                DatePicker("Date Estimate", selection: $dateEstimate, displayedComponents: .date)
            }
            Section {
                Label("This estimated event will be shown until we find a confirmed release date to replace it.", systemImage: "info.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", systemImage: "checkmark") {
                    event.date = dateEstimate
                    event.dateIsEstimate = true
                    #if canImport(WidgetKit)
                    WidgetCenter.shared.reloadAllTimelines()
                    #endif
                    dismiss()
                }
            }
        }
        .navigationTitle("\(event.title ?? "") Estimate")
    }
}

#Preview {
    NewDateEstimateView(event: Event(dataSource: nil, title: "Event", colorName: nil, icon: .symbolIcon(name: "circle"), date: nil, dateIsEstimate: false))
}
