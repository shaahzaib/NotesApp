//
//  NoteRowView.swift
//  NotesApp
//
//  Created by Macbook Pro on 12/12/2025.
//

import SwiftUI

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title ?? "Untitled")
                .font(.headline)
            Text(note.content ?? "")
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
            if let category = note.category, !category.isEmpty {
                Text(category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
    }
}


