//
//  NotesListView.swift
//  NotesApp
//
//  Created by Macbook Pro on 10/12/2025.
//


import SwiftUI

struct NotesListView: View {
    @StateObject private var vm = NoteViewModel()
    
    @State private var selectedCategory: String = "All"
    @State private var searchText : String = ""
    
    var filteredNotes: [Note] {
        if selectedCategory == "All" {
            return vm.notes
        } else {
            return vm.notes.filter { $0.category == selectedCategory }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                
                ///SearchBar
                searchBar
                
                /// Category Tabs
                categoryTabs
                
                ///Notes list
                notesList
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            vm.generateFakeNotes(count: 1_000)
                        } label: {
                            Label("Add 1,000 Notes", systemImage: "doc.on.doc")
                        }
                        Button {
                            vm.generateFakeNotes(count: 10_000)
                        } label: {
                            Label("Add 10,000 Notes", systemImage: "doc.on.doc.fill")
                        }
                        Button {
                            vm.generateFakeNotes(count: 100_000)
                        } label: {
                            Label("Add 100,000 Notes", systemImage: "tray.full")
                        }
                    } label: {
                        Text("Faker")
                    }
                }
            }
        }
    }
}


#Preview {
    NotesListView()
}


extension NotesListView{
    
    ///SEARCH BAR
    private var searchBar:some View{
        TextField("search...", text: $searchText)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .onChange(of: searchText) {
                vm.Search(searchText: searchText, category: selectedCategory)
            }
    }
    
    
    /// CATEGORY TABS
    private var categoryTabs:some View{
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(vm.categoriesWithAll, id: \.self) { category in
                    Text(category)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            selectedCategory == category
                            ? Color.blue.opacity(0.2)
                            : Color.gray.opacity(0.1)
                        )
                        .cornerRadius(12)
                        .onTapGesture {
                            selectedCategory = category
                            vm.Search(searchText: searchText, category: selectedCategory)
                        }
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }
    }
    
    ///Notes list
    private var notesList:some View{
        List{
            ForEach(filteredNotes, id: \.self) { note in
                NavigationLink {
                    AddEditNoteView(vm: vm, noteToEdit: note)
                } label: {
                    NoteRowView(note: note)
                        .onAppear {
                            if note == vm.notes.last{
                                vm.loadMoreNotes()
                            }
                        }
                }
            }
            .onDelete { indexSet in
                let note = filteredNotes[indexSet.first!]
                if let index = vm.notes.firstIndex(of: note) {
                    vm.deleteNote(indexSet: IndexSet(integer: index))
                }
            }
        }
    }
}

