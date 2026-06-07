//
//  Job.swift
//  JobTracker1.00
//
//  Created by Rich Taylor on 06/06/2026.
//
import Foundation

struct Job: Codable, Identifiable {
    let id: Int?
    let createdAt: Date?
    var job: String
    // 1. A brand new job sheet defaults to .offered, waiting for a worker to accept it
    var status: JobStatus = .unassigned

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case job
        case status
    }
    
    // 2. The true 3-step life cycle of your job sheets
    enum JobStatus: String, Codable, CaseIterable {
        case unassigned = "Unassigned"
        case offered = "Offered"
        case inProgress = "In Progress"
        case completed = "Completed"
    }
}
