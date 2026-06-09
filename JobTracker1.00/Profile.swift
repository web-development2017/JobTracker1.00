//
//  Profile.swift
//  JobTracker1.00
//
//  Created by Rich Taylor on 09/06/2026.
//
import Foundation

struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    let email: String?
}
