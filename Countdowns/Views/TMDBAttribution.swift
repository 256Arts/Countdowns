import SwiftUI

/// The notice and logo TMDB's API terms require wherever the app credits its data sources.
struct TMDBAttribution: View {

    var body: some View {
        Link(destination: URL(string: "https://www.themoviedb.org")!) {
            VStack(alignment: .leading, spacing: 8) {
                Image("TMDB Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 12)
                    .accessibilityLabel("TMDB")
                Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(.plain)
    }

}

#Preview {
    TMDBAttribution()
        .padding()
}
