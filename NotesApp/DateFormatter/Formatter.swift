//
//  dateformatter.swift
//  NotesApp
//
//  Created by Macbook Pro on 10/12/2025.
//
import Foundation

func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
