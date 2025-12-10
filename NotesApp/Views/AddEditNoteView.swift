//
//  AddEditNoteView.swift
//  NotesApp
//
//  Created by Macbook Pro on 10/12/2025.
//


import SwiftUI

struct AddEditNoteView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var vm: NoteViewModel
    var noteToEdit: Note?
    
    @State private var title: String
    @State private var content: String
    
    init(vm: NoteViewModel, noteToEdit: Note?) {
        self.vm = vm
        self.noteToEdit = noteToEdit
        _title = State(initialValue: noteToEdit?.title ?? "")
        _content = State(initialValue: noteToEdit?.content ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Title") {
                    TextField("Enter title", text: $title)
                }
                
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }
                
                // Show creation date in edit mode
                if let date = noteToEdit?.dateCreated {
                    Section {
                        Text("Created: \(formattedDate(date))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle(noteToEdit == nil ? "Add Note" : "Edit Note")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveNote() {
        if let noteToEdit = noteToEdit {
            // Update existing
            noteToEdit.title = title
            noteToEdit.content = content
            vm.saveNotes()
        } else {
            // Add new
            let newNote = NoteModel(title: title, content: content, dateCreated: Date())
            vm.addNote(note: newNote)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
