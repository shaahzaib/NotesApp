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
import Fakery

final class NoteViewModel: ObservableObject {
    @Published var notes: [Note] = []
    let container: NSPersistentContainer
    
    let categories = ["Personal", "Work", "Study", "Ideas"]
    var categoriesWithAll: [String] { ["All"] + categories }
    
    // Pagination & Memory Management
    private let pageSize = 16
    private let windowSize = 100      // Increased for smoother scrolling
    private let prefetchThreshold = 10 // Load when 8 notes from edge
    
     var isLoadingOlder = false
     var isLoadingNewer = false
     var hasMoreOlder = true
     var hasMoreNewer = false
    
    // Track the "window" boundaries
    private var oldestLoadedDate: Date?
    private var newestLoadedDate: Date?
    
    // Track which notes we've already loaded (for deduplication)
    private var loadedNoteIDs = Set<UUID>()
    
    // Current search state
    private var currentSearchText = ""
    private var currentCategory = "All"
    
    // Pre-fetch buffers
    private var olderNotesBuffer: [Note] = []
    private var newerNotesBuffer: [Note] = []
    
    init() {
        container = NSPersistentContainer(name: "DBModel")
        container.loadPersistentStores { _, error in
            if let error = error { print("CoreData load error:", error) }
        }
        loadInitialNotes()
    }
    
    // MARK: - Initial Load
    func loadInitialNotes(searchText: String = "", category: String = "All") {
        currentSearchText = searchText
        currentCategory = category
        
        // Reset state
        notes = []
        loadedNoteIDs.removeAll()
        olderNotesBuffer = []
        newerNotesBuffer = []
        oldestLoadedDate = nil
        newestLoadedDate = nil
        hasMoreOlder = true
        hasMoreNewer = false
        
        // Load initial notes (newest first)
        fetchInitialNotes()
    }
    
