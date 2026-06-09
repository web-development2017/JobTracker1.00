//
//  Job.swift
//  JobTracker1.00
//
//  Created by Rich Taylor on 06/06/2026.
//
import Foundation

struct Job: Codable, Identifiable, Equatable {
    let id: Int?
    let createdAt: Date?
    var job: String
    // 1. A brand new job sheet defaults to .offered, waiting for a worker to accept it
    var status: JobStatus = .unassigned
    var created_by: UUID? // 👈 Add this new field here
    var assigned_to: UUID? // 👈 1. Add this field for targeted assignments

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case job
        case status
        case created_by = "created_by" // Maps Swift camelCase to Postgres snake_case
        case assigned_to = "assigned_to" // 👈 2. Map Swift property to Postgres snake_case
            
    }
    
    // 2. The true 3-step life cycle of your job sheets
    enum JobStatus: String, Codable, CaseIterable {
        case unassigned = "Unassigned"
        case offered = "Offered"
        case inProgress = "In Progress"
        case completed = "Completed"
    }
}
