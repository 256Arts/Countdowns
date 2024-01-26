//
//  FullScreenEventView.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-07-30.
//

import SwiftUI

struct FullScreenEventView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var event: Event
    
    var body: some View {
        VStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .trailing)
            
            switch event.icon {
            case .symbolIcon(name: let name):
                HStack {
                    Image(systemName: name)
                        .symbolVariant(.fill)
                        .foregroundStyle(Color.accentColor.gradient)
                    
                    Text(event.title ?? "")
                }
                .font(.largeTitle)
            case .remote(let url):
                Text(event.title ?? "")
                    .font(.largeTitle)
                
                AsyncImage(url: URL(string: url.absoluteString.replacingOccurrences(of: "/w185/", with: "/w500/"))!) { image in
                    image.resizable()
                } placeholder: {
                    Color.secondary
                }
                .aspectRatio(contentMode: .fit)
                .cornerRadius(20)
                .frame(width: 300, height: 450)
            case .preloaded, nil:
                EmptyView()
            }
            
            Spacer()
            
            if let date = event.date {
                VStack {
                    if event.dateIsEstimate == true {
                        Text("Expected:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Text(event.daysUntilString + " days")
                        .font(.largeTitle)
                    Text(date, style: .date)
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
            }
            
            Spacer()
            
            if case .recurrence = event.dataSource {
                Text("Repeats Yearly")
                    .foregroundColor(.secondary)
            }
        }
        .scenePadding()
        .frame(idealWidth: .infinity, maxWidth: .infinity)
        .background {
            if case .remote(let url) = event.icon {
                AsyncImage(url: URL(string: url.absoluteString.replacingOccurrences(of: "/w185/", with: "/w500/"))!) { image in
                    image.resizable()
                } placeholder: {
                    EmptyView()
                }
                .aspectRatio(contentMode: .fill)
                .overlay(Material.thin)
                .ignoresSafeArea()
            } else {
                #if !os(visionOS)
                Color.black.ignoresSafeArea()
                #endif
            }
        }
        .environment(\.colorScheme, .dark)
    }
}

#Preview {
    FullScreenEventView(event: Event(dataSource: nil, title: "Content", colorHEX: nil, icon: .symbolIcon(name: "circle"), date: .now, dateIsEstimate: false))
}