    private func fetchInitialNotes() {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.fetchLimit = windowSize
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.dateCreated, ascending: false)]
        
        if let filterPredicate = buildPredicate() {
            request.predicate = filterPredicate
        }
        
        do {
            let result = try container.viewContext.fetch(request)
            DispatchQueue.main.async {
                self.notes = result
                // Track loaded notes
                for note in result {
                    if let id = note.id {
                        self.loadedNoteIDs.insert(id)
                    }
                }
                
                self.newestLoadedDate = result.first?.dateCreated
                self.oldestLoadedDate = result.last?.dateCreated
                
                // Pre-fetch older notes immediately
                self.prefetchOlderNotesIfNeeded()
                
                self.hasMoreOlder = result.count == self.windowSize
                
                print("Initial load: \(result.count) notes")
            }
        } catch {
            print("Initial fetch error:", error)
        }
    }
    
    // MARK: - Smart Scrolling Detection
    func checkScrollPosition(currentIndex: Int) {
        // Check if we're near the bottom and should pre-fetch older notes
        let distanceFromBottom = notes.count - currentIndex
        if distanceFromBottom <= prefetchThreshold && !isLoadingOlder && hasMoreOlder {
            print("Near bottom (\(distanceFromBottom) from end), pre-fetching...")
            loadOlderNotes(immediate: false)
        }
        
        // Check if we're near the top and should pre-fetch newer notes
        if currentIndex <= prefetchThreshold && !isLoadingNewer && hasMoreNewer {
            print("Near top (\(currentIndex) from start), pre-fetching...")
            loadNewerNotes(immediate: false)
        }
    }
    
    // MARK: - Load Older Notes (with buffer)
    func loadOlderNotes(immediate: Bool = true) {
        // If we have buffered notes, use them first
        if !olderNotesBuffer.isEmpty && immediate {
            print("Using buffered older notes (\(olderNotesBuffer.count) available)")
            applyOlderNotesFromBuffer()
            return
        }
        
        guard !isLoadingOlder, hasMoreOlder, let oldestDate = oldestLoadedDate else {
            return
        }
        
        isLoadingOlder = true
        
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.fetchLimit = pageSize
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.dateCreated, ascending: false)]
        
        // Get notes older than our current oldest
        var predicates: [NSPredicate] = [NSPredicate(format: "dateCreated < %@", oldestDate as NSDate)]
        if let filterPredicate = buildPredicate() {
            predicates.append(filterPredicate)
        }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        do {
            let result = try container.viewContext.fetch(request)
            DispatchQueue.main.async {
                print("Got \(result.count) older notes")
                
                if !result.isEmpty {
                    if immediate {
                        // Apply immediately
                        self.applyOlderNotes(result)
                    } else {
                        // Store in buffer for later
                        self.olderNotesBuffer = result
                        print("Buffered \(result.count) older notes")
                    }
                } else {
                    self.hasMoreOlder = false
                }
                
                self.isLoadingOlder = false
                
                // Pre-fetch more if buffer is empty
                if self.olderNotesBuffer.isEmpty && self.hasMoreOlder {
                    self.prefetchOlderNotesIfNeeded()
                }
            }
        } catch {
            print("Older fetch error:", error)
            isLoadingOlder = false
        }
    }
    
    private func applyOlderNotes(_ newNotes: [Note]) {
        // Filter out duplicates
        let uniqueNotes = newNotes.filter { note in
            guard let id = note.id else { return false }
            return !self.loadedNoteIDs.contains(id)
        }
        
        if uniqueNotes.isEmpty {
            self.hasMoreOlder = false
            return
        }
        
        // Add to loaded IDs
        for note in uniqueNotes {
            if let id = note.id {
                self.loadedNoteIDs.insert(id)
            }
        }
        
        // Append new notes to bottom
        self.notes.append(contentsOf: uniqueNotes)
        self.oldestLoadedDate = uniqueNotes.last?.dateCreated
        
        // If we're way over window size, remove from top
        if self.notes.count > self.windowSize * Int(1.5) {
            let toRemove = self.notes.count - self.windowSize
            let removedNotes = self.notes.prefix(toRemove)
            self.notes.removeFirst(toRemove)
            
            // Clean up IDs of removed notes (optional - for memory)
            for note in removedNotes {
                if let id = note.id {
                    self.loadedNoteIDs.remove(id)
                }
            }
            
            // Update newest date after removal
            self.newestLoadedDate = self.notes.first?.dateCreated
            print("Cleaned up \(toRemove) notes from top")
        }
        
        self.hasMoreOlder = uniqueNotes.count == self.pageSize
        self.hasMoreNewer = true
        
        print("Now have \(self.notes.count) notes in memory")
    }
    
    private func applyOlderNotesFromBuffer() {
        guard !olderNotesBuffer.isEmpty else { return }
        applyOlderNotes(olderNotesBuffer)
        olderNotesBuffer = []
    }
    
    // MARK: - Load Newer Notes (with buffer)
    func loadNewerNotes(immediate: Bool = true) {
        // If we have buffered notes, use them first
        if !newerNotesBuffer.isEmpty && immediate {
            print("Using buffered newer notes (\(newerNotesBuffer.count) available)")
            applyNewerNotesFromBuffer()
            return
        }
        
        guard !isLoadingNewer, hasMoreNewer, let newestDate = newestLoadedDate else {
            return
        }
        
        isLoadingNewer = true
        
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.fetchLimit = pageSize
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.dateCreated, ascending: true)]
        
        // Get notes newer than our current newest
        var predicates: [NSPredicate] = [NSPredicate(format: "dateCreated > %@", newestDate as NSDate)]
        if let filterPredicate = buildPredicate() {
            predicates.append(filterPredicate)
        }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        do {
            let result = try container.viewContext.fetch(request)
            DispatchQueue.main.async {
                print("Got \(result.count) newer notes")
                
                if !result.isEmpty {
                    if immediate {
                        // Apply immediately
                        self.applyNewerNotes(result)
                    } else {
                        // Store in buffer for later
                        self.newerNotesBuffer = result
                        print("Buffered \(result.count) newer notes")
                    }
                } else {
                    self.hasMoreNewer = false
                }
                
                self.isLoadingNewer = false
                
                // Pre-fetch more if buffer is empty
                if self.newerNotesBuffer.isEmpty && self.hasMoreNewer {
                    self.prefetchNewerNotesIfNeeded()
                }
            }
        } catch {
            print("Newer fetch error:", error)
            isLoadingNewer = false
        }
    }
    
    private func applyNewerNotes(_ newNotes: [Note]) {
        // We fetched in ascending order, need descending for display
        let reversedNotes = Array(newNotes.reversed())
        
        // Filter out duplicates
        let uniqueNotes = reversedNotes.filter { note in
            guard let id = note.id else { return false }
            return !self.loadedNoteIDs.contains(id)
        }
        
        if uniqueNotes.isEmpty {
            self.hasMoreNewer = false
            return
        }
        
        // Add to loaded IDs
        for note in uniqueNotes {
            if let id = note.id {
                self.loadedNoteIDs.insert(id)
            }
        }
        
        // Insert new notes at top
        self.notes.insert(contentsOf: uniqueNotes, at: 0)
        self.newestLoadedDate = uniqueNotes.first?.dateCreated
        
        // If we're way over window size, remove from bottom
        if self.notes.count > self.windowSize * Int(1.5) {
            let toRemove = self.notes.count - self.windowSize
            let removedNotes = self.notes.suffix(toRemove)
            self.notes.removeLast(toRemove)
            
            // Clean up IDs of removed notes
            for note in removedNotes {
                if let id = note.id {
                    self.loadedNoteIDs.remove(id)
                }
            }
            
            // Update oldest date after removal
            self.oldestLoadedDate = self.notes.last?.dateCreated
            print("Cleaned up \(toRemove) notes from bottom")
        }
        
        self.hasMoreNewer = newNotes.count == self.pageSize
        
        print("Now have \(self.notes.count) notes in memory")
    }
    
    private func applyNewerNotesFromBuffer() {
        guard !newerNotesBuffer.isEmpty else { return }
        applyNewerNotes(newerNotesBuffer)
        newerNotesBuffer = []
    }
    
    // MARK: - Pre-fetching
    private func prefetchOlderNotesIfNeeded() {
        // Only pre-fetch if buffer is empty and we have room
        if olderNotesBuffer.isEmpty && !isLoadingOlder && hasMoreOlder && notes.count < windowSize * 2 {
            print("Pre-fetching older notes...")
            loadOlderNotes(immediate: false)
        }
    }
    
    private func prefetchNewerNotesIfNeeded() {
        // Only pre-fetch if buffer is empty and we have room
        if newerNotesBuffer.isEmpty && !isLoadingNewer && hasMoreNewer && notes.count < windowSize * 2 {
            print("Pre-fetching newer notes...")
            loadNewerNotes(immediate: false)
        }
    }
    
    private func buildPredicate() -> NSPredicate? {
          var predicates: [NSPredicate] = []
          if !currentSearchText.isEmpty {
              predicates.append(NSPredicate(format: "title CONTAINS[c] %@", currentSearchText))
          }
          if currentCategory != "All" {
              predicates.append(NSPredicate(format: "category == %@", currentCategory))
          }
          return predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
      }
      
      // MARK: - Public Methods
      func searchNotes(searchText: String, category: String) {
          loadInitialNotes(searchText: searchText, category: category)
      }
      
      func refreshNotes() {
          // For refresh, just reload the initial notes
          loadInitialNotes(searchText: currentSearchText, category: currentCategory)
      }
      
      // MARK: - CRUD Operations
      func addNote(title: String, content: String, category: String?) {
          let note = Note(context: container.viewContext)
          note.id = UUID()
          note.title = title
          note.content = content
          note.category = category
          note.dateCreated = Date()
          saveNotes()
      }
      
      func updateNote(note: Note, title: String, content: String, category: String?) {
          note.title = title
          note.content = content
          note.category = category
          saveNotes()
      }
      
      func deleteNote(at indexSet: IndexSet) {
          guard let index = indexSet.first else { return }
          let noteToDelete = notes[index]
          container.viewContext.delete(noteToDelete)
          saveNotes()
      }
      
      private func saveNotes() {
          do {
              try container.viewContext.save()
              // After saving, refresh to show changes
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                  self.refreshNotes()
              }
          } catch {
              print("Save error:", error)
          }
      }
}
