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

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case job
    }
}
