import SwiftUI

struct SettingsView: View {

    #if !os(macOS)
    @Environment(\.dismiss) private var dismiss
    #endif

    @AppStorage(UserDefaults.Key.countdownFormat) private var format = CountdownFormat.default
    @AppStorage(UserDefaults.Key.notifyOnEventDay) private var notifyOnEventDay = false
    @AppStorage(UserDefaults.Key.notifyDayBefore) private var notifyDayBefore = false
    @State private var notificationsDenied = false

    /// A fixed sample far enough out that every unit has something to show, so the preview changes
    /// only when the settings below it do.
    @State private var sample = Date.now..<Date.now.addingTimeInterval((400 * 24 * 60 * 60) + (4 * 60 * 60) + (48 * 60) + 33)

    var body: some View {
        Form {
            Section("Preview") {
                Text(format.string(from: sample.lowerBound, to: sample.upperBound))
                    .font(.title)
                    .lineLimit(1)
                    .allowsTightening(true)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity)
            }

            Section {
                ForEach(CountdownUnit.allCases) { unit in
                    Toggle(unit.name, isOn: binding(for: unit))
                        // Something has to be counted, so the last unit left on cannot be turned off.
                        .disabled(format.units == [unit])
                }
            } header: {
                Text("Units")
            } footer: {
                Text("Countdowns are spelled out using the largest of these units that the time remaining fills.")
            }

            Section {
                Stepper(value: $format.maxMixedUnits, in: 1...CountdownFormat.maxMixedUnitsLimit) {
                    LabeledContent("Units at Once", value: format.maxMixedUnits.formatted())
                }
            } footer: {
                Text("The most units shown together. Short names are used when several share a line.")
            }

            Section {
                Toggle("On the Day", isOn: $notifyOnEventDay)
                Toggle("The Day Before", isOn: $notifyDayBefore)
                    .disabled(!notifyOnEventDay)
            } header: {
                Text("Notifications")
            } footer: {
                if notificationsDenied {
                    Text("Allow notifications for Countdowns in Settings.")
                } else {
                    Text("Delivered at \(deliveryTime, format: .dateTime.hour().minute()).")
                }
            }
            .onChange(of: notifyOnEventDay) { _, isOn in
                guard isOn else { return }
                Task {
                    notificationsDenied = !(await NotificationScheduler.requestAuthorization())
                    if notificationsDenied {
                        notifyOnEventDay = false
                    }
                }
            }

            Section("Data Sources") {
                TMDBAttribution()
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        #if !os(macOS)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Done", systemImage: "checkmark") {
                    dismiss()
                }
            }
        }
        #endif
    }

    private var deliveryTime: Date {
        Calendar.autoupdatingCurrent.date(bySettingHour: NotificationScheduler.deliveryHour, minute: 0, second: 0, of: .now) ?? .now
    }

    private func binding(for unit: CountdownUnit) -> Binding<Bool> {
        Binding {
            format.units.contains(unit)
        } set: { isOn in
            if isOn {
                format.units.insert(unit)
            } else {
                format.units.remove(unit)
            }
        }
    }

}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
