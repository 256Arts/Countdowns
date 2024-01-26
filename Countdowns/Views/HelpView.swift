//
//  HelpView.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2024-01-25.
//

import SwiftUI

struct HelpView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Link(destination: URL(string: "https://www.256arts.com/")!) {
                Label("Developer Website", systemImage: "safari")
            }
            Link(destination: URL(string: "https://www.256arts.com/joincommunity/")!) {
                Label("Join Community", systemImage: "bubble.left.and.bubble.right")
            }
            Link(destination: URL(string: "https://github.com/256Arts/Countdowns")!) {
                Label("Contribute on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        }
        .navigationTitle("Help")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    HelpView()
}
