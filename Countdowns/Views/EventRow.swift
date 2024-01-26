//
//  EventRow.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2023-10-08.
//

import SwiftUI

struct EventRow: View {
    
    let event: Event
    
    var body: some View {
        HStack {
            Text(event.daysUntilString)
                .lineLimit(1)
                .allowsTightening(true)
                .minimumScaleFactor(0.5)
                .font(.title)
                #if os(visionOS) || targetEnvironment(macCatalyst)
                .frame(width: 50)
                #else
                .frame(width: 80)
                #endif
            
            switch event.icon {
            case .symbolIcon(name: let name):
                Image(systemName: name)
                    .symbolVariant(.fill)
                    .foregroundStyle(Color.accentColor.gradient)
                    .imageScale(.large)
                    .frame(minWidth: 32)
            case .remote(let url):
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Color.secondary
                }
                .aspectRatio(contentMode: .fit)
                .cornerRadius(6)
                .frame(width: 40, height: 60)
            case .preloaded, nil:
                EmptyView()
            }
            
            VStack(alignment: .leading) {
                Text(event.title ?? "")
                    .lineLimit(1)
                    .font(.title2)
                Text(event.date ?? .distantFuture, style: .date)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    EventRow(event: Event(dataSource: nil, title: "Content", colorHEX: nil, icon: .symbolIcon(name: "circle"), date: .now, dateIsEstimate: false))
}
