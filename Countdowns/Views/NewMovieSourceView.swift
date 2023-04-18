//
//  NewMovieSourceView.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-12-08.
//

import SwiftUI

struct NewMovieSourceView: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var eventsData: EventsData
    
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
                
                if !eventsData.events.contains(where: { $0.id == String(media.id) }) {
                    Button("ADD") {
                        let icon: ImageResource = {
                            if let url = media.posterURL {
                                return .remote(url)
                            } else {
                                return .symbolIcon(name: media.isMovie ? "film" : "tv")
                            }
                        }()
                        let dataSource: Event.DataSource = media.isMovie ? .movie(id: media.id) : .tvShow(id: media.id)
                        eventsData.events.append(
                            Event(id: String(media.id), dataSource: dataSource, title: media.title, colorHEX: nil, icon: icon, date: media.releaseDate, dateIsEstimate: false))
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .fontWeight(.bold)
                }
            }
        }
        .searchable(text: $searchString, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search movies/tv")
        .navigationTitle("New Movie/TV Event")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: searchString) { newValue in
            Task {
                results = try await MediaDatabase.shared.search(newValue)
            }
        }
    }
}

struct NewMovieSourceView_Previews: PreviewProvider {
    static var previews: some View {
        NewMovieSourceView()
    }
}
