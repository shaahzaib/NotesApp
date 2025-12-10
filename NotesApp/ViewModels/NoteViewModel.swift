//
//  NoteViewModel.swift
//  NotesApp
//
//  Created by Macbook Pro on 10/12/2025.
//

import Foundation
import CoreData
import SwiftUI
import Combine

class NoteViewModel: ObservableObject {
    @Published var notes: [Note] = []

    let container: NSPersistentContainer

    // Predefined categories
    let categories = ["Personal", "Work", "Study", "Ideas"]
        var categoriesWithAll: [String] { ["All"] + categories }

    init() {
        container = NSPersistentContainer(name: "DBModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error loading CoreData:", error)
            }
        }
        fetchNotes()
    }

    // MARK: - Notes

    func fetchNotes() {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.dateCreated, ascending: false)]

        do {
            notes = try container.viewContext.fetch(request)
        } catch {
            print("Error fetching notes:", error)
        }
    }

    func addNote(title: String, content: String, category: String?) {
        let newNote = Note(context: container.viewContext)
        newNote.id = UUID()
        newNote.title = title
        newNote.content = content
        newNote.dateCreated = Date()
        newNote.category = category
        saveNotes()
    }

    func updateNote(note: Note, title: String, content: String, category: String?) {
        note.title = title
        note.content = content
        note.category = category
        saveNotes()
    }

    func deleteNote(indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let note = notes[index]
        container.viewContext.delete(note)
        saveNotes()
    }

    func saveNotes() {
        do {
            try container.viewContext.save()
            fetchNotes()
        } catch {
            print("Error saving notes:", error)
        }
    }
}
