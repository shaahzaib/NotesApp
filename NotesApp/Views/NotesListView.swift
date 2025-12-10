//
//  NotesListView.swift
//  NotesApp
//
//  Created by Macbook Pro on 10/12/2025.
//


import SwiftUI

struct NotesListView: View {
    @StateObject private var vm = NoteViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(vm.notes, id: \.self) { note in
                    NavigationLink {
                        AddEditNoteView(vm: vm, noteToEdit: note)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(note.title ?? "Untitled")
                                .font(.headline)
                            Text(note.content ?? "")
                                .font(.subheadline)
                                .lineLimit(2)
                                .foregroundColor(.gray)
                            if let date = note.dateCreated {
                                Text("Created: \(formattedDate(date))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: vm.deleteNote)
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AddEditNoteView(vm: vm, noteToEdit: nil)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    NotesListView()
}
