import SwiftUI

struct AddEditNoteView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: NoteViewModel
    var noteToEdit: Note?
    
    @State private var title: String
    @State private var content: String
    @State private var selectedCategory: String?
    
    init(vm: NoteViewModel, noteToEdit: Note?) {
        self.vm = vm
        self.noteToEdit = noteToEdit
        _title = State(initialValue: noteToEdit?.title ?? "")
        _content = State(initialValue: noteToEdit?.content ?? "")
        _selectedCategory = State(initialValue: noteToEdit?.category)
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
                
                Section("Category") {
                    Picker("Select Category", selection: $selectedCategory) {
                        Text("None").tag(String?.none)
                        ForEach(vm.categories, id: \.self) { category in
                            Text(category).tag(String?.some(category))
                        }
                    }
                }
                
                if let date = noteToEdit?.dateCreated {
                    Section {
                        Text("Created: \(formattedDate(date))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                if noteToEdit != nil {
                    Section {
                        Button(role: .destructive) {
                            deleteNote()
                        } label: {
                            Text("Delete Note")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
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
        }.navigationBarBackButtonHidden()
    }
    
    private func saveNote() {
        if let note = noteToEdit {
            vm.updateNote(note: note, title: title, content: content, category: selectedCategory)
        } else {
            vm.addNote(title: title, content: content, category: selectedCategory)
        }
    }
    
    private func deleteNote() {
        if let note = noteToEdit, let index = vm.notes.firstIndex(of: note) {
            let indexSet = IndexSet(integer: index)
            vm.deleteNote(indexSet: indexSet)
            dismiss()
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
