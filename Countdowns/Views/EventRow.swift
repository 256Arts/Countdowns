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
                #if os(visionOS) || os(macOS)
                .frame(width: 50)
                #else
                .frame(width: 80)
                #endif
            
            switch event.icon {
            case .symbolIcon(name: let name):
                Image(systemName: name)
                    .symbolVariant(.fill)
                    .foregroundStyle(event.colorName?.color.gradient ?? Color.accentColor.gradient)
                    .imageScale(.large)
                    .frame(minWidth: 32)
            case .remote(let url):
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Color.secondary
                }
                .aspectRatio(contentMode: .fit)
                .clipShape(.rect(cornerRadius: 6))
                #if os(macOS)
                .frame(width: 24, height: 36)
                #else
                .frame(width: 40, height: 60)
                #endif
            case .preloaded, nil:
                EmptyView()
            }
            
            VStack(alignment: .leading) {
                Text(event.title ?? "")
                    .lineLimit(1)
                    .font(.title2)
                Text(event.date ?? .distantFuture, style: .date)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    EventRow(event: Event(dataSource: nil, title: "Content", colorName: nil, icon: .symbolIcon(name: "circle"), date: .now, dateIsEstimate: false))
}
