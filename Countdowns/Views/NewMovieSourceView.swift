//
//  NewMovieSourceView.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-12-08.
//

import SwiftUI
import SwiftData
#if canImport(WidgetKit)
import WidgetKit
#endif

struct NewMovieSourceView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var events: [Event]
    
    @State var searchString = ""
    @State var results: [Media] = []
    
    var body: some View {
        List(results) { media in
            HStack(spacing: 12) {
                AsyncImage(url: media.posterURL) { image in
                    image.resizable()
                } placeholder: {
                    Color.secondary
                }
                .aspectRatio(contentMode: .fit)
                .cornerRadius(6)
                .frame(width: 40, height: 60)
                
                VStack(alignment: .leading) {
                    Text(media.title)
                        .lineLimit(2)
                    if let date = media.releaseDate {
                        Text(date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !events.contains(where: { $0.dataSource == media.dataSource }) {
                    Button("ADD") {
                        let icon: IconResource = {
                            if let url = media.posterURL {
                                return .remote(url)
                            } else {
                                return .symbolIcon(name: media.isMovie ? "film" : "tv")
                            }
                        }()
                        modelContext.insert(
                            Event(dataSource: media.dataSource, title: media.title, colorHEX: nil, icon: icon, date: media.releaseDate, dateIsEstimate: false))
                        #if canImport(WidgetKit)
                        WidgetCenter.shared.reloadAllTimelines()
                        #endif
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .fontWeight(.bold)
                }
            }
        }
        .navigationTitle("New Movie/TV Event")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        #if os(macOS)
        .searchable(text: $searchString, prompt: "Search movies/tv")
        #else
        .searchable(text: $searchString, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search movies/tv")
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onChange(of: searchString) { _, newValue in
            Task {
                results = try await MediaDatabase.shared.search(newValue)
            }
        }
    }
}

#Preview {
    NewMovieSourceView()
}
