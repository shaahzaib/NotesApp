//
//  ContentView.swift
//  NotesApp
//
//  Created by Macbook Pro on 10/12/2025.
//

import SwiftUI

struct NotesListView: View {
    @StateObject var vm = NoteViewModel()
    @State var notetitle : String = ""
    let newNote = NoteModel(title: "1st Note", content: "this is demo note", dateCreated: Date())
    var body: some View {
        VStack {
            Text("Notes")
                .font(.title)
            TextField("add note title", text: $notetitle)
                .padding()
            
            Button {
                guard !notetitle.isEmpty else {return}
                vm.addNote(note: newNote)
            } label: {
                Text("Add Note")
            }

            List {
                ForEach(vm.notes) { note in
                    VStack{
                        Text(note.title ?? "No Title")
                            .font(.headline)
                        HStack{
                            Text(note.content ?? "no content")
                                .font(.subheadline)
                            Text(formattedDate(note.dateCreated ?? Date()))
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    NotesListView()
    
}
