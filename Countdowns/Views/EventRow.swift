import SwiftUI

struct EventRow: View {
    
    let event: Event
    
    var body: some View {
        HStack {
            Text(event.daysUntilString)
                .lineLimit(1)
                .allowsTightening(true)
                .minimumScaleFactor(0.5)
                #if os(watchOS)
                .font(.title3)
                .frame(width: 40)
                #else
                .font(.title)
                #endif
                #if os(visionOS) || os(macOS)
                .frame(width: 50)
                #elseif !os(watchOS)
                .frame(width: 80)
                #endif
            
            switch event.icon {
            case .symbolIcon(name: let name):
                Image(systemName: name)
                    .symbolVariant(.fill)
                    .foregroundStyle(event.colorName?.color.gradient ?? Color.accentColor.gradient)
                    #if os(watchOS)
                    .frame(minWidth: 20)
                    #else
                    .imageScale(.large)
                    .frame(minWidth: 32)
                    #endif
            case .remote(let url):
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Color.secondary
                }
                .aspectRatio(contentMode: .fit)
                .clipShape(.rect(cornerRadius: 6))
                #if os(macOS) || os(watchOS)
                .frame(width: 24, height: 36)
                #else
                .frame(width: 40, height: 60)
                #endif
            case .preloaded, nil:
                EmptyView()
            }
            
            VStack(alignment: .leading) {
                #if os(watchOS)
                Text(event.title ?? "")
                    .lineLimit(2)
                    .font(.headline)
                Text(event.date ?? .distantFuture, format: .dateTime.month().day())
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                #else
                Text(event.title ?? "")
                    .lineLimit(1)
                    .font(.title2)
                Text(event.date ?? .distantFuture, style: .date)
                    .foregroundStyle(.secondary)
                #endif
            }
        }
    }
}

#Preview {
    EventRow(event: Event(dataSource: nil, title: "Content", colorName: nil, icon: .symbolIcon(name: "circle"), date: .now, dateIsEstimate: false))
}
