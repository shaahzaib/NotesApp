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
    
    //pagination states
    private let pageSize = 30
    private var currentOffset = 0
    private var isLoading = false
    private var hasMoreData = true
    
    init() {
        container = NSPersistentContainer(name: "DBModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error loading CoreData:", error)
            }
        }
        loadinitialnotes()
    }
    
    func loadinitialnotes(){
        notes = []
        currentOffset = 0
        hasMoreData = true
        
        loadMoreNotes()
    }
    
    
    func loadMoreNotes(searchText: String="", category: String="All"){
        guard !isLoading else{return}
        guard hasMoreData else{return}
        
        isLoading = true
        
        let request : NSFetchRequest<Note> = Note.fetchRequest()
        var predicates : [NSPredicate] = []
        
        //global search
        if !searchText.isEmpty{
            predicates.append(NSPredicate(format: "title CONTAINS[c] %@", searchText))
        }else if category != "All"{
            predicates.append(NSPredicate(format: "category == %@", category))
        }
        
        // combine all predicates as one
        if !predicates.isEmpty{
            request.predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
        }
        
        // pagination
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.dateCreated, ascending: false)]
        request.fetchLimit = pageSize
        request.fetchOffset = currentOffset
        
        ///error handling 
        do {
            let newNotes = try container.viewContext.fetch(request)
            if newNotes.count < pageSize{
                hasMoreData = false
            }
            
            DispatchQueue.main.async {
                self.notes += newNotes
                self.currentOffset += self.pageSize
                self.isLoading = false
            }
        } catch  {
            print("error fetching notes",error)
            isLoading = false
        }
    }
    
    
    ///Search func
    func Search(searchText: String, category: String){
        notes = []
        currentOffset = 0
        hasMoreData = true
        loadMoreNotes(searchText: searchText, category: category)
    }
    
    ///ading new note
    func addNote(title: String, content: String, category: String?) {
        let newNote = Note(context: container.viewContext)
        newNote.id = UUID()
        newNote.title = title
        newNote.content = content
        newNote.dateCreated = Date()
        newNote.category = category
        saveNotes()
    }
    
    //update notes
    func updateNote(note: Note, title: String, content: String, category: String?) {
        note.title = title
        note.content = content
        note.category = category
        saveNotes()
    }
    
    ///delete notes
    func deleteNote(indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let note = notes[index]
        container.viewContext.delete(note)
        saveNotes()
    }
    
    ///saving notes
    func saveNotes() {
        do {
            try container.viewContext.save()
            loadinitialnotes()
        } catch {
            print("Error saving notes:", error)
        }
    }
    
    
}
