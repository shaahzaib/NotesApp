//
//  NoteModel.swift
//  NotesApp
//
//  Created by Macbook Pro on 10/12/2025.
//

import Foundation

struct NoteModel{
    let id: UUID = UUID()
    let title : String
    let content : String
    let dateCreated : Date
    let category : String
}

