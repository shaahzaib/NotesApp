//
//  NotesListView.swift
//  NotesApp
//
//  Created by Macbook Pro on 10/12/2025.
//


import SwiftUI

struct NotesListView: View {
    @StateObject private var vm = NoteViewModel()
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    
    var body: some View {
        NavigationView {
            VStack {
                searchBar
                categoryTabs
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
            }
        }
    }
    
    private var searchBar: some View {
        TextField("Search...", text: $searchText)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .onChange(of: searchText) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    vm.searchNotes(searchText: searchText, category: selectedCategory)
                }
            }
    }
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(vm.categoriesWithAll, id: \.self) { category in
                    Text(category)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(selectedCategory == category ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .onTapGesture {
                            selectedCategory = category
                            vm.searchNotes(searchText: searchText, category: selectedCategory)
                        }
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }
    }
    
    private var notesList: some View {
           List {
               ForEach(Array(vm.notes.enumerated()), id: \.element) { index, note in
                   NavigationLink {
                       AddEditNoteView(vm: vm, noteToEdit: note)
                   } label: {
                       NoteRowView(note: note)
                   }
                   .onAppear {
                       // Load older when we're near the bottom
                       if index == vm.notes.count - 3 && !vm.isLoadingOlder && vm.hasMoreOlder {
                           print("Near bottom (3 from end) - loading older")
                           vm.loadOlderNotes()
                       }
                       
                       // Load newer when we're near the top
                       if index == 2 && !vm.isLoadingNewer && vm.hasMoreNewer {
                           print("Near top (3 from start) - loading newer")
                           vm.loadNewerNotes()
                       }
                   }
               }
               
               // Loading indicators
               if vm.isLoadingOlder {
                   HStack {
                       Spacer()
                       ProgressView()
                           .padding()
                       Spacer()
                   }
               }
               
               if !vm.hasMoreOlder && !vm.notes.isEmpty {
                   Text("No more notes")
                       .foregroundColor(.gray)
                       .font(.caption)
                       .frame(maxWidth: .infinity, alignment: .center)
                       .padding()
               }
           }
           .listStyle(PlainListStyle())
           .refreshable {
               // Pull to refresh
               await withCheckedContinuation { continuation in
                   vm.refreshNotes()
                   DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                       continuation.resume()
                   }
               }
           }
       }
   }
#Preview {
    NotesListView()
}
