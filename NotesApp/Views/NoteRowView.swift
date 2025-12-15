//
//  NoteRowView.swift
//  NotesApp
//
//  Created by Macbook Pro on 12/12/2025.
//

import SwiftUI

struct NoteRowView: View {
    let note : Note
    var body: some View {
        VStack(alignment: .leading) {
            Text(note.title ?? "Untitled")
                .font(.headline)
                .foregroundStyle(.black)
            Text(note.content ?? "")
                .foregroundColor(.gray)
                .lineLimit(1)
            
            HStack{
                if let category = note.category {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                if let date = note.dateCreated {
                    Text("Created: \(formattedDate(date))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
        }
        .padding(.vertical,6)
    }
}


