//
//  JobViewModel.swift
//  JobTracker1.00
//
//  Created by Rich Taylor on 06/06/2026.
//

import Foundation
import Observation
import Supabase

@Observable
final class JobsViewModel {
    // Read-only from the outside to protect data integrity, mutable only inside this class
    private(set) var jobs: [Job] = []
    
    // UI state bound directly to the View
    var newJobText = ""
    var isSaving = false
    
    /// Fetches jobs from Supabase asynchronously on the MainActor to keep the UI smooth
    @MainActor
    func fetchJobs() async {
        do {
            let fetchedJobs: [Job] = try await SupabaseManager.client
                .from("Jobs")
                .select()
                .execute()
                .value
            
            self.jobs = fetchedJobs
        } catch {
            print("Error fetching jobs: \(error)")
        }
    }
    
    /// Inserts a new job and optimizes performance by updating locally
    @MainActor
    func saveJob() async {
        // Lean check: Don't send empty strings or spaces to the database
        let trimmedJob = newJobText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedJob.isEmpty else { return }
        
        isSaving = true
        let freshJob = Job(id: nil, createdAt: nil, job: trimmedJob)
        
        do {
            // We remove the Type expectation [Job] and just execute the network request
            try await SupabaseManager.client
                .from("Jobs")
                .insert(freshJob)
                .execute()
            
            self.newJobText = ""
            // Refresh our local array cleanly from the cloud database
            await fetchJobs()
        } catch {
            print("Error saving job: \(error)")
        }            // This 'defer' block always runs at the very end, ensuring the loader stops
            self.isSaving = false
        }
    /// Deletes a job from Supabase and updates the UI locally
    @MainActor
    func deleteJob(at offsets: IndexSet) async {
        // 1. Find the item the user swiped on
        guard let index = offsets.first else { return }
        let jobToDelete = jobs[index]
        
        // 2. Performance Optimization: Optimistically remove it from the UI immediately
        // This makes the app feel instant to the user
        jobs.remove(at: index)
        
        // 3. If the job doesn't have an ID (e.g., failed to save earlier), stop here
        guard let jobId = jobToDelete.id else { return }
        
        do {
            // 4. Tell Supabase to delete the row where the ID matches
            try await SupabaseManager.client
                .from("Jobs")
                .delete()
                .eq("id", value: jobId) // Matches the specific row ID
                .execute()
                
            print("Successfully deleted job from cloud database.")
        } catch {
            print("Error deleting job from cloud: \(error)")
            // If the network fails, we fetch the data again to restore the UI state safely
            await fetchJobs()
        }
    }
}
